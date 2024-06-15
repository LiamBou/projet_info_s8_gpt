
# Projet ChatBot Université Evry Paris-Saclay 

Ce projet développe un chatbot éducatif conçu pour répondre aux questions des utilisateurs concernant l'Université Evry Paris-Saclay en utilisant des techniques d'intelligence artificielle avancées. Le chatbot analyse les questions et extrait des réponses pertinentes à partir de documents stockés dans une base de données MongoDB.
## Bibliothèques et Technologies Utilisées

  ### Transformateurs et Modèles de Langage

**Model utilisé :** `Ggemma-1.1-7b-it`

**Transformers (Hugging Face):** Utilisé pour le chargement et l'inférence des modèles de langage, notamment avec AutoTokenizer et AutoModelForCausalLM.

**BitsAndBytes :** Employé pour la quantification des modèles afin de réduire l'utilisation de la mémoire et accélérer les calculs


  ### Base de Données et Traitement des Textes
**MongoDB (PyMongo) :** Base de données NoSQL utilisée pour stocker les documents et suggestions.

**Scikit-learn :** Utilisé pour la vectorisation des textes avec TfidfVectorizer et la comparaison de similarité des textes avec cosine_similarity.

  ### Framework Web
**Flask :** Cadre web léger pour la création de routes et la gestion des requêtes HTTPS.


## Fonctionnalités de l'IA

  ### Chargement et Quantification du Modèle
Le modèle utilisé est AutoModelForCausalLM de la bibliothèque Transformers, avec une configuration de quantification en 4 bits pour une performance optimisée. La quantification en 4 bits permet de réduire la taille du modèle et d'accélérer les calculs, tout en minimisant la perte de précision.

  ### Vectorisation et Analyse des Textes
Les documents et les questions sont transformés en vecteurs à l'aide de TfidfVectorizer pour faciliter la comparaison et la recherche de similarité.

**Vectorisation des Documents :** Les textes sont convertis en vecteurs numériques pondérés en fonction de la fréquence des termes dans les documents, permettant une comparaison efficace.

**Comparaison de Similarité :** La similarité cosinus est utilisée pour comparer les vecteurs des documents à ceux de la question, aidant ainsi à identifier les contextes les plus pertinents.

  ### Recherche de Contextes Pertinents
L'algorithme identifie les documents les plus pertinents à partir de la base de données MongoDB en fonction de la similarité des vecteurs. Les documents pertinents sont ensuite utilisés pour générer des réponses détaillées et précises.

  ### Génération de Réponses
Le modèle génère des réponses en utilisant le contexte pertinent et l'historique des conversations pour fournir des réponses détaillées et adaptées à la question posée.
## Pré-requis

- Python 3.x installé 

- MongoDB installé et en cours d'exécution sur localhost : 27017
```bash
  sudo apt install -y cuda
```
- CUDA (optionnel, pour l'accélération GPU)
```bash
    sudo apt install -y cuda
```
L'installation des extentions 
```bash
    pip install torch transformers sentence-transformers pymongo flask flask-talisman scikit-learn numpy bson 
```


## Utilisation

Accédez à l'application en ouvrant un navigateur et en naviguant vers https://localhost:5000

Posez une question en utilisant l'API GET à https://localhost:5000/ask?prompt=<votre_question>
## Auteurs

- [@sadoqghita](https://github.com/sadoqghita)
- [@kadirisalim](https://github.com/SalimKad)
- [@boudadiliam](https://github.com/LiamBou)
- [@abdellahmagueri](https://github.com/abdellahmgr)
