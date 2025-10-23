import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../view_models/quiz_view_model.dart';
import '../screens/settings_screen.dart';
import '../widgets/upgrade_modal.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);
    final quizViewModel = Provider.of<QuizViewModel>(context);
    final theme = Theme.of(context);

    if (user == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // White background as per blueprint
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins( // Poppins font
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500), // Constrained width for responsive center column
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildProfileAvatar(user),
                const SizedBox(height: 20),
                Text(
                  user.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                _buildSubscriptionChip(user),
                const SizedBox(height: 40),
                _buildStatsSection(quizViewModel),
                const SizedBox(height: 40),
                if (user.subscriptionStatus != 'Pro') ...[
                  _buildUpgradeButton(context),
                  const SizedBox(height: 24),
                ],
                _buildLogOutButton(context, authService),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel user) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey[200], // Light gray background for avatar
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
        style: GoogleFonts.poppins(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSubscriptionChip(UserModel user) {
    bool isPro = user.subscriptionStatus == 'Pro';
    return Chip(
      label: Text(
        isPro ? 'Pro User' : 'Free Plan',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: isPro ? Colors.white : Colors.black,
        ),
      ),
      backgroundColor: isPro ? Colors.black : Colors.grey[200],
      avatar: isPro ? const Icon(Icons.star, color: Colors.white, size: 18) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildStatsSection(QuizViewModel quizViewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard('Quizzes', quizViewModel.quizzes.length.toString()),
        _buildStatCard('Avg Score', '${quizViewModel.averageScore.toStringAsFixed(1)}%'),
        _buildStatCard('Best Score', '${quizViewModel.bestScore.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const UpgradeModal(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // Black background for prominent button
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Upgrade to Pro',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLogOutButton(BuildContext context, AuthService authService) {
    return TextButton(
      onPressed: () async {
        await authService.signOut();
      },
      child: Text(
        'Log Out',
        style: GoogleFonts.poppins(
          color: Colors.red[700], // Simple text button for logout
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
