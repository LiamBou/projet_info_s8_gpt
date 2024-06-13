import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/chat.dart';
import '../providers/chat_provider.dart';

class ChatBubble extends StatefulWidget {
  final int chatId;
  final String text;
  final bool isUser;
  final bool? isLoading;

  const ChatBubble(
      {super.key,
      required this.chatId,
      required this.text,
      required this.isUser,
      this.isLoading = false});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  @override
  Widget build(BuildContext context) {
    Chat? chat = context
        .watch<ChatProvider>()
        .chatList
        .firstWhereOrNull((element) => element.id == widget.chatId);
    return Row(
      mainAxisAlignment:
          widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!widget.isUser)
          Container(
            margin: (widget.isLoading ?? false)
                ? const EdgeInsets.only(left: 5)
                : const EdgeInsets.only(left: 5, bottom: 15),
            padding: (widget.isLoading ?? false)
                ? const EdgeInsets.all(0)
                : const EdgeInsets.only(bottom: 32),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.transparent,
              foregroundImage: const AssetImage(
                'assets/universite-evry.png',
              ),
              radius: 20,
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              margin: widget.isUser
                  ? const EdgeInsets.all(10)
                  : const EdgeInsets.only(right: 10, left: 10, top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: widget.isUser
                      ? const Color.fromRGBO(224, 111, 36, 1)
                      : const Color.fromRGBO(0, 87, 147, 1),
                  borderRadius: widget.isUser
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        )),
              child: (widget.isLoading ?? false)
                  ? LoadingAnimationWidget.fourRotatingDots(
                      color: Colors.white, size: 25)
                  : Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      child: MarkdownBody(
                        selectable: true,
                        onTapLink: (text, href, title) async {
                          if (!context.mounted) return;
                          await _launchUrl(href);
                        },
                        data: widget.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
            if (!widget.isUser && !(widget.isLoading ?? false))
              Container(
                padding: const EdgeInsets.only(right: 15),
                child: Row(children: [
                  IconButton(
                    color: Colors.transparent,
                    icon: Icon(
                      Icons.thumb_up,
                      color: chat?.good == 1
                          ? Colors.green
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black),
                    ),
                    onPressed: () {
                      if (chat?.good == 1) {
                        context
                            .read<ChatProvider>()
                            .updateChatGood(widget.chatId, 0);
                      } else {
                        context
                            .read<ChatProvider>()
                            .updateChatGood(widget.chatId, 1);
                      }
                    },
                  ),
                  IconButton(
                    color: Colors.transparent,
                    icon: Icon(
                      Icons.thumb_down,
                      color: chat?.good == -1
                          ? Colors.red
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black),
                    ),
                    onPressed: () {
                      if (chat?.good == -1) {
                        context
                            .read<ChatProvider>()
                            .updateChatGood(widget.chatId, 0);
                      } else {
                        context
                            .read<ChatProvider>()
                            .updateChatGood(widget.chatId, -1);
                      }
                    },
                  ),
                ]),
              )
          ],
        ),
        if (widget.isUser)
          Container(
              margin: const EdgeInsets.only(right: 5, bottom: 15),
              child: const Icon(
                Icons.person,
                color: Color.fromRGBO(224, 111, 36, 1),
                size: 35,
              )),
      ],
    );
  }
}

Future<void> _launchUrl(String? href) async {
  Uri url = Uri.parse(href!);
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}
