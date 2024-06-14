import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projet_info_s8_gpt/models/conversation.dart';
import 'package:projet_info_s8_gpt/providers/conversation_provider.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/user_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Conversation? conversation = context
        .watch<ConversationProvider>()
        .conversationList
        .firstWhereOrNull((element) => element.selected == true);
    if (conversation == null) {
      return const Center(child: Text('Créez une conversation pour continuer'));
    }
    final scrollController = ScrollController();

    bool displayLoading = false;

    _controller.text = conversation.name;

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Conversation name
          Container(
            padding: const EdgeInsets.all(10),
            child: Center(
                child: SizedBox(
              width: 200,
              child: TextFormField(
                  textAlign: TextAlign.center,
                  inputFormatters: [LengthLimitingTextInputFormatter(18)],
                  controller: _controller,
                  autofocus: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Nom de la conversation',
                  ),
                  onChanged: (String value) {
                    context
                        .read<ConversationProvider>()
                        .updateConversationName(conversation.id ?? 0, value);
                  }),
            )),
          ),
          // Chat bubbles
          Consumer<ChatProvider>(
            builder: (BuildContext context, ChatProvider chatProvider,
                Widget? child) {
              if (chatProvider.chatsByConversation[conversation.id ?? 0] ==
                  null) {
                return const Center();
              }
              return Expanded(
                child: ListView(
                  reverse: true,
                  controller: scrollController,
                  children: [
                    ...chatProvider.chatsByConversation[conversation.id ?? 0]!
                        .map<Widget>(
                      (Chat chat) => ChatBubble(
                        chatId: chat.id ?? 0,
                        text: chat.message,
                        isUser: chat.isUser,
                      ),
                    ),
                    (displayLoading)
                        ? const ChatBubble(
                            chatId: 0, text: "", isUser: false, isLoading: true)
                        : const SizedBox(),
                  ].reversed.toList(),
                ),
              );
            },
          ),
          UserInput(
              conversationId: conversation.id ?? 0,
              setDisplayLoading: (bool value) {
                displayLoading = value;
              }),
        ],
      ),
    );
  }
}
