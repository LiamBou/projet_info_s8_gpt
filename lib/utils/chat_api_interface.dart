import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:projet_info_s8_gpt/models/chat.dart';

class ChatApiInterface {
  static final ChatApiInterface instance = ChatApiInterface._internal();

  ChatApiInterface._internal();

  Future<Chat?> askPrompt(Chat newChat, int conversationId) async {
    String payload = newChat.message;

    debugPrint(payload);
    final resp = await http
        .get(Uri.parse('http://10.4.17.150:5000/ask?prompt=$payload'));
    debugPrint("answer: ${resp.body}");
    if (resp.statusCode != 200) {
      return Chat(
        conversationId: conversationId,
        isUser: false,
        message: "Impossible de contacter l'API",
        sentAt: DateTime.now(),
      );
    }

    Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
    debugPrint(data.toString());
    return Chat(
      conversationId: conversationId,
      isUser: false,
      message: (data['answer'] ?? "Erreur lors de la réponse API") as String,
      sentAt: DateTime.now(),
    );
  }
}
