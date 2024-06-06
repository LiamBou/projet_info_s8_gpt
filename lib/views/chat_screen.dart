import 'package:flutter/cupertino.dart';
import 'package:projet_info_s8_gpt/models/conversation.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../providers/chat_provider.dart';
import 'chat_bubble_widget.dart';
import 'user_input.dart';

class ChatScreen extends StatelessWidget {
  final Conversation? conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    if (conversation == null) {
      debugPrint('No conversation found');
      return const Center(child: Text('LOADING PAGE'));
    }
    final scrollController = ScrollController();

    bool displayLoading = false;

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            // Conversation name
            margin: const EdgeInsets.only(top: 10),
            child: Text(
              conversation!.name,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Consumer<ChatProvider>(
            builder: (BuildContext context, ChatProvider chatProvider,
                Widget? child) {
              if (chatProvider.chatsByConversation[conversation?.id ?? 0] ==
                  null) {
                return const Center();
              }
              return Expanded(
                child: ListView(
                  reverse: true,
                  controller: scrollController,
                  children: [
                    ...chatProvider.chatsByConversation[conversation?.id ?? 0]!
                        .map<Widget>(
                      (Chat chat) => ChatBubble(
                        text: chat.message,
                        isUser: chat.isUser,
                      ),
                    ),
                    (displayLoading)
                        ? const ChatBubble(
                            text: "", isUser: false, isLoading: true)
                        : const SizedBox(),
                  ].reversed.toList(),
                ),
              );
            },
          ),
          UserInput(
              conversationId: conversation?.id ?? 0,
              setDisplayLoading: (bool value) {
                displayLoading = value;
              }),
        ],
      ),
    );
  }
}
