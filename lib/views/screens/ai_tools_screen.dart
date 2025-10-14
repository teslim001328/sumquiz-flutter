import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AiToolsScreen extends StatelessWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('AI Tools',
                  style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.grey[900]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildFeatureCard(
                    context,
                    icon: Icons.flash_on,
                    title: 'Generate Summary',
                    subtitle:
                        'Summarize any text, article, or document instantly.',
                    color: const Color(0xFF1E3A8A), // A deep blue shade
                    onTap: () => context.push('/summary'),
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    icon: Icons.filter_none,
                    title: 'Flashcards',
                    subtitle:
                        'Create flashcards from any content to aid your learning.',
                    color: const Color(0xFF6EE7B7), // A mint green shade
                    onTap: () => context.push('/flashcards'),
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    icon: Icons.question_answer,
                    title: 'Generate Quiz',
                    subtitle:
                        'Create a quiz from any content to test your knowledge.',
                    color: const Color(0xFFC026D3), // A fuchsia shade
                    onTap: () => context.push('/quiz'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: GoogleFonts.roboto(
                    fontSize: 16, color: Colors.white70, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
