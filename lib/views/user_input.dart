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
    List<Chat> chats = context
            .watch<ChatProvider>()
            .chatsByConversation[widget.conversationId] ??
        [];
    return Container(
      margin: const EdgeInsets.all(10),
      child: TextField(
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: 6,
        autofocus: false,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: 'Posez une question...',
          suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                if (_controller.text.trim().isEmpty) {
                  return;
                }
                if (chats.isNotEmpty && chats.last.isUser == true) {
                  return;
                }
                context
                    .read<ChatProvider>()
                    .addChat(Chat(
                        message: _controller.text,
                        isUser: true,
                        conversationId: widget.conversationId,
                        sentAt: DateTime.now()))
                    .then((value) {
                  widget.setDisplayLoading(true);
                  debugPrint("Chats: $chats");
                  // Ask the prompt to the API with 3 or 2 or last previous chats and the current question
                  ChatApiInterface.instance
                      .askPromptWithPreviousChats(
                          context
                                  .read<ChatProvider>()
                                  .chatsByConversation[widget.conversationId] ??
                              [],
                          _controller.text,
                          widget.conversationId)
                      .then((value) {
                    widget.setDisplayLoading(false);
                    context.read<ChatProvider>().addChat(value!);
                  });
                  _controller.clear();
                });
              }),
        ),
        controller: _controller,
      ),
    );
  }
}
