import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/upgrade_service.dart';
import 'services/local_database_service.dart';
import 'views/screens/auth_wrapper.dart';
import 'models/user_model.dart';
import 'views/theme.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/ai_tools_screen.dart';
import 'views/screens/library_screen.dart';
import 'views/screens/progress_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/main_screen.dart';
import 'views/screens/summary_screen.dart';
import 'views/screens/flashcards_screen.dart';
import 'views/screens/quiz_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalDatabaseService().init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate App Check
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    );
    developer.log('Firebase App Check activated.', name: 'com.example.myapp.main');
    FirebaseAppCheck.instance.onTokenChange.listen((token) {
      developer.log('App Check Token: $token', name: 'com.example.myapp.app_check');
    });
  } catch (e) {
    developer.log('Error activating Firebase App Check: $e', name: 'com.example.myapp.main');
  }

  final authService = AuthService(FirebaseAuth.instance);

  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(MyApp(authService: authService));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthWrapper(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return const MainScreen();
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const AiToolsScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/summary',
      builder: (context, state) => const SummaryScreen(),
    ),
    GoRoute(
      path: '/flashcards',
      builder: (context, state) => const FlashcardsScreen(),
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => const QuizScreen(),
    ),
  ],
  redirect: (context, state) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bool loggedIn = authService.currentUser != null;
    final bool loggingIn = state.matchedLocation == '/auth';

    if (!loggedIn) {
      return '/auth';
    }

    if (loggingIn) {
      return '/';
    }

    return null;
  },
);

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        StreamProvider<User?>.value(
          value: authService.authStateChanges,
          initialData: null,
        ),
        StreamProvider<UserModel?>.value(
          value: authService.user,
          initialData: null,
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<UpgradeService>(
          create: (_) => UpgradeService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<LocalDatabaseService>(
          create: (_) => LocalDatabaseService(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'SumQuiz',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
