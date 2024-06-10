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
    bool showSuggestionSent = false;

    final _userController = TextEditingController();
    final _suggestionController = TextEditingController();

    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/user_profile.png'),
                        radius: 40,
                      ),
                      DrawerHeader(
                        child: Column(
                          children: [
                            const CircleAvatar(
                              backgroundImage:
                                  AssetImage('assets/user_profile.png'),
                              radius: 40,
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              child: ElevatedButton(
                                onPressed: () => showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => Dialog(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                            margin: const EdgeInsets.all(10),
                                            child: const Text(
                                                'Faire une suggestion')),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: TextField(
                                            controller: _userController,
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
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Entrez votre suggestion',
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (_suggestionController.text
                                                    .trim()
                                                    .isEmpty ||
                                                _userController.text
                                                    .trim()
                                                    .isEmpty) {
                                              return;
                                            }
                                            Navigator.of(context).pop();
                                            showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) =>
                                                        AlertDialog(
                                                          title: const Text(
                                                              'Merci pour votre suggestion !'),
                                                          content: const Icon(
                                                            Icons
                                                                .check_circle_rounded,
                                                            color: Colors.green,
                                                            size: 50,
                                                          ),
                                                          actions: <Widget>[
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: const Text(
                                                                  'OK'),
                                                            ),
                                                          ],
                                                        ));
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
                      for (int i = 0; i < conversations.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 8, right: 8, bottom: 5),
                          child: ListTile(
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
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
                      context
                          .read<ConversationProvider>()
                          .updateSelectedConversation(
                              selectedConversation?.id ?? 0,
                              conversations.length + 1);
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
