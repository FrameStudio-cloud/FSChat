import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  try {
    await NotificationService.init('7f9abadb-2c15-4019-80c6-a6d2393dc282');
  } catch (e) {
    debugPrint('OneSignal init failed: $e');
  }

  final themeProvider = ThemeProvider();
  await themeProvider.loadPreference();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'FSChat',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF075E54),
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF075E54),
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: themeProvider.themeMode,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/chat':
                return MaterialPageRoute(
                  builder: (_) => const ChatScreen(),
                  settings: settings,
                );
              case '/settings':
                return MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                  settings: settings,
                );
            }
            return null;
          },
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return auth.isSignedIn
                  ? const ChatListScreen()
                  : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
