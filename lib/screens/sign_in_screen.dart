import 'package:flutter/material.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            AuthService(FirebaseAuth.instance).signInWithGoogle();
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
