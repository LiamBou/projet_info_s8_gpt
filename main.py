import os
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from sentence_transformers import SentenceTransformer
from pymongo import MongoClient
from flask import Flask, request, jsonify
from bson import ObjectId
from datetime import datetime
import faiss
import numpy as np

app = Flask(__name__)

# Désactiver les opérations personnalisées oneDNN et avertissement de symlink Hugging Face
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['HF_HUB_DISABLE_SYMLINKS_WARNING'] = '1'
os.environ['USE_FLASH_ATTENTION'] = '1'

# Connexion à MongoDB
client = MongoClient('mongodb://localhost:27017/')
db = client['Projet_ChatBot']
suggestions_collection = db['Suggestions']

# Configuration de quantification en 4 bits pour BitsAndBytes
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_use_double_quant=True,
    bnb_4bit_compute_dtype=torch.bfloat16,
)

# Chemin vers le modèle fine-tuné
fine_tuned_model_path = "google/gemma-1.1-7b-it"

# Charger le modèle et le tokenizer
print("Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(fine_tuned_model_path)
print("Tokenizer chargé.")

print("Chargement du modèle...")
model = AutoModelForCausalLM.from_pretrained(
    fine_tuned_model_path,
    quantization_config=bnb_config,
    torch_dtype=torch.bfloat16,
    device_map="auto"
)
print("Modèle chargé.")

# Sentence Transformer pour trouver le contexte pertinent
print("Chargement du modèle Sentence Transformer...")
sentence_model = SentenceTransformer('all-MiniLM-L6-v2')
sentence_model.to("cuda" if torch.cuda.is_available() else "cpu")
print("Modèle Sentence Transformer chargé.")

# Charger l'index FAISS et les ID des documents
def load_faiss_index_and_ids():
    print("Chargement de l'index FAISS...")
    index = faiss.read_index("vectors.index")
    print("Index FAISS chargé.")
    
    print("Chargement des correspondances d'ID...")
    id_map = []
    with open("id_map.txt", "r") as f:
        for line in f:
            collection_name, doc_id = line.strip().split("\t")
            id_map.append((collection_name, doc_id))
    print("Correspondances d'ID chargées.")
    
    return index, id_map

faiss_index, id_map = load_faiss_index_and_ids()

# Fonction pour trouver les contextes pertinents
def find_relevant_contexts(question, index, id_map, sentence_model):
    print(f"Recherche des contextes pertinents pour la question: {question}")
    
    # Encoder la question pour obtenir son vecteur d'embedding
    question_embedding = sentence_model.encode(question, convert_to_tensor=True).cpu().numpy()
    
    # Rechercher les contextes les plus pertinents dans l'index FAISS
    D, I = index.search(np.array([question_embedding]), k=5)  # k=5 pour les 5 contextes les plus pertinents
    
    top_k_contexts = []
    for i in range(len(I[0])):
        collection_name, doc_id = id_map[I[0][i]]
        document = db[collection_name].find_one({"_id": ObjectId(doc_id)})
        if document:
            # Construire le contexte à partir du document
            context = f"Collection: {collection_name}, " + ", ".join([f"{key}: {value}" for key, value in document.items() if key != "_id"])
            top_k_contexts.append(context)
        else:
            print(f"Avertissement : Document {doc_id} dans la collection {collection_name} introuvable.")
    
    if top_k_contexts:
        print(f"Contextes pertinents trouvés: {top_k_contexts}")
    else:
        print("Aucun contexte pertinent trouvé.")
    
    return top_k_contexts



# Fonction pour obtenir une réponse en utilisant le modèle
def get_answer_combined(question, index, id_map):
    top_k_contexts = find_relevant_contexts(question, index, id_map, sentence_model)
    if top_k_contexts:
        combined_context = "\n\n".join([f"Contexte {i+1}: {ctx}" for i, ctx in enumerate(top_k_contexts)])
        '''prompt = (
            f"Tu es un chatbot éducatif conçu pour l'université Evry Paris-Saclay."
            f" Ton rôle est de répondre aux questions des utilisateurs concernant les différents services de l'université,"
            f" les événements, les calendriers académiques, et autres informations pertinentes."
            f" Tu dois fournir des réponses précises et détaillées, collecter des commentaires et des suggestions pour améliorer les services de l'école,"
            f" et t'améliorer au fil du temps grâce aux interactions avec les utilisateurs."
            f" Tu dois toujours répondre en français et être capable de gérer des conversations complexes en suivant le contexte. Analyse toujours le contexte pour savoir si des éléments répondent à la question et utilise les dans ta réponse si ils sont pertinents."
            #f" A chaque question, tu auras 5 éléments de contexte à traiter, "
            f"\n\n{combined_context}\n\nQuestion : {question}\nRéponse :"
        )'''
        prompt = (        
            f"Tu es un chatbot éducatif, utile et respectueux conçu pour l'université Evry Paris-Saclay. "
            f"Ton rôle est de répondre aux questions des utilisateurs concernant des différents informations sur des éléments de l'université, "
            f"Tu dois fournir des réponses précises et détaillées en utilisant le contexte - provenant de la base de données de l'université - fourni dans le texte, "
            f"Tu peux recevoir du contexte de la base de données de l'université et de l'historique de la conversation pour générer une réponse. "
            f"Si aucun contexte n'est fourni, le champ 'Contexte : ' sera vide. Dans ce cas, tu peux générer une réponse basée sur tes connaissances générales sur l'université. "
            f"Si une question n'a pas de sens ou n'est pas factuellement cohérente, explique pourquoi au lieu de fournir une réponse incorrecte. "
            f"Si tu ne connais pas la réponse à une question, ne partage pas de fausses informations. Dis simplement que tu ne sais pas. "
            f"Tu dois toujours répondre en français et être capable de gérer des conversations complexes en suivant le contexte.\n\n"
            f"Tu dois toujours sélectionner toi même les éléments pertinents du contexte auxquels tu dois répondre.\n\n"
            f"Voici quelques exemples du format des contextes qui te seront fournis DEBUT EXEMPLE:\n\n"
            f"['Collection: nombre-detudiants, Annee_de_linscription: 2018, Nationalité - continent: Afrique, classe_dage: 25 - 29 ans, CSP parents: sans objet ou non renseigné, Sexe: F, Nationalite_francaise_ON: N, Nationalite_-_Pays: CAMEROUNAIS(E), Neo-bachelier_ON: N, Groupe de bac: Bac étranger, Bac_serie: Bac étranger, Bac_Mention: Bien, Lieu du bac: Etranger, Composante: UFR SHS, Néo-entrants (O/N): O, Cursus_LMD: cursus M, Niveau: bac+5, Type de diplôme: Master, Etape: M2, Diplôme_Saclay: Diplôme Saclay, Regime: initiale, Etudiant_Oui-si: Oui, Redoublement: Non-redoublant, nombre_etudiants: 1', 'Collection: nombre-detudiants, Annee_de_linscription: 2018, Nationalité - continent: Europe, classe_dage: moins de 18 ans, CSP parents: sans objet ou non renseigné, Sexe: F, Nationalite_francaise_ON: O, Nationalite_-_Pays: FRANCAIS(E), Neo-bachelier_ON: O, Groupe de bac: Bac techno, Bac_serie: STMG, Bac_Mention: Bien, Lieu du bac: Essonne, Composante: IUT, Néo-entrants (O/N): O, Cursus_LMD: cursus L, Niveau: bac+1, Type de diplôme: DUT, Etape: DUT1, Diplôme_Saclay: Diplôme UEVE, Regime: apprentis, Etudiant_Oui-si: Oui, Redoublement: Non-redoublant, nombre_etudiants: 1']"
            f"FIN EXEMPLE\n\n"
            f"Question: {question}\n\n"
            f"{combined_context}\n\n"
            f"Réponds à la question en te basant sur les contextes ci-dessus. Ta réponse doit être précise et détaillée :\nRéponse :"
        )

        inputs = tokenizer(prompt, return_tensors="pt").to("cuda" if torch.cuda.is_available() else "cpu")

        print("Génération de la réponse...")
        try:
            gen_tokens = model.generate(
                inputs.input_ids,
                max_new_tokens=150,
                do_sample=True,
                temperature=0.7,
                top_p=0.9,
            )
            gen_text = tokenizer.decode(gen_tokens[0], skip_special_tokens=True)
            # Extraire uniquement la partie de la réponse générée par le modèle
            response = gen_text.split('Réponse :', 1)[-1].strip()
            print(f"Réponse générée: {response}")
            return response
        except Exception as e:
            print(f"Erreur pendant la génération de la réponse: {e}")
            return "Une erreur est survenue pendant la génération de la réponse."
    else:
        return "Aucun contexte pertinent trouvé."

@app.route('/')
def home():
    return 'Hello World!'

@app.route('/ask', methods=['GET'])
def get_answer():
    question = request.args.get('prompt')
    
    if not question:
        return jsonify({'error': 'No question provided'}), 400

    answer = get_answer_combined(question, faiss_index, id_map)
    print("answer : ", answer)
    return jsonify(answer)

# Routes pour interagir avec la base de données MongoDB
@app.route('/collection/<collection_name>', methods=['GET'])
def get_all_from_collection(collection_name):
    try:
        collection = db[collection_name]
        data = list(collection.find())
        for item in data:
            item['_id'] = str(item['_id'])  # Convertir ObjectId en chaîne de caractères
        return jsonify(data)
    except Exception as e:
        return str(e), 500

@app.route('/collection/<collection_name>/<id>', methods=['GET'])
def get_from_collection_by_id(collection_name, id):
    try:
        collection = db[collection_name]
        data = collection.find_one({'_id': ObjectId(id)})
        if data:
            data['_id'] = str(data['_id'])  # Convertir ObjectId en chaîne de caractères
            return jsonify(data)
        else:
            return jsonify({'error': 'Document not found'}), 404
    except Exception as e:
        return str(e), 500

@app.route('/collection/<collection_name>/query', methods=['GET'])
def query_collection(collection_name):
    try:
        field = request.args.get('field')
        value = request.args.get('value')
        if not field or not value:
            return jsonify({'error': 'Field and value query parameters are required'}), 400
        
        query = {field: value}
        collection = db[collection_name]
        data = list(collection.find(query))
        for item in data:
            item['_id'] = str(item['_id'])  # Convertir ObjectId en chaîne de caractères
        return jsonify(data)
    except Exception as e:
        return str(e), 500
    
# Route pour ajouter des suggestions
@app.route('/suggestions', methods=['POST'])
def add_suggestion():
    username = request.args.get('Username')
    suggestion_text = request.args.get('Suggestion')

    if not username or not suggestion_text:
        return jsonify({'error': 'Username and Suggestion are required'}), 400

    suggestion = {
        "Username": username,
        "Date": datetime.now(),
        "Suggestion": suggestion_text
    }

    try:
        suggestions_collection.insert_one(suggestion)
        return jsonify({'message': 'Suggestion added successfully'}), 201
    except Exception as e:
        return str(e), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)