import 'package:flutter/widgets.dart';
import 'package:projet_info_s8_gpt/models/conversation.dart';
import 'package:projet_info_s8_gpt/utils/chat_database_interface.dart';

class ConversationProvider extends ChangeNotifier {
  final ChatDatabaseInterface _databaseInterface =
      ChatDatabaseInterface.instance;

  List<Conversation> _conversationList = [];

  List<Conversation> get conversationList => _conversationList;

  ConversationProvider() {
    loadConversations();
  }

  Future<void> loadConversations() async {
    _conversationList = await _databaseInterface.conversations;
    notifyListeners();
  }

  Future<void> addConversation(Conversation conversation) async {
    await _databaseInterface.insertConversation(conversation);
    loadConversations();
  }

  Future<void> updateConversation(Conversation conversation) async {
    await _databaseInterface.updateConversation(conversation);
    loadConversations();
  }

  Future<void> updateConversationName(int id, String name) async {
    await _databaseInterface.updateConversationName(id, name);
    loadConversations();
  }

  Future<void> deleteConversation(int id) async {
    await _databaseInterface.deleteConversation(id);
    loadConversations();
  }

  Future<void> updateSelectedConversation(int oldID, int newID) async {
    await _databaseInterface.updateSelectedConversation(oldID, newID);
    debugPrint("Conversation selected : $newID");
    loadConversations();
  }
}
