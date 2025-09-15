
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:provider/provider.dart';

// Entry point for the authentication screen
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // App Title
              Text(
                'SumQuiz',
                textAlign: TextAlign.center,
                style: GoogleFonts.oswald(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome! Please sign in to continue.',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // Google Sign-In Button
              _GoogleSignInButton(),
              const SizedBox(height: 20),
              // Divider
              const Row(
                children: [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('OR', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),
              // Email/Password Form
              _EmailForm(),
            ],
          ),
        ),
      ),
    );
  }
}

// Google Sign-In button widget
class _GoogleSignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return ElevatedButton.icon(
      icon: const Icon(Icons.g_mobiledata, size: 28), // Placeholder for Google Icon
      label: const Text('Sign in with Google'),
      onPressed: () async {
        final user = await authService.signInWithGoogle();
        if (user == null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Google Sign-In Failed. Please try again.')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, // Text color
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.grey), // Border
        ),
      ),
    );
  }
}

// Email/Password form widget
class _EmailForm extends StatefulWidget {
  @override
  _EmailFormState createState() => _EmailFormState();
}

class _EmailFormState extends State<_EmailForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true; // Determines if the form is for login or signup
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _trySubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus(); // Close keyboard

    if (isValid) {
      _formKey.currentState?.save();
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      setState(() => _isLoading = true);

      try {
        if (_isLogin) {
          await authService.signInWithEmailAndPassword(_email, _password);
        } else {
          await authService.createUserWithEmailAndPassword(_email, _password);
        }
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Authentication Failed: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Email field
          TextFormField(
            key: const ValueKey('email'),
            validator: (value) => !value!.contains('@') ? 'Invalid email' : null,
            onSaved: (value) => _email = value!,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Password field
          TextFormField(
            key: const ValueKey('password'),
            validator: (value) => value!.length < 6 ? 'Password is too short' : null,
            onSaved: (value) => _password = value!,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          // Submit button
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _trySubmit,
              child: Text(_isLogin ? 'Login' : 'Sign Up'),
            ),
          const SizedBox(height: 12),
          // Toggle between login and signup
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(_isLogin
                ? 'Create a new account'
                : 'I already have an account'),
          ),
        ],
      ),
    );
  }
}
