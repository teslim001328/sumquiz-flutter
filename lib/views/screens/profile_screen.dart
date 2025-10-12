import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../widgets/upgrade_modal.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel?>(context);
    final user = Provider.of<User?>(context);

    if (userModel == null || user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : const NetworkImage('https://firebasestorage.googleapis.com/v0/b/genie-a0445.appspot.com/o/images%2Fprofile_placeholder.png?alt=media&token=27192865-1d43-409d-837c-f2b1c4a1b835'),
              ),
              const SizedBox(height: 20),
              Text(userModel.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(userModel.email, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
              const SizedBox(height: 30),
              if (userModel.subscriptionStatus != 'Pro') ...[
                _buildUpgradeCard(context),
                const SizedBox(height: 30),
              ],
              _buildSectionTitle('Daily Usage'),
              const SizedBox(height: 10),
              _buildUsageTile(Icons.description_outlined, 'Summaries Generated', '${userModel.dailyUsage['summaries'] ?? 0}', '5'),
              _buildUsageTile(Icons.quiz_outlined, 'Quizzes Created', '${userModel.dailyUsage['quizzes'] ?? 0}', '3'),
              _buildUsageTile(Icons.style_outlined, 'Flashcards Created', '${userModel.dailyUsage['flashcards'] ?? 0}', '3'),
              const SizedBox(height: 30),
              _buildSectionTitle('Quick Stats'),
              const SizedBox(height: 10),
              _buildStatsTile(Icons.local_fire_department_outlined, '3-day Streak'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Free Member', style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  const Text('Upgrade to Pro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Unlock unlimited summaries, quizzes, and flashcards.', style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (context) => const UpgradeModal(),
                      isScrollControlled: true,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Upgrade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Image.network(
              'https://firebasestorage.googleapis.com/v0/b/genie-a0445.appspot.com/o/images%2Fpro_card_image.png?alt=media&token=8a4c8a9f-3e1a-4f2a-9428-accabf49c2d1',
              width: 80,
              height: 80,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildUsageTile(IconData icon, String title, String count, String limit) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: Text('$count / $limit', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
    );
  }

  Widget _buildStatsTile(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.orange, size: 24),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}
