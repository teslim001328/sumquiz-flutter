import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Your saved summaries, quizzes, and flashcards will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
