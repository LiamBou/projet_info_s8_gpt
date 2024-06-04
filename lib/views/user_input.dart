import 'package:flutter/material.dart';

class UserInput extends StatelessWidget {
  final Function(String) onSend;

  const UserInput({super.key, required this.onSend});

  void ntm() {
    print("tapped");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Posez une question...',
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: ntm,
          ),
        ),
        onSubmitted: (value) {
          onSend(value);
        },
      ),
    );
  }
}
