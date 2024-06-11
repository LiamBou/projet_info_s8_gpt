import 'package:flutter/material.dart';
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
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      drawer: const CustomDrawer(),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: const Center(
        child: ChatScreen(),
      ),
    );
  }
}
