import 'package:flutter/material.dart';
import 'package:projet_info_s8_gpt/models/chat.dart';
import 'package:projet_info_s8_gpt/models/conversation.dart';
import 'package:projet_info_s8_gpt/providers/chat_provider.dart';
import 'package:projet_info_s8_gpt/providers/conversation_provider.dart';
import 'package:provider/provider.dart';
import 'views/chat_screen.dart';
import 'views/drawer_widget.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(create: (_) => ConversationProvider()),
    ],
    child: const MyApp(),
  ));
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
  void selectPage() {
    print("select page called");
  }

  int selectedPage = 0;

  @override
  Widget build(BuildContext context) {
    List<Chat> chats = context.read<ChatProvider>().chatList;
    List<Conversation> conversations =
        context.read<ConversationProvider>().conversationList;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      drawer: CustomDrawer(selectPage: selectPage),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: Center(
        child: chats.isEmpty
            ? const Text('No chats available')
            : ChatScreen(id: selectedPage),
      ),
    );
  }
}
