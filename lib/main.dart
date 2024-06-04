import 'package:flutter/material.dart';
import 'views/chat_screen.dart';
import 'views/drawer_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPHF GPT Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GPT App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ChatScreen> chats = [
    const ChatScreen(id: 0),
    const ChatScreen(id: 1),
    const ChatScreen(id: 2),
  ];

  int selectedPage = 0;

  void selectPage(int page) {
    setState(() {
      selectedPage = page;
      print('Selected page: $selectedPage');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      drawer: CustomDrawer(selectPage: selectPage, chats: chats),
      body: Center(
        child: chats[selectedPage],
      ),
    );
  }
}
