import 'package:flutter/material.dart';
import 'chat_screen.dart';

class CustomDrawer extends StatefulWidget {
  final void Function(int) selectPage;
  final List<ChatScreen> chats;

  const CustomDrawer(
      {super.key, required this.selectPage, required this.chats});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  void selectPage(int page) {
    widget.selectPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Drawer Header',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          for (int i = 0; i < widget.chats.length; i++)
            ListTile(
              leading: const Icon(Icons.message),
              title: Text('Chat ${widget.chats[i].id}'),
              onTap: () {
                selectPage(i);
              },
            ),
        ],
      ),
    );
  }
}
