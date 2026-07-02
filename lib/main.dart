import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/settings_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/chat/screens/create_group_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/blog/providers/blog_provider.dart';
import 'features/blog/screens/blog_post_screen.dart';
import 'features/blog/screens/blog_editor_screen.dart';
import 'features/habits/presentation/screens/habits_list_screen.dart';
import 'features/mood/screens/mood_list_screen.dart';
import 'features/mood/screens/mood_editor_screen.dart';
import 'features/challenges/screens/challenges_list_screen.dart';
import 'features/challenges/screens/challenge_detail_screen.dart';
import 'features/reading_list/presentation/screens/reading_list_screen.dart';
import 'core/services/notification_service.dart';
import 'core/services/isar_service.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplashApp());
}

class SplashApp extends StatefulWidget {
  const SplashApp({super.key});

  @override
  State<SplashApp> createState() => _SplashAppState();
}

class _SplashAppState extends State<SplashApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }

    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }

    try {
      await IsarService.init();
    } catch (e) {
      debugPrint('Isar init failed: $e');
    }

    final themeProvider = ThemeProvider();
    await themeProvider.loadPreference();
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadPreferences();

    if (!mounted) return;
    setState(() {
      _initialized = true;
      _themeProvider = themeProvider;
      _settingsProvider = settingsProvider;
    });
  }

  ThemeProvider? _themeProvider;
  SettingsProvider? _settingsProvider;

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _themeProvider == null || _settingsProvider == null) {
      return const _SplashScreen();
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BlogProvider()),
        ChangeNotifierProvider.value(value: _themeProvider!),
        ChangeNotifierProvider.value(value: _settingsProvider!),
      ],
      child: const MyApp(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFE65100),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'FS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.handlePendingInitialMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final bubbleStyle = BubbleStyle.fromStyle(settings.bubbleStyle);
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: settings.textScaleFactor,
          ),
          child: child!,
        );
      },
      theme: AppTheme.light.copyWith(extensions: [bubbleStyle]),
      darkTheme: AppTheme.dark.copyWith(extensions: [bubbleStyle]),
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
          case '/blog/post':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => BlogPostScreen(postId: args['postId'] as String),
              settings: settings,
            );
          case '/blog/create':
            return MaterialPageRoute(
              builder: (_) => const BlogEditorScreen(),
              settings: settings,
            );
          case '/habits':
            return MaterialPageRoute(
              builder: (_) => const HabitsListScreen(),
              settings: settings,
            );
          case '/mood':
            return MaterialPageRoute(
              builder: (_) => const MoodListScreen(),
              settings: settings,
            );
          case '/challenges':
            return MaterialPageRoute(
              builder: (_) => const ChallengesListScreen(),
              settings: settings,
            );
          case '/challenge/detail':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ChallengeDetailScreen(
                challenge: args['challenge'],
              ),
              settings: settings,
            );
          case '/reading':
            return MaterialPageRoute(
              builder: (_) => const ReadingListScreen(),
              settings: settings,
            );
          case '/create_group':
            return MaterialPageRoute(
              builder: (_) => const CreateGroupScreen(),
              settings: settings,
            );
        }
        return null;
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isSignedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
