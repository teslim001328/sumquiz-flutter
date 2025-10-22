import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/editable_content.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/views/screens/auth_screen.dart';
import 'package:myapp/views/screens/main_screen.dart';
import 'package:myapp/views/screens/settings_screen.dart';
import 'package:myapp/views/screens/spaced_repetition_screen.dart';
import 'package:myapp/views/screens/summary_screen.dart';
import 'package:myapp/views/screens/quiz_screen.dart';
import 'package:myapp/views/screens/flashcards_screen.dart';
import 'package:myapp/views/screens/edit_content_screen.dart';
import 'package:myapp/views/screens/account_screen.dart';
import 'package:myapp/views/screens/preferences_screen.dart';
import 'package:myapp/views/screens/data_storage_screen.dart';
import 'package:myapp/views/screens/subscription_screen.dart';
import 'package:myapp/views/screens/privacy_about_screen.dart';

// GoRouterRefreshStream class
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

GoRouter createAppRouter(AuthService authService) {
  return GoRouter(
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
        path: '/account',
        builder: (context, state) => const AccountScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'preferences',
                builder: (context, state) => const PreferencesScreen(),
              ),
              GoRoute(
                path: 'data-storage',
                builder: (context, state) => const DataStorageScreen(),
              ),
              GoRoute(
                path: 'subscription',
                builder: (context, state) => const SubscriptionScreen(),
              ),
              GoRoute(
                path: 'privacy-about',
                builder: (context, state) => const PrivacyAboutScreen(),
              ),
            ],
          ),
        ],
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
        builder: (context, state) =>
            EditContentScreen(content: state.extra! as EditableContent),
      ),
    ],
  );
}
