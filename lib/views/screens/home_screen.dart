import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/views/screens/summary_screen.dart';
import 'package:myapp/views/screens/quiz_screen.dart';
import 'package:myapp/views/screens/flashcards_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Tools',
              style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildToolCard(
                    context,
                    'Summary',
                    Icons.article,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SummaryScreen()),
                      );
                    },
                  ),
                  _buildToolCard(
                    context,
                    'Quiz',
                    Icons.quiz,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QuizScreen()),
                      );
                    },
                  ),
                  _buildToolCard(
                    context,
                    'Flashcards',
                    Icons.style,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FlashcardsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
