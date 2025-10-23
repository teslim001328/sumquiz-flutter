import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Subscription',
          style: theme.textTheme.headlineSmall,
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildPlanCard(theme, user),
                const SizedBox(height: 24),
                _buildPricingTable(theme),
                const SizedBox(height: 32),
                _buildUpgradeButton(theme),
                const SizedBox(height: 16),
                _buildRestoreButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(ThemeData theme, UserModel? user) {
    return Card(
      color: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Current Plan', style: theme.textTheme.titleLarge),
            Text(user?.subscriptionStatus ?? 'Free', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingTable(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Feature', style: theme.textTheme.bodyMedium),
                Text('Free', style: theme.textTheme.bodyMedium),
                Text('Pro', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            _buildFeatureRow('AI Summaries', '3/day', 'Unlimited', theme),
            _buildFeatureRow('Quiz Generation', '3/day', 'Unlimited', theme),
            _buildFeatureRow('Flashcards', 'Limited', 'Unlimited', theme),
            _buildFeatureRow('Save to Library', '10 items', 'Unlimited', theme),
            _buildFeatureRow('Offline Mode', '3 items', 'Full library', theme),
            _buildFeatureRow('PDF Uploads', '1 trial', 'Unlimited', theme),
            _buildFeatureRow('Study Progress Tracking', '❌', '✅', theme),
          ],
        ),
      ),
    );
  }

  static Widget _buildFeatureRow(String feature, String freeValue, String proValue, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(feature, style: theme.textTheme.bodyMedium),
          Text(freeValue, style: theme.textTheme.bodyMedium),
          Text(proValue, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(width: 8),
          Icon(Icons.star, color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(color: theme.colorScheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
      child: const Text('Restore Purchases'),
    );
  }
}
