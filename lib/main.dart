import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/local_database_service.dart';
import 'package:myapp/models/user_model.dart';
import 'firebase_options.dart';
import 'package:myapp/services/ai_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/view_models/quiz_view_model.dart';
import 'package:myapp/services/upgrade_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:myapp/router/app_router.dart';
import 'package:myapp/providers/navigation_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/services/usage_service.dart';
import 'package:myapp/services/referral_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalDatabaseService().init();

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  }

  // Instantiate AuthService before runApp
  final authService = AuthService(FirebaseAuth.instance);

  runApp(MyApp(authService: authService));
}

class MyApp extends StatefulWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SubscriptionService? _subscriptionService;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes and initialize SubscriptionService
    widget.authService.user.listen((user) {
      if (user != null) {
        if (_subscriptionService == null) {
          _subscriptionService = SubscriptionService();
          _subscriptionService!.initialize(user.uid);
        }
      } else {
        // Clean up when user logs out
        _subscriptionService?.dispose();
        _subscriptionService = null;
      }
    });
  }

  @override
  void dispose() {
    _subscriptionService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        // Use Provider.value to expose the pre-instantiated AuthService
        Provider<AuthService>.value(value: widget.authService),
        Provider<AIService>(create: (_) => AIService()),
        Provider<UpgradeService>(create: (_) => UpgradeService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<LocalDatabaseService>(create: (_) => LocalDatabaseService()),
        ProxyProvider<AuthService, SubscriptionService?>(
          update: (context, authService, previous) {
            final user = authService.currentUser;
            if (user != null) {
              // Return existing service or create new one
              if (previous != null) {
                return previous;
              }
              final service = SubscriptionService();
              service.initialize(user.uid);
              return service;
            }
            // Dispose previous service when user logs out
            previous?.dispose();
            return null;
          },
          dispose: (_, service) => service?.dispose(),
        ),
        ProxyProvider<AuthService, UsageService?>(
          update: (context, authService, previous) {
            final user = authService.currentUser;
            if (user != null) {
              return UsageService(user.uid);
            }
            return null;
          },
        ),
        ProxyProvider<AuthService, ReferralService?>(
          update: (context, authService, previous) {
            final user = authService.currentUser;
            if (user != null) {
              return ReferralService(user.uid);
            }
            return null;
          },
        ),
        StreamProvider<UserModel?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
        ChangeNotifierProxyProvider<AuthService, QuizViewModel>(
          create: (context) => QuizViewModel(
            LocalDatabaseService(),
            context.read<AuthService>(),
          ),
          update: (_, authService, previous) {
            // Reuse existing QuizViewModel if available
            if (previous != null) {
              return previous;
            }
            return QuizViewModel(LocalDatabaseService(), authService);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final router = createAppRouter(widget.authService);
          return MaterialApp.router(
            title: 'SumQuiz',
            theme: themeProvider.getTheme(),
            darkTheme: themeProvider.getTheme(),
            themeMode: themeProvider.themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
            ],
          );
        },
      ),
    );
  }
}