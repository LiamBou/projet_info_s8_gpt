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
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, ThemeMode currentTheme, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GPT-Evry-Chatbot',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: currentTheme,
          home: MyHomePage(
              title: 'GPT App', themeModeNotifier: themeModeNotifier),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key, required this.title, required this.themeModeNotifier});

  final String title;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool light = true;
  final WidgetStateProperty<Icon?> themeIcon =
      WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return const Icon(Icons.light_mode);
    }
    return const Icon(Icons.dark_mode, color: Colors.white);
  });

  @override
  Widget build(BuildContext context) {
    light = widget.themeModeNotifier.value == ThemeMode.light;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          Switch(
              thumbIcon: themeIcon,
              value: light,
              activeColor: Colors.white,
              activeTrackColor: Colors.deepPurple,
              inactiveTrackColor: Colors.transparent,
              inactiveThumbColor: Colors.deepPurple,
              onChanged: (bool value) {
                setState(() {
                  light = value;
                  widget.themeModeNotifier.value =
                      light ? ThemeMode.light : ThemeMode.dark;
                });
              })
        ],
      ),
      drawer: const CustomDrawer(),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: const Center(
        child: ChatScreen(),
      ),
    );
  }
}
