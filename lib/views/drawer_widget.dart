import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:projet_info_s8_gpt/models/conversation.dart';
import 'package:projet_info_s8_gpt/providers/conversation_provider.dart';
import 'package:provider/provider.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    List<Conversation> conversations =
        context.watch<ConversationProvider>().conversationList;
    Conversation? selectedConversation = context
        .watch<ConversationProvider>()
        .conversationList
        .firstWhereOrNull((element) => element.selected == true);

    bool conversationSelected = selectedConversation != null;
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
                    padding:
                        const EdgeInsets.only(left: 8, right: 8, bottom: 5),
                    child: ListTile(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      enabled: true,
                      leading: const Icon(Icons.message),
                      title: Text(conversations[i].name),
                      selected: conversationSelected &&
                          conversations[i].id == selectedConversation.id,
                      selectedTileColor: Colors.blue[100],
                      onTap: () {
                        context
                            .read<ConversationProvider>()
                            .updateSelectedConversation(
                                selectedConversation?.id ?? 0,
                                conversations[i].id ?? 0);
                        Navigator.pop(context);
                      },
                      onLongPress: () {
                        int newID;
                        if (i > 0) {
                          newID = conversations[i - 1].id ?? 0;
                        } else if (i < conversations.length - 1) {
                          newID = conversations[i + 1].id ?? 0;
                        } else {
                          newID = 0;
                        }
                        context
                            .read<ConversationProvider>()
                            .updateSelectedConversation(
                                selectedConversation?.id ?? 0, newID);
                        context
                            .read<ConversationProvider>()
                            .deleteConversation(conversations[i].id ?? 0);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                context.read<ConversationProvider>().addConversation(
                    Conversation(
                        id: conversations.length + 1,
                        name: 'Conversation ${conversations.length + 1}',
                        selected: true));
                context.read<ConversationProvider>().updateSelectedConversation(
                    selectedConversation?.id ?? 0, conversations.length + 1);
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
