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

# Fonction pour extraire les documents et préparer les textes
def get_documents_from_db():
    collections = db.list_collection_names()
    documents = []
    for collection_name in collections:
        collection = db[collection_name]
        docs = list(collection.find({}))
        for doc in docs:
            doc_text = f"Collection: {collection_name}, " + " ".join([f"{key}: {value}" for key, value in doc.items() if key != '_id'])
            documents.append((collection_name, doc['_id'], doc_text))
    return documents

# Extraire les documents de la base de données
documents = get_documents_from_db()

# Fonction pour vectoriser les documents et la question
def vectorize_documents_and_question(question, documents):
    contexts = [doc[2] for doc in documents]
    vectorizer = TfidfVectorizer().fit(contexts + [question])
    context_vectors = vectorizer.transform(contexts).toarray()
    question_vector = vectorizer.transform([question]).toarray()[0]
    return context_vectors, question_vector

# Fonction pour trouver les contextes pertinents
def find_relevant_contexts(question, documents):
    print(f"Recherche des contextes pertinents pour la question: {question}")

    context_vectors, question_vector = vectorize_documents_and_question(question, documents)

    # Calculer les similarités cosinus
    similarities = cosine_similarity([question_vector], context_vectors).flatten()

    # Filtrer les similarités inférieures à 0.2
    filtered_indices = [i for i, similarity in enumerate(similarities) if similarity >= 0.2]

    if not filtered_indices:
        print("Aucun contexte pertinent trouvé.")
        return

    # Obtenir les indices des contextes les plus similaires, triés par ordre décroissant
    top_k_indices = np.argsort(similarities[filtered_indices])[-5:][::-1]

    top_k_contexts = []
    for idx in top_k_indices:
        collection_name, doc_id, context_text = documents[filtered_indices[idx]]
        top_k_contexts.append({
            "collection": collection_name,
            "document_id": doc_id,
            "context": context_text
        })

    print(f"Contextes pertinents trouvés: {top_k_contexts}")
    return top_k_contexts

# Fonction pour obtenir une réponse en utilisant le modèle
def get_answer_combined(question, documents):
    top_k_contexts = find_relevant_contexts(question, documents)
    if top_k_contexts:
        combined_context = "\n\n".join([f"Contexte {i+1}:\n{ctx['context']}" for i, ctx in enumerate(top_k_contexts)])
        print(combined_context)

        prompt = (
            "<end_of_turn>\n"
            f"<start_of_turn>user\n"
            f"Tu es un chatbot éducatif, utile et respectueux, conçu pour l'université Evry Paris-Saclay. "
            f"Ton rôle est de répondre aux questions des utilisateurs concernant différents éléments et informations sur l'université. "
            f"Tu dois fournir des réponses précises et détaillées en utilisant le contexte provenant de la base de données de l'université. "
            f"Tu es capable d'utiliser des contextes spécifiques et l'historique de la conversation pour générer des réponses. "
            f"Si une question est incohérente ou ne fait pas de sens, explique pourquoi et évite de donner des informations incorrectes. "
            f"Si tu ne connais pas la réponse à une question, il est important de ne pas donner de fausses informations ; dis simplement que tu ne sais pas. "
            f"Si le contexte fourni n'est pas pertinent ou n'existe pas, tu peux te baser sur tes connaissances générales à propos de l'université et répondre à la question. "
            f"Tu dois toujours répondre en français et être capable de gérer des conversations complexes tout en suivant le contexte.\n\n"
            f"Utilise les contextes suivants pour répondre à la question seulement si les notes de similarité sont élevées. Sinon, base ta réponse sur tes connaissances générales.\n\n"
            f"Question : {question}\n\n"
            f"{combined_context}\n\n"
            f"Réponds simplement à la question en te basant sur les contextes ci-dessus. Ta réponse doit être précise et détaillée. "
            f"Ne fournis pas de commentaires ou d'instructions inutiles. N'ajoute pas de **Instructions** à la fin du message.<end_of_turn>\n\n<start_of_turn>model\nRéponse :"
        )
    else :
        prompt = (
            f"<end_of_turn>\n"
            f"<start_of_turn>user\n"
            f"Tu es un chatbot éducatif, utile et respectueux, conçu pour l'université Evry Paris-Saclay. "
            f"Ton rôle est de répondre aux questions des utilisateurs concernant différents éléments et informations sur l'université. "
            f"Tu dois fournir des réponses précises et détaillées en utilisant le contexte provenant de la base de données de l'université. "
            f"Tu es capable d'utiliser des contextes spécifiques et l'historique de la conversation pour générer des réponses. "
            f"Si une question est incohérente ou ne fait pas de sens, explique pourquoi et évite de donner des informations incorrectes. "
            f"Si tu ne connais pas la réponse à une question, il est important de ne pas donner de fausses informations ; dis simplement que tu ne sais pas. "
            f"Si le contexte fourni n'est pas pertinent ou n'existe pas, tu peux te baser sur tes connaissances générales à propos de l'université et répondre à la question. "
            f"Tu dois toujours répondre en français et être capable de gérer des conversations complexes tout en suivant le contexte.\n\n"
            f"Utilise les contextes suivants pour répondre à la question seulement si les notes de similarité sont élevées. Sinon, base ta réponse sur tes connaissances générales.\n\n"
            f"Question : {question}\n\n"
            f"Ta réponse doit être précise et détaillée. "
            f"Ne fournis pas de commentaires ou d'instructions inutiles. N'ajoute pas de **Instructions** à la fin du message.<end_of_turn>\n\n<start_of_turn>model\nRéponse :"
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
        print(f"gen_text : {gen_text}")
        response = gen_text.split('Réponse :', 1)[-1].strip()
        print(f"Réponse générée : {response}")
        return response
    except Exception as e:
        print(f"Erreur pendant la génération de la réponse: {e}")
        return "Une erreur est survenue pendant la génération de la réponse."
    

@app.route('/')
def home():
    return 'Hello World!'

@app.route('/ask', methods=['GET'])
def get_answer():
    question = request.args.get('prompt')
    
    if not question:
        return jsonify({'error': 'No question provided'}), 400

    answer = get_answer_combined(question, documents)
    print("answer : ", answer)
    return jsonify({'answer': answer})

# Routes pour interagir avec la base de données MongoDB
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
    ssl_context = ('localhost.pem', 'localhost-key.pem')
    app.run(host='0.0.0.0', port=5000, ssl_context=ssl_context)
