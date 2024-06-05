import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class CustomDrawer extends StatefulWidget {
  final void Function() selectPage;

  const CustomDrawer({super.key, required this.selectPage});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  void selectPage(int page) {
    widget.selectPage();
  }

  @override
  Widget build(BuildContext context) {
    List<Chat> chats = context.read<ChatProvider>().chatList;

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
          for (int i = 0; i < chats.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 5),
              child: ListTile(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                enabled: true,
                leading: const Icon(Icons.message),
                title: Text('Chat ${chats[i].id}'),
                selectedTileColor: Colors.blue[200],
                selected: false,
                splashColor: Colors.blue[200],
                onTap: () {
                  selectPage(i);
                  Navigator.pop(context);
                },
              ),
            ),
        ],
      ),
    );
  }
}
