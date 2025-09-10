import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Analytics coming soon. Upgrade to Pro to see progress.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
