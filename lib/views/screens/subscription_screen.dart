
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../services/subscription_service.dart';
import '../../services/referral_service.dart';
import '../../models/user_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlanId = 'sumquiz_annual'; // Default to the best value
  late StreamSubscription<PurchaseResult> _purchaseResultSubscription;
  String? _errorMessage; // NEW: To hold and display the error message on screen

  @override
  void initState() {
    super.initState();
    final subscriptionService =
        Provider.of<SubscriptionService>(context, listen: false);

    // NEW: Listen to the purchaseResultStream
    _purchaseResultSubscription =
        subscriptionService.purchaseResultStream.listen((result) {
      if (!mounted) return;

      setState(() {
        // Clear previous error messages on new state changes
        _errorMessage = null;
      });

      if (result.state == PurchaseState.success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase successful!')));
        subscriptionService.resetPurchaseState();
      } else if (result.state == PurchaseState.error) {
        // NEW: Set the error message to be displayed in the UI
        setState(() {
          _errorMessage = result.errorMessage ?? 'An unknown error occurred. Please try again.';
        });
        // The reset will be handled by the user trying again or leaving the screen
      } else if (result.state == PurchaseState.canceled) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Purchase canceled.')));
        subscriptionService.resetPurchaseState();
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
    final user = Provider.of<UserModel?>(context);
    final referralService = Provider.of<ReferralService?>(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SumQuiz Pro',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // NEW: Use StreamBuilder with PurchaseResult
      body: StreamBuilder<PurchaseResult>(
        stream: subscriptionService.purchaseResultStream,
        builder: (context, snapshot) {
          final isPurchasing = snapshot.data?.state == PurchaseState.purchasing;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFeatureList(),
                const SizedBox(height: 24),
                _buildPlanCard(
                  context,
                  title: 'Monthly',
                  price: '\$3.99',
                  billingCycle: '/month',
                  description: 'Billed monthly',
                  planId: 'sumquiz_monthly',
                ),
                const SizedBox(height: 16),
                _buildPlanCard(
                  context,
                  title: 'Annual',
                  price: '\$29.99',
                  billingCycle: '/year',
                  description: 'Billed annually',
                  isBestValue: true,
                  planId: 'sumquiz_annual',
                ),
                const SizedBox(height: 16),
                _buildPlanCard(
                  context,
                  title: 'Lifetime',
                  price: '\$69.99',
                  billingCycle: '',
                  description: 'One-time purchase',
                  planId: 'sumquiz_lifetime',
                ),
                const SizedBox(height: 32),

                // --- NEW: Error message display area ---
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: theme.colorScheme.error, width: 1)
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // --- End of new error message display ---

                ElevatedButton(
                  onPressed: (user?.isPro ?? false) || isPurchasing
                      ? null
                      : () {
                          // When user tries again, reset the state
                          subscriptionService.resetPurchaseState();
                          subscriptionService.purchasePlan(_selectedPlanId);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                        theme.colorScheme.secondary.withAlpha(128),
                  ),
                  child: isPurchasing
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          user?.isPro ?? false
                              ? 'You are a Pro Member'
                              : 'Upgrade to Pro',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                if (referralService != null)
                  StreamBuilder<int>(
                    stream: referralService.getReferralCount(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data! > 0) {
                        return Center(
                          child: Text(
                            'You have referred ${snapshot.data} friends! You have ${snapshot.data! * 7} days of Pro for free! 🎁',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(178),
                            ),
                          ),
                        );
                      } else {
                        return Center(
                          child: Text(
                            'Invite 3 friends and get 1 week of Pro free 🎁',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(178),
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unlock Your Full Potential',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem('Unlimited quizzes'),
        _buildFeatureItem('Advanced analytics'),
        _buildFeatureItem('Personalized learning'),
        _buildFeatureItem('Offline access'),
        _buildFeatureItem('Ad-free experience'),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: Colors.green.shade500),
          const SizedBox(width: 12),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String billingCycle,
    required String description,
    required String planId,
    bool isBestValue = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedPlanId == planId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanId = planId;
        });
      },
      child: Card(
        color:
            isSelected ? theme.colorScheme.primary.withAlpha(26) : theme.cardColor,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (isBestValue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Best Value ✨',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    billingCycle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurface.withAlpha(200)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
