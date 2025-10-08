import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/views/screens/auth_screen.dart';
import 'package:myapp/views/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen for the UserModel? from the StreamProvider in main.dart
    final userModel = Provider.of<UserModel?>(context);

    // If the userModel is null, it means the user is not logged in
    // or their data is still loading.
    if (userModel == null) {
      // You might want to show a loading spinner while auth state is being determined
      // For now, we'll just show the AuthScreen.
      return const AuthScreen();
    } else {
      // If we have a userModel, the user is fully logged in and their
      // data is available. Proceed to the HomeScreen.
      return const HomeScreen();
    }
  }
}
