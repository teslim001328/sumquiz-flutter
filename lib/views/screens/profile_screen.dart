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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.iconTheme.color),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildWideLayout(context, user, quizViewModel, authService, theme);
          } else {
            return _buildNarrowLayout(context, user, quizViewModel, authService, theme);
          }
        },
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, UserModel user, QuizViewModel quizViewModel, AuthService authService, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _buildProfileAvatar(user, theme),
          const SizedBox(height: 16),
          Text(user.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(user.email, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          _buildSubscriptionChip(user, theme),
          const SizedBox(height: 32),
          _buildStatsSection(quizViewModel, theme),
          const SizedBox(height: 32),
          if (user.subscriptionStatus != 'Pro') ...[
            _buildUpgradeCard(context, theme),
            const SizedBox(height: 32),
          ],
          _buildLogOutButton(context, authService, theme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, UserModel user, QuizViewModel quizViewModel, AuthService authService, ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildProfileAvatar(user, theme, radius: 60),
                    const SizedBox(height: 20),
                    Text(user.name, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(user.email, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _buildSubscriptionChip(user, theme),
                    const SizedBox(height: 30),
                     _buildLogOutButton(context, authService, theme),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildStatsSection(quizViewModel, theme),
                    const SizedBox(height: 32),
                    if (user.subscriptionStatus != 'Pro')
                      _buildUpgradeCard(context, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProfileAvatar(UserModel user, ThemeData theme, {double radius = 50}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.secondaryContainer,
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
        style: GoogleFonts.poppins(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildSubscriptionChip(UserModel user, ThemeData theme) {
    bool isPro = user.subscriptionStatus == 'Pro';
    return Chip(
      label: Text(isPro ? 'Pro User' : 'Free Plan',
          style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
      backgroundColor: theme.colorScheme.secondaryContainer,
      avatar: isPro ? Icon(Icons.star, color: theme.colorScheme.onSecondaryContainer) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildStatsSection(QuizViewModel quizViewModel, ThemeData theme) {
    final quizzesTaken = quizViewModel.quizzes.length;
    final averageScore = quizViewModel.averageScore;
    final bestScore = quizViewModel.bestScore;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.dividerColor)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Quizzes', quizzesTaken.toString(), theme),
          _buildStatCard('Avg Score', '${averageScore.toStringAsFixed(1)}%', theme),
          _buildStatCard('Best Score', '${bestScore.toStringAsFixed(1)}%', theme),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildUpgradeCard(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const UpgradeModal(),
          ),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: theme.colorScheme.onPrimary, size: 40),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upgrade to Pro',
                          style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Unlock all features and get unlimited access',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onPrimary.withAlpha(200))),
                    ],
                  ),
                ),
                 const SizedBox(width: 20),
                Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onPrimary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogOutButton(
      BuildContext context, AuthService authService, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.logout, color: theme.colorScheme.error),
        label: Text('Log Out', style: TextStyle(color: theme.colorScheme.error)),
        onPressed: () async {
          await authService.signOut();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
