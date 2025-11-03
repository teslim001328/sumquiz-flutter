import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../view_models/quiz_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for changes in QuizViewModel and rebuild the widget
    Provider.of<QuizViewModel>(context, listen: false).addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);
    final quizViewModel = Provider.of<QuizViewModel>(context);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface), // Use theme color
            onPressed: () => context.go('/account/settings'), // Corrected navigation
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildProfileAvatar(context, user),
                const SizedBox(height: 20),
                Text(
                  user.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildSubscriptionChip(context, user),
                const SizedBox(height: 40),
                _buildStatsSection(context, quizViewModel),
                const SizedBox(height: 40),
                if (!user.isPro) ...[
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

  Widget _buildProfileAvatar(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 50,
      backgroundColor: theme.colorScheme.primaryContainer, // Use theme color
      child: Text(
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
        style: GoogleFonts.poppins(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer, // Use theme color
        ),
      ),
    );
  }

  Widget _buildSubscriptionChip(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    bool isPro = user.isPro;
    return Chip(
      label: Text(
        isPro ? 'Pro User' : 'Free Plan',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: isPro ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer,
        ),
      ),
      backgroundColor: isPro ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer,
      avatar: isPro ? Icon(Icons.star, color: theme.colorScheme.onPrimary, size: 18) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildStatsSection(BuildContext context, QuizViewModel quizViewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(context, 'Quizzes', quizViewModel.quizzes.length.toString()),
        _buildStatCard(context, 'Avg Score', '${quizViewModel.averageScore.toStringAsFixed(1)}%'),
        _buildStatCard(context, 'Best Score', '${quizViewModel.bestScore.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to upgrade/pricing page or show upgrade dialog
          // You can implement this based on your app's structure
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upgrade feature coming soon!'),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary, // Use theme color
          foregroundColor: theme.colorScheme.onPrimary, // Use theme color
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
    final theme = Theme.of(context);
    return TextButton(
      onPressed: () async {
        await authService.signOut();
      },
      child: Text(
        'Log Out',
        style: GoogleFonts.poppins(
          color: theme.colorScheme.error, // Use theme color
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}