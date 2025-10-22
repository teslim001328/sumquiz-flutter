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

import 'models/user_model.dart';
import 'models/local_summary.dart';
import 'models/local_quiz.dart';
import 'models/local_quiz_question.dart';
import 'models/local_flashcard.dart';
import 'models/local_flashcard_set.dart';
import 'models/spaced_repetition.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'view_models/quiz_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
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
    developer.log('Error during app initialization',
        name: 'my_app.main', error: e, stackTrace: s);
    runApp(ErrorApp(error: e.toString()));
    return;
  }

  final authService = AuthService(FirebaseAuth.instance);
  final appRouter = createAppRouter(authService);

  runApp(MyApp(authService: authService, router: appRouter));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final GoRouter router;

  const MyApp({super.key, required this.authService, required this.router});

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
        ChangeNotifierProvider<QuizViewModel>(
          create: (context) => QuizViewModel(
            Provider.of<LocalDatabaseService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'SumQuiz',
            theme: themeProvider.getTheme(),
            darkTheme: themeProvider.getTheme(),
            themeMode: themeProvider.themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
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
