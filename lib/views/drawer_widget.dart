import 'package:flutter/material.dart';
import 'package:projet_info_s8_gpt/models/conversation.dart';
import 'package:projet_info_s8_gpt/providers/conversation_provider.dart';
import 'package:provider/provider.dart';

class CustomDrawer extends StatefulWidget {
  final void Function(Conversation) selectConversation;

  const CustomDrawer({super.key, required this.selectConversation});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  void selectConv(Conversation conversation) {
    widget.selectConversation(conversation);
  }

  @override
  Widget build(BuildContext context) {
    List<Conversation> conversations =
        context.watch<ConversationProvider>().conversationList;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/user_profile.png'),
                  radius: 40,
                ),
              ],
            ),
          ),
          for (int i = 0; i < conversations.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 5),
              child: ListTile(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                enabled: true,
                leading: const Icon(Icons.message),
                title: Text(conversations[i].name),
                selectedTileColor: Colors.blue[200],
                splashColor: Colors.blue[200],
                onTap: () {
                  selectConv(conversations[i]);
                  Navigator.pop(context);
                },
              ),
            ),
          Container(
            margin: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                context.read<ConversationProvider>().addConversation(
                    Conversation(
                        id: conversations.length + 1,
                        name: 'Conversation ${conversations.length + 1}'));
              },
              onLongPress: () {
                debugPrint('Deleting conversation');
                context.read<ConversationProvider>().deleteConversation(
                    conversations[conversations.length - 1].id ?? 0);
              },
              child: const Text('Add Conversation'),
            ),
          ),
        ],
      ),
    );
  }
}
