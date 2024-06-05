import 'package:flutter/cupertino.dart';
import 'chat_bubble_widget.dart';
import 'user_input.dart';

class ChatScreen extends StatelessWidget {
  final int id;

  const ChatScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                ChatBubble(
                  text: 'Hello World !$id',
                  isUser: true,
                  isLoading: false,
                ),
                const ChatBubble(
                  text: 'Hello Flutter !',
                  isUser: false,
                  isLoading: true,
                ),
              ],
            ),
          ),
          UserInput(
            onSend: (value) {
              print(value);
            },
          ),
        ],
      ),
    );
  }
}
