import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiToolsScreen extends StatelessWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Create', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Choose what you want to generate today.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.flash_on,
                    title: 'Generate Summary',
                    subtitle: 'Summarize any text, article, or document instantly.',
                    color: const Color(0xFF1E3A8A), // A deep blue shade
                    onTap: () => context.go('/summary'),
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    icon: Icons.filter_none,
                    title: 'Flashcards',
                    subtitle: 'Create flashcards from any content to aid your learning.',
                    color: const Color(0xFF6EE7B7), // A mint green shade
                    onTap: () => context.go('/flashcards'),
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    icon: Icons.help_center,
                    title: 'Quizzes',
                    subtitle: 'Generate quizzes from any material to test your knowledge.',
                    color: const Color(0xFFA7F3D0), // A lighter mint shade
                    onTap: () => context.go('/quiz'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    {
      required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap,
    }
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
