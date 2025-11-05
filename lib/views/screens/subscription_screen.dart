import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../services/subscription_service.dart';
import '../../models/user_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlanId = 'sumquiz_annual';
  late StreamSubscription<PurchaseResult> _purchaseResultSubscription;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final subscriptionService = context.read<SubscriptionService>();

    _purchaseResultSubscription = subscriptionService.purchaseResultStream.listen((result) {
      if (!mounted) return;

      setState(() => _errorMessage = null);

      switch (result.state) {
        case PurchaseState.success:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase successful!')),
          );
          subscriptionService.resetPurchaseState();
          break;
        case PurchaseState.restored:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your previous purchase has been restored.')),
          );
          subscriptionService.resetPurchaseState();
          break;
        case PurchaseState.error:
          setState(() {
            _errorMessage = result.errorMessage ?? 'An unknown error occurred. Please try again.';
          });
          break;
        case PurchaseState.canceled:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase canceled.')),
          );
          subscriptionService.resetPurchaseState();
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _purchaseResultSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserModel?>();
    final subscriptionService = context.watch<SubscriptionService>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<PurchaseResult>(
        stream: subscriptionService.purchaseResultStream,
        initialData: PurchaseResult(PurchaseState.idle),
        builder: (context, snapshot) {
          final isPurchasing = snapshot.data?.state == PurchaseState.purchasing;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildFeatureList(theme),
                      const SizedBox(height: 32),
                      _buildPlanSelector(theme),
                      const SizedBox(height: 32),
                      if (_errorMessage != null) _buildErrorMessage(theme),
                      _buildCtaButton(theme, user, isPurchasing, subscriptionService),
                      const SizedBox(height: 16),
                      _buildRestorePurchaseLink(theme, subscriptionService),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(top: 100, bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primary.withAlpha(102),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_outlined, size: 60, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(height: 16),
          Text(
            'Go Pro',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock all features and study without limits.',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem(theme, 'Unlimited quizzes & flashcards'),
        _buildFeatureItem(theme, 'AI-powered question generation'),
        _buildFeatureItem(theme, 'Advanced progress tracking'),
        _buildFeatureItem(theme, 'Ad-free experience'),
      ],
    );
  }

  Widget _buildFeatureItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 22, color: Colors.green.shade500),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(ThemeData theme) {
    return Column(
      children: [
        _buildPlanCard(
          theme: theme,
          title: 'Monthly',
          price: '\$3.99',
          billingCycle: '/month',
          planId: 'sumquiz_monthly',
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          theme: theme,
          title: 'Annual',
          price: '\$29.99',
          billingCycle: '/year',
          isBestValue: true,
          planId: 'sumquiz_annual',
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          theme: theme,
          title: 'Lifetime',
          price: '\$69.99',
          billingCycle: ' one-time',
          planId: 'sumquiz_lifetime',
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required ThemeData theme,
    required String title,
    required String price,
    required String billingCycle,
    required String planId,
    bool isBestValue = false,
  }) {
    final isSelected = _selectedPlanId == planId;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = planId),
      child: Card(
        color: isSelected ? theme.colorScheme.primary.withAlpha(26) : theme.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBestValue)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'BEST VALUE',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(price, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(billingCycle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.colorScheme.error.withAlpha(128), width: 1),
      ),
      child: Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCtaButton(ThemeData theme, UserModel? user, bool isPurchasing, SubscriptionService subscriptionService) {
    return ElevatedButton(
      onPressed: (user?.isPro ?? false) || isPurchasing
          ? null
          : () {
              subscriptionService.resetPurchaseState();
              subscriptionService.purchasePlan(_selectedPlanId);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: theme.colorScheme.secondary.withAlpha(128),
      ),
      child: isPurchasing
          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
          : Text(
              user?.isPro ?? false ? 'You are already a Pro Member' : 'Upgrade to Pro',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildRestorePurchaseLink(ThemeData theme, SubscriptionService subscriptionService) {
    return TextButton(
      onPressed: () => subscriptionService.restorePurchases(),
      child: Text(
        'Restore Purchases',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}
