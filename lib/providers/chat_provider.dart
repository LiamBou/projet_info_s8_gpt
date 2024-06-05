import 'package:flutter/widgets.dart';
import 'package:projet_info_s8_gpt/models/chat.dart';
import 'package:projet_info_s8_gpt/utils/chat_database_interface.dart';

class ChatProvider extends ChangeNotifier {
  final ChatDatabaseInterface _databaseInterface =
      ChatDatabaseInterface.instance;

  List<Chat> _chatList = [];

  List<Chat> get chatList => _chatList;

  ChatProvider() {
    loadChats();
  }

  Future<void> loadChats() async {
    _chatList = await _databaseInterface.chats;
    notifyListeners();
  }

  Future<void> addChat(Chat chat) async {
    await _databaseInterface.insertChat(chat);
    loadChats();
  }

  Future<void> updateChat(Chat chat) async {
    await _databaseInterface.updateChat(chat);
    loadChats();
  }

  Future<void> deleteChat(int id) async {
    await _databaseInterface.deleteChat(id);
    loadChats();
  }

  Future<void> deleteChatsByConversation(String conversationId) async {
    await _databaseInterface.deleteChatsByConversation(conversationId);
    loadChats();
  }
}
