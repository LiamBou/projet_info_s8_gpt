from flask import Flask, request, jsonify

app = Flask(__name__)


@app.route('/')
def hello():
    return 'Hello World!'

@app.route('/ask', methods=['GET'])
def getAnswer():
    content = request.args.get('prompt')
    
    if not content:
        return jsonify({'error': 'No question provided'}), 400

    # Call our IA model here
    # context = ...
    # answer = ...
    # return jsonify({'answer': answer}) 

# CAN ADD OTHER ROUTES IF NEEDED

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000) #Can choose an other port
