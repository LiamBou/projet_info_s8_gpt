import json
import torch
import spacy
import numpy as np
import pandas as pd
from transformers import BertForQuestionAnswering, BertTokenizer, pipeline
import os

# Load SpaCy model with Word2Vec embeddings
nlp = spacy.load('en_core_web_md')

# Load BERT model for question answering
model_name = 'bert-base-uncased'
tokenizer = BertTokenizer.from_pretrained(model_name)
model = BertForQuestionAnswering.from_pretrained(model_name)

# Function to load data from CSV files
def load_data_from_csvs(csv_folder):
    contexts = []
    for filename in os.listdir(csv_folder):
        if filename.endswith('.csv'):
            try:
                df = pd.read_csv(os.path.join(csv_folder, filename), delimiter=';', on_bad_lines='skip', engine='python')
                for _, row in df.iterrows():
                    # Assuming each row represents a context as a combined string of all columns
                    context = ' '.join(map(str, row.values))
                    contexts.append(context)
            except pd.errors.ParserError as e:
                print(f"Error parsing {filename}: {e}")
    return contexts

# Load data from CSV files
csv_folder = '/content/CSV'
contexts = load_data_from_csvs(csv_folder)
questions_with_contexts = [(f"Question {i+1}", context) for i, context in enumerate(contexts)]

# Fine-tune BERT model
optimizer = torch.optim.AdamW(model.parameters(), lr=5e-5)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)
num_epochs = 3

for epoch in range(num_epochs):
    for question, context in questions_with_contexts:
        inputs = tokenizer(question, context, return_tensors="pt", padding=True, truncation=True, max_length=512)
        inputs.to(device)
        optimizer.zero_grad()
        outputs = model(**inputs)
        loss = outputs.loss
        if loss is not None:
            loss.backward()
            optimizer.step()

# Load pipeline for question answering
qa_pipeline = pipeline('question-answering', model='distilbert-base-cased-distilled-squad')

# Function to find relevant context using word embeddings
def find_relevant_context(question, contexts, embeddings_model):
    question_vector = np.mean([embeddings_model(word.text).vector for word in nlp(question.lower())], axis=0)
    relevant_context = None
    max_similarity = -1  # Initialize with a scalar value
    for context in contexts:
        context_vector = np.mean([embeddings_model(word.text).vector for word in nlp(context.lower())], axis=0)
        if not np.any(np.isnan(question_vector)) and not np.any(np.isnan(context_vector)):  # Check for NaN values
            similarity = np.dot(question_vector, context_vector) / (
                        np.linalg.norm(question_vector) * np.linalg.norm(context_vector))
            if similarity > max_similarity:
                max_similarity = similarity
                relevant_context = context
    return relevant_context

# Function to get answer using combined approach
def get_answer_combined(question, contexts):
    context = find_relevant_context(question, contexts, nlp)
    if context:
        output = qa_pipeline({"context": context, "question": question})
        return output['answer']
    else:
        return "No relevant context found."

# User input loop
print("Type your question (type 'exit' to quit):")
while True:
    user_question = input("Question: ")
    if user_question.lower() == 'exit':
        break
    answer = get_answer_combined(user_question, contexts)
    print(f"Answer: {answer}")