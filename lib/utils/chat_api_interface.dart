import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:projet_info_s8_gpt/models/chat.dart';

class ChatApiInterface {
  static final ChatApiInterface instance = ChatApiInterface._internal();

  ChatApiInterface._internal();

  Future<Chat?> askPrompt(Chat newChat, int conversationId) async {
    String payload = newChat.message;
    debugPrint("Payload: $payload");
    final resp = await http
        .get(Uri.parse('https://10.4.17.150:5000/ask?prompt=$payload'));
    if (resp.statusCode != 200) {
      debugPrint("Error: ${resp.body}");
      return Chat(
        conversationId: conversationId,
        isUser: false,
        message: "Impossible de contacter l'API",
        sentAt: DateTime.now(),
        good: 0,
      );
    }

    Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Chat(
      conversationId: conversationId,
      isUser: false,
      message: (data['answer'] ?? "Erreur lors de la réponse API") as String,
      sentAt: DateTime.now(),
      good: 0,
    );
  }

  Future<Chat?> askPromptWithPreviousChats(
      List<Chat> chats, String question, int conversationId) async {
    String history = "";
    int nbChatsToAsk = chats.length >= 6 ? 6 : chats.length;
    if (nbChatsToAsk != 0) {
      for (int i = chats.length - nbChatsToAsk; i < chats.length; i++) {
        history +=
            '${chats[i].isUser ? '<start_of_turn>user ' : '<start_of_turn>model'}${chats[i].message}<end_of_turn>';
      }
    }
    debugPrint("Question: $question");
    debugPrint("History: $history");

    final resp = await http.get(Uri.parse(
        'https://172.20.10.2:5000/ask?prompt=$question&history=$history'));
    if (resp.statusCode != 200) {
      return Chat(
        conversationId: conversationId,
        isUser: false,
        message: "Impossible de contacter l'API",
        sentAt: DateTime.now(),
        good: 0,
      );
    }

    Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Chat(
      conversationId: conversationId,
      isUser: false,
      message: (data['answer'] ?? "Erreur lors de la réponse API") as String,
      sentAt: DateTime.now(),
      good: 0,
    );
  }
}
