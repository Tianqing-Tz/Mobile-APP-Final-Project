import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/content_screen.dart';
import 'screens/help_screen.dart';
import 'screens/search_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAJqm3h6xqMZtkJ65YPUYbU81-cnCZjRH4',
      appId: '1:32586762212:android:6da446e1522c9f7eed69f1',
      messagingSenderId: '32586762212',
      projectId: 'kayn-7119a',
      storageBucket: 'kayn-7119a.firebasestorage.app',
    ),
  );
  runApp(const SecondHandMarketApp());
}

class SecondHandMarketApp extends StatelessWidget {
  const SecondHandMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return MaterialApp(
      title: 'Campus Second-hand Trading Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.orangeAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: FutureBuilder<Map<String, dynamic>?>(
        future: firebaseService.getCurrentSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/content': (context) => const ContentScreen(),
        '/help': (context) => const HelpScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}
