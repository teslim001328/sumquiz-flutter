import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:developer' as developer;

import 'firebase_options.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/local_database_service.dart';
import 'services/upgrade_service.dart';

import 'views/screens/auth_screen.dart';
import 'views/screens/main_screen.dart';
import 'views/screens/settings_screen.dart';
import 'views/screens/spaced_repetition_screen.dart';
import 'views/screens/summary_screen.dart';
import 'views/screens/quiz_screen.dart';
import 'views/screens/flashcards_screen.dart';
import 'views/screens/edit_content_screen.dart';

import 'models/user_model.dart';
import 'models/local_summary.dart';
import 'models/local_quiz.dart';
import 'models/local_quiz_question.dart';
import 'models/local_flashcard.dart';
import 'models/local_flashcard_set.dart';
import 'models/spaced_repetition.dart';
import 'models/editable_content.dart';
import 'views/theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );

    await Hive.initFlutter();
    Hive.registerAdapter(LocalSummaryAdapter());
    Hive.registerAdapter(LocalQuizAdapter());
    Hive.registerAdapter(LocalQuizQuestionAdapter());
    Hive.registerAdapter(LocalFlashcardAdapter());
    Hive.registerAdapter(LocalFlashcardSetAdapter());
    Hive.registerAdapter(SpacedRepetitionItemAdapter());

    await Hive.openBox<LocalSummary>('summaries');
    await Hive.openBox<LocalQuiz>('quizzes');
    await Hive.openBox<LocalFlashcardSet>('flashcard_sets');
    await Hive.openBox<SpacedRepetitionItem>('spaced_repetition');
  } catch (e, s) {
    developer.log('Error during app initialization', name: 'my_app.main', error: e, stackTrace: s);
    runApp(ErrorApp(error: e.toString()));
    return;
  }

  final authService = AuthService(FirebaseAuth.instance);

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
      redirect: (context, state) {
        final user = authService.currentUser;
        final loggingIn = state.matchedLocation == '/auth';

        if (user == null) {
          return loggingIn ? null : '/auth';
        }

        if (loggingIn) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MainScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => AuthScreen(authService: authService),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/spaced-repetition',
          builder: (context, state) => const SpacedRepetitionScreen(),
        ),
        GoRoute(
          path: '/summary',
          builder: (context, state) => const SummaryScreen(),
        ),
        GoRoute(
          path: '/quiz',
          builder: (context, state) => const QuizScreen(),
        ),
        GoRoute(
          path: '/flashcards',
          builder: (context, state) => const FlashcardsScreen(),
        ),
        GoRoute(
          path: '/edit-content',
          builder: (context, state) => EditContentScreen(content: state.extra! as EditableContent),
        ),
      ],
    );

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
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $error'),
        ),
      ),
    );
  }
}
