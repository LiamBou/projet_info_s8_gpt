import 'package:flutter/material.dart';
import 'package:projet_info_s8_gpt/models/conversation.dart';
import 'package:projet_info_s8_gpt/providers/chat_provider.dart';
import 'package:projet_info_s8_gpt/providers/conversation_provider.dart';
import 'package:provider/provider.dart';
import 'views/chat_screen.dart';
import 'views/drawer_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  @override
  Widget build(BuildContext context) {
    List<Conversation> conversations =
        context.read<ConversationProvider>().conversationList;

    Conversation? selectedConversation;
    conversations.isEmpty
        ? selectedConversation = null
        : selectedConversation = conversations.first;

    void selectPage(Conversation conversation) {
      setState(() {
        selectedConversation = conversation;
      });
      debugPrint('Selected conversation: ${conversation.name}');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      drawer: CustomDrawer(selectConversation: selectPage),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: Center(
        child: ChatScreen(conversation: selectedConversation),
      ),
    );
  }
}
