import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<User?>(context);

    return Scaffold(
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<UserModel>(
              stream: firestoreService.streamUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('User data not found.'));
                }

                final userModel = snapshot.data!;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfoCard(context, userModel, authService),
                      const SizedBox(height: 24),
                      _buildUsageCard(context, userModel, firestoreService),
                      const SizedBox(height: 24),
                      _buildSubscriptionCard(context, userModel),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, UserModel user, AuthService authService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authService.signOut(),
              tooltip: 'Logout',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(BuildContext context, UserModel user, FirestoreService firestore) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Usage',
              style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildUsageRow('Summaries', user.dailyUsage['summaries'] ?? 0, 3, firestore.canGenerate('summaries', user)),
            const Divider(height: 24),
            _buildUsageRow('Quizzes', user.dailyUsage['quizzes'] ?? 0, 2, firestore.canGenerate('quizzes', user)),
            const Divider(height: 24),
            _buildUsageRow('Flashcards', user.dailyUsage['flashcards'] ?? 0, 2, firestore.canGenerate('flashcards', user)),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String title, int count, int limit, bool canGenerate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.openSans(fontSize: 16)),
        Text('$count / $limit', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500)),
        Icon(
          canGenerate ? Icons.check_circle_outline : Icons.highlight_off,
          color: canGenerate ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription',
              style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(user.subscriptionStatus, style: GoogleFonts.openSans(fontSize: 16)),
                if (user.subscriptionStatus != 'Pro')
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement upgrade functionality
                    },
                    child: const Text('Upgrade to Pro'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
