import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'upgrade_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel?>(context);
    final user = Provider.of<User?>(context);

    if (userModel == null || user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (userModel.subscriptionStatus != 'Pro')
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Upgrade to Pro and unlock all features!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                          },
                          child: const Text('Upgrade Now'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person, size: 50) : null,
              ),
              const SizedBox(height: 20),
              Text(userModel.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(userModel.email, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Chip(
                label: Text(userModel.subscriptionStatus == 'Pro' ? 'Pro Member' : 'Free Member'),
                backgroundColor: userModel.subscriptionStatus == 'Pro' ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              const Text('Daily Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Summaries'),
                trailing: Text('${userModel.dailyUsage['summaries'] ?? 0} / 5'),
              ),
              ListTile(
                leading: const Icon(Icons.quiz),
                title: const Text('Quizzes'),
                trailing: Text('${userModel.dailyUsage['quizzes'] ?? 0} / 3'),
              ),
              ListTile(
                leading: const Icon(Icons.style),
                title: const Text('Flashcards'),
                trailing: Text('${userModel.dailyUsage['flashcards'] ?? 0} / 3'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
