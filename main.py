import os
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from sentence_transformers import SentenceTransformer
from pymongo import MongoClient
from flask import Flask, request, jsonify
from flask_talisman import Talisman
from bson import ObjectId
from datetime import datetime
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

app = Flask(__name__)
#Talisman(app)

# DÃ©sactiver les opÃ©rations personnalisÃ©es oneDNN et avertissement de symlink Hugging Face
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['HF_HUB_DISABLE_SYMLINKS_WARNING'] = '1'
os.environ['USE_FLASH_ATTENTION'] = '1'

# Connexion Ã  MongoDB
client = MongoClient('mongodb://localhost:27017/')
db = client['Projet_ChatBot']
suggestions_collection = db['Suggestions']

# Configuration de quantification en 4 bits pour BitsAndBytes
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True, #pour utiliser moins de mÃ©moire, calculer plus vite, on rÃ©duis la taille du poids
    bnb_4bit_quant_type="nf4", #quantification non fusionnÃ©e pour minimiser la perte de prÃ©cision
    bnb_4bit_use_double_quant=True, #double quantification, pour ajouter une Ã©tape de quantification et augmenter la prÃ©cision des rÃ©sultats
    bnb_4bit_compute_dtype=torch.bfloat16, #type de donnÃ©e pour les calculs
)

# Chemin vers le modÃ¨le
model_path = "google/gemma-1.1-7b-it" 

