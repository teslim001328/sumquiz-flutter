import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/local_database_service.dart';
import 'package:myapp/views/screens/auth_wrapper.dart';
import 'package:myapp/models/user_model.dart';
import 'firebase_options.dart';
import 'package:myapp/services/ai_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/view_models/quiz_view_model.dart';
import 'package:myapp/services/upgrade_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize the local database service
  await LocalDatabaseService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<AIService>(create: (_) => AIService()),
        Provider<UpgradeService>(create: (_) => UpgradeService()),
        StreamProvider<UserModel?>.value(
          value: AuthService().user,
          initialData: null,
        ),
        ProxyProvider<UserModel?, FirestoreService>(
          update: (_, user, __) => FirestoreService(uid: user?.uid),
        ),
        ChangeNotifierProxyProvider<FirestoreService, QuizViewModel>(
          create: (context) => QuizViewModel(
            firestoreService: Provider.of<FirestoreService>(context, listen: false),
            userId: Provider.of<UserModel?>(context, listen: false)?.uid,
          ),
          update: (_, firestoreService, previousQuizViewModel) =>
              previousQuizViewModel!..updateFirestoreService(firestoreService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SumQuiz',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
