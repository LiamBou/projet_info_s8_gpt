// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:projet_info_s8_gpt/models/conversation.dart';
import 'package:projet_info_s8_gpt/providers/conversation_provider.dart';
import 'package:projet_info_s8_gpt/utils/suggestion_api_interface.dart';
import 'package:provider/provider.dart';

import '../models/suggestion.dart';

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

    final _userController = TextEditingController();
    final _suggestionController = TextEditingController();

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DrawerHeader(
            child: Column(
              children: [
                const Icon(
                  Icons.person,
                  size: 80,
                  color: Color.fromRGBO(224, 111, 36, 1),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  child: ElevatedButton(
                    onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => Dialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                margin: const EdgeInsets.all(10),
                                child: const Text('Faire une suggestion')),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _userController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: "Nom de l'utilisateur",
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _suggestionController,
                                minLines: 1,
                                maxLines: 5,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: 'Entrez votre suggestion',
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (_suggestionController.text.trim().isEmpty ||
                                    _userController.text.trim().isEmpty) {
                                  return;
                                }
                                Navigator.of(context).pop();
                                SuggestionApiInterface.instance.putSuggestion(
                                    Suggestion(
                                        username: _userController.text,
                                        description: _suggestionController.text,
                                        date: DateTime.now().toString()),
                                    context);
                              },
                              child: const Text('Envoyer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: const Text('Faire une suggestion'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                for (int i = 0; i < conversations.length; i++)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 8, right: 8, bottom: 5),
                    child: ListTile(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      enabled: true,
                      leading: const Icon(Icons.message),
                      trailing: IconButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                          ),
                          onPressed: () {
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
                          icon: const Icon(Icons.delete)),
                      title: Text(conversations[i].name),
                      selected: conversationSelected &&
                          conversations[i].id == selectedConversation.id,
                      selectedTileColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color.fromRGBO(0, 87, 147, 1)
                              : const Color.fromRGBO(0, 87, 147, 1),
                      selectedColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.white,
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
