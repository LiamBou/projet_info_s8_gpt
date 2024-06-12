import 'package:flutter/widgets.dart';
import 'package:projet_info_s8_gpt/models/chat.dart';
import 'package:projet_info_s8_gpt/utils/chat_database_interface.dart';

class ChatProvider extends ChangeNotifier {
  final ChatDatabaseInterface _databaseInterface =
      ChatDatabaseInterface.instance;

  List<Chat> _chatList = [];
  Map<int, List<Chat>> _chatsByConversation = {};

  List<Chat> get chatList => _chatList;
  Map<int, List<Chat>> get chatsByConversation => _chatsByConversation;

  ChatProvider() {
    loadChats();
  }

  Future<void> loadChats() async {
    _chatList = await _databaseInterface.chats;

    _chatsByConversation.clear();
    for (Chat chat in _chatList) {
      if (_chatsByConversation.containsKey(chat.conversationId)) {
        _chatsByConversation[chat.conversationId]!.add(chat);
      } else {
        _chatsByConversation[chat.conversationId] = [chat];
      }
    }
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

  Future<void> deleteChatsByConversation(int conversationId) async {
    await _databaseInterface.deleteChatsByConversation(conversationId);
    loadChats();
  }

  Future<void> updateChatGood(int id, int good) async {
    await _databaseInterface.updateChatGood(id, good);
    loadChats();
  }
}