# Charger le modÃ¨le et le tokenizer
print("Chargement du tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(model_path) #chargement du tokenizer
print("Tokenizer chargÃ©.")

print("Chargement du modÃ¨le...")
model = AutoModelForCausalLM.from_pretrained(
    model_path, #chargement du modÃ¨le
    quantization_config=bnb_config, #configuration de quantification
    torch_dtype=torch.bfloat16, #type de donnÃ©e pour les calculs (bfloat16 pour rÃ©duire la taille du modÃ¨le et accÃ©lÃ©rer les calculs)
    device_map="auto" #priorise le GPU au CPU
)
print("ModÃ¨le chargÃ©.")

# Fonction pour extraire les documents et prÃ©parer les textes
def get_documents_from_db():
    collections = db.list_collection_names() #liste des collections dans la base de donnÃ©es
    documents = []
    for collection_name in collections: 
        collection = db[collection_name] 
        docs = list(collection.find({})) #extraire les documents de la collection 
        for doc in docs:
            doc_text = f"Collection: {collection_name}, " + " ".join([f"{key}: {value}" for key, value in doc.items() if key != '_id'])
            documents.append((collection_name, doc['_id'], doc_text)) 
    return documents

# Extraire les documents de la base de donnÃ©es
documents = get_documents_from_db()

# Fonction pour vectoriser les documents et la question
def vectorize_documents_and_question(question, documents):
    contexts = [doc[2] for doc in documents] #extraire le contenu de la BD
    vectorizer = TfidfVectorizer().fit(contexts + [question]) #crÃ©ation d'un vecteur TF-IDF pour les documents et la question
    context_vectors = vectorizer.transform(contexts).toarray() #vectorisation des contextes
    question_vector = vectorizer.transform([question]).toarray()[0] #vectorisation de la question 
    return context_vectors, question_vector 

# Fonction pour trouver les contextes pertinents
def find_relevant_contexts(question, documents):
    print(f"Recherche des contextes pertinents pour la question: {question}")

    context_vectors, question_vector = vectorize_documents_and_question(question, documents) #vectorisation des documents et de la question

    # Calculer les similaritÃ©s cosinus
    similarities = cosine_similarity([question_vector], context_vectors).flatten() 

    # Filtrer les similaritÃ©s infÃ©rieures Ã  0.2
    filtered_indices = [i for i, similarity in enumerate(similarities) if similarity >= 0.2]

    if not filtered_indices:
        print("Aucun contexte pertinent trouvÃ©.")
        return

    #print("FILTERED INDICES : ", filtered_indices)

    # Obtenir les indices des contextes les plus similaires, triÃ©s par ordre dÃ©croissant
    top_k_indices = np.argsort(similarities[filtered_indices])[-5:][::-1]

    #print("top_k_indices : ", top_k_indices)

    top_k_contexts = []
    for idx in top_k_indices:
        collection_name, doc_id, context_text = documents[filtered_indices[idx]] #extraire le nom de la collection, l'ID du document et le texte du contexte
        similarity_score =  similarities[filtered_indices[idx]] #extraire le score de similaritÃ© 
        top_k_contexts.append({
            "collection": collection_name,
            "document_id": doc_id,
            "context": context_text,
            "similarity": similarity_score
        })

    print(f"Contextes pertinents trouvÃ©s: {top_k_contexts}")
    return top_k_contexts

# Fonction pour obtenir une rÃ©ponse en utilisant le modÃ¨le
def get_answer_combined(question, documents,history):
    top_k_contexts = find_relevant_contexts(question, documents) #rechercher les contextes pertinents
    if top_k_contexts:
# Combinaison des contextes pour les afficher dans le prompt de l'IA 
        combined_context = "\n\n".join([f"Contexte {i+1}:\n{ctx['context']} (SimilaritÃ©: {ctx['similarity']:.2f})" for i, ctx in enumerate(top_k_contexts)])
        print(combined_context)

        prompt = (
            "<end_of_turn>\n"
            f"<start_of_turn>user\n"
            f"Tu es un chatbot Ã©ducatif, utile et respectueux, conÃ§u pour l'universitÃ© Evry Paris-Saclay. "
            f"Ton rÃ´le est de rÃ©pondre aux questions des utilisateurs concernant diffÃ©rents Ã©lÃ©ments et informations sur l'universitÃ©. "
            f"Tu dois fournir des rÃ©ponses prÃ©cises et dÃ©taillÃ©es en utilisant le contexte provenant de la base de donnÃ©es de l'universitÃ©. "
            f"Tu es capable d'utiliser des contextes spÃ©cifiques et l'historique de la conversation pour gÃ©nÃ©rer des rÃ©ponses. "
            f"Si une question est incohÃ©rente ou ne fait pas de sens, explique pourquoi et Ã©vite de donner des informations incorrectes. "
            f"Si tu ne connais pas la rÃ©ponse Ã  une question, il est important de ne pas donner de fausses informations ; dis simplement que tu ne sais pas. "
            f"Si le contexte fourni n'est pas pertinent ou n'existe pas, tu peux te baser sur tes connaissances gÃ©nÃ©rales Ã  propos de l'universitÃ© et rÃ©pondre Ã  la question. "
            f"Tu dois toujours rÃ©pondre en franÃ§ais et Ãªtre capable de gÃ©rer des conversations complexes tout en suivant le contexte.\n\n"
            f"Utilise les contextes suivants pour rÃ©pondre Ã  la question seulement si les notes de similaritÃ© sont Ã©levÃ©es. Sinon, base ta rÃ©ponse sur tes connaissances gÃ©nÃ©rales.\n\n"
            f"Voici l'historique des conversations : {history}\n\n, s'il est donnÃ© utilise le sinon ignore le"
            f"Question : {question}\n\n"
            f"{combined_context}\n\n"
            f"RÃ©ponds simplement Ã  la question en te basant sur les contextes ci-dessus. Ta rÃ©ponse doit Ãªtre prÃ©cise et dÃ©taillÃ©e. "
            f"Ne fournis pas de commentaires ou d'instructions inutiles. N'ajoute pas de **Instructions** Ã  la fin du message.<end_of_turn>\n\n<start_of_turn>model\nRÃ©ponse :"
        )
    else :
        prompt = (
            f"<end_of_turn>\n"
            f"<start_of_turn>user\n"
            f"Tu es un chatbot Ã©ducatif, utile et respectueux, conÃ§u pour l'universitÃ© Evry Paris-Saclay. "
            f"Ton rÃ´le est de rÃ©pondre aux questions des utilisateurs concernant diffÃ©rents Ã©lÃ©ments et informations sur l'universitÃ©. "
            f"Tu dois fournir des rÃ©ponses prÃ©cises et dÃ©taillÃ©es en utilisant le contexte provenant de la base de donnÃ©es de l'universitÃ©. "
            f"Tu es capable d'utiliser des contextes spÃ©cifiques et l'historique de la conversation pour gÃ©nÃ©rer des rÃ©ponses. "
            f"Si une question est incohÃ©rente ou ne fait pas de sens, explique pourquoi et Ã©vite de donner des informations incorrectes. "
            f"Si tu ne connais pas la rÃ©ponse Ã  une question, il est important de ne pas donner de fausses informations ; dis simplement que tu ne sais pas. "
            f"Si le contexte fourni n'est pas pertinent ou n'existe pas, tu peux te baser sur tes connaissances gÃ©nÃ©rales Ã  propos de l'universitÃ© et rÃ©pondre Ã  la question. "
            f"Tu dois toujours rÃ©pondre en franÃ§ais et Ãªtre capable de gÃ©rer des conversations complexes tout en suivant le contexte.\n\n"
            f"Utilise les contextes suivants pour rÃ©pondre Ã  la question seulement si les notes de similaritÃ© sont Ã©levÃ©es. Sinon, base ta rÃ©ponse sur tes connaissances gÃ©nÃ©rales.\n\n"
            f"Voici l'historique des conversations : {history}\n\n, s'il est donnÃ© utilise le sinon ignore le"
            f"Question : {question}\n\n"
            f"Ta rÃ©ponse doit Ãªtre prÃ©cise et dÃ©taillÃ©e. "
            f"Ne fournis pas de commentaires ou d'instructions inutiles. N'ajoute pas de **Instructions** Ã  la fin du message.<end_of_turn>\n\n<start_of_turn>model\nRÃ©ponse :"
        )

    inputs = tokenizer(prompt, return_tensors="pt").to("cuda" if torch.cuda.is_available() else "cpu")

    print("GÃ©nÃ©ration de la rÃ©ponse...")
    try:
        gen_tokens = model.generate(
            inputs.input_ids, # texte d'entrÃ©es tokenisÃ©
            max_new_tokens=150, #limite la taille de rÃ©ponse
            do_sample=True, #echantillonage stochastique plutot que mÃ©thode dÃ©terministe, diversitÃ© des solutions
            temperature=0.7, #plus c'est haut, plus l'IA est crÃ©ative
            top_p=0.9, #resteindre les choix de rÃ©ponses aux plus probables
        )
        gen_text = tokenizer.decode(gen_tokens[0], skip_special_tokens=True) #dÃ©codage des tokens en texte lisible 
        print(f"gen_text : {gen_text}")
        response = gen_text.split('RÃ©ponse :', 1)[-1].strip()
        print(f"RÃ©ponse gÃ©nÃ©rÃ©e : {response}")
        return response
    except Exception as e:
        print(f"Erreur pendant la gÃ©nÃ©ration de la rÃ©ponse: {e}")
        return "Une erreur est survenue pendant la gÃ©nÃ©ration de la rÃ©ponse."
    

@app.route('/')
def home():
    return '<h1>Bienvenue sur le ChatBot de l\'universitÃ© Evry Paris-Saclay !</h1>'

@app.route('/ask', methods=['GET'])
def get_answer():
    question = request.args.get('prompt')
    history = request.args.get('history') 

    if not question:
        return jsonify({'error': 'No question provided'}), 400

    answer = get_answer_combined(question, documents,history)
    print("answer : ", answer)
    return jsonify({'answer': answer})

# Routes pour interagir avec la base de donnÃ©es MongoDB
@app.route('/collection/<collection_name>', methods=['GET'])
def get_all_from_collection(collection_name):
    try:
        collection = db[collection_name]
        data = list(collection.find())
        for item in data:
            item['_id'] = str(item['_id'])
        return jsonify(data)
    except Exception as e:
        return str(e), 500

@app.route('/collection/<collection_name>/<id>', methods=['GET'])
def get_from_collection_by_id(collection_name, id):
    try:
        collection = db[collection_name]
        data = collection.find_one({'_id': ObjectId(id)})
        if data:
            data['_id'] = str(data['_id'])
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
            item['_id'] = str(item['_id'])
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
    # Utiliser SSL pour HTTPS
    ssl_context = ('localhost.pem', 'localhost-key.pem') #clÃ© privÃ©e et certificat SSL
    app.run(host='0.0.0.0', port=5000, ssl_context=ssl_context) #lancer l'application sur le port 5000, host 0.0.0.0 correspond Ã  localhost