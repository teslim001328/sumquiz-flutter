import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/upgrade_service.dart';
import 'services/local_database_service.dart';
import 'views/screens/auth_wrapper.dart';
import 'models/user_model.dart';
import 'views/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await LocalDatabaseService().init();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  final authService = AuthService(FirebaseAuth.instance);

  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        // The new StreamProvider that provides the UserModel directly.
        StreamProvider<UserModel?>(
          create: (context) => context.read<AuthService>().user,
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
          return MaterialApp(
            title: 'SumQuiz',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
