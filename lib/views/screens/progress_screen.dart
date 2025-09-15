import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../widgets/upgrade_modal.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: Center(
        child: userModel == null
            ? const CircularProgressIndicator()
            : userModel.isPro
                ? const Text('Pro Content')
                : _buildUpgradeCard(context),
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upgrade to Pro to track your progress!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const UpgradeModal(),
                );
              },
              child: const Text('Upgrade Now'),
            ),
          ],
        ),
      ),
    );
  }
}
