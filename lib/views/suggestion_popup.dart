import 'package:flutter/material.dart';

class SuggestionPopup extends StatelessWidget {
  const SuggestionPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          const Text('Faire une suggestion'),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Entrez votre suggestion',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
