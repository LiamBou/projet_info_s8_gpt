import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
      children: [
        if (!isUser)
          Container(
            margin: const EdgeInsets.only(left: 5),
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
              color: isUser ? Colors.blue : Colors.pinkAccent,
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
                  color: Colors.black, size: 25)
              : Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        if (isUser)
          Container(
              margin: const EdgeInsets.only(right: 5),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
              )),
      ],
    );
  }
}