import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool? isLoading;

  const ChatBubble(
      {super.key,
      required this.text,
      required this.isUser,
      this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser)
          Container(
            margin: const EdgeInsets.only(left: 5, bottom: 15),
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
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: isUser
                  ? const Color.fromRGBO(224, 111, 36, 1)
                  : const Color.fromRGBO(0, 87, 147, 1),
              borderRadius: isUser
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
          child: (isLoading ?? false)
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
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
        if (isUser)
          Container(
              margin: const EdgeInsets.only(right: 5, bottom: 15),
              child: const Icon(
                Icons.person,
                color: Color.fromRGBO(224, 111, 36, 1),
                size: 30,
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
