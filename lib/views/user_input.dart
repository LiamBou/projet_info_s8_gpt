import 'package:flutter/material.dart';
import 'package:projet_info_s8_gpt/providers/chat_provider.dart';
import 'package:projet_info_s8_gpt/utils/chat_api_interface.dart';
import 'package:provider/provider.dart';
import 'package:projet_info_s8_gpt/models/chat.dart';

class UserInput extends StatefulWidget {
  final int conversationId;
  final Null Function(bool value) setDisplayLoading;

  const UserInput(
      {super.key,
      required this.conversationId,
      required this.setDisplayLoading});

  @override
  State<UserInput> createState() => _UserInputState();
}

class _UserInputState extends State<UserInput> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: TextField(
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: 6,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Posez une question...',
          suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                if (_controller.text.trim().isEmpty) {
                  return;
                }
                context.read<ChatProvider>().addChat(Chat(
                    message: _controller.text,
                    isUser: true,
                    conversationId: widget.conversationId,
                    sentAt: DateTime.now()));
                widget.setDisplayLoading(true);
                ChatApiInterface.instance
                    .askPrompt(
                        Chat(
                            message: _controller.text,
                            isUser: true,
                            conversationId: widget.conversationId,
                            sentAt: DateTime.now()),
                        widget.conversationId)
                    .then((value) {
                  widget.setDisplayLoading(false);
                  context.read<ChatProvider>().addChat(value!);
                });
                _controller.clear();
              }),
        ),
        controller: _controller,
      ),
    );
  }
}