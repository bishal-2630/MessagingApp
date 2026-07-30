import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'package:flutter/material.dart';
import 'providers/theme_provider.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'config/theme.dart';
import 'screens/messages.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/search_user.dart';
import 'screens/chat.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final token = await AuthService.getAccessToken();
  if(token !=null) {
    await NotificationService.init();

    // 1. App is in background (but not closed)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final convIdStr = message.data['conversationId'];
      if(convIdStr != null) {
        navigatorKey.currentState?.pushNamed('/chat', arguments: {
          'conversationId': int.parse(convIdStr),
          'username': message.notification?.title?.replaceAll('New message from ', '') ?? 'Chat',
        });
      }
    });

    // 2. App was completely closed (terminated)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final convIdStr = initialMessage.data['conversationId'];
      if (convIdStr != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          navigatorKey.currentState?.pushNamed('/chat', arguments: {
            'conversationId': int.parse(convIdStr),
            'username': initialMessage.notification?.title?.replaceAll('New message from ', '') ?? 'Chat'
          });
        });
      }
    }
  }
  runApp(
    ProviderScope(
      child: MyApp(initialRoute: token == null ? '/' : '/messages')
    ),
  );
}

class MyApp extends ConsumerWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Chatme',
      theme: ThemeData.light(),
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: initialRoute,
      
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/messages': (context) => const MessageScreen(),
        '/search': (context) => const SearchUserScreen(),
        '/chat': (context) => const ChatScreen(),
      },
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
