import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpgradeDialog extends StatelessWidget {
  final String featureName;

  const UpgradeDialog({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upgrade to Pro to use $featureName'),
      content: const Text('You have reached your daily limit for this feature. Upgrade to Pro for unlimited access.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/account/settings/subscription');
          },
          child: const Text('Upgrade'),
        ),
      ],
    );
  }
}
