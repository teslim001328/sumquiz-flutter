import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/view_models/quiz_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = Provider.of<UserModel?>(context);
    final quizViewModel = Provider.of<QuizViewModel>(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final quizzesTaken = quizViewModel.quizzes.length;
    final averageScore = quizViewModel.averageScore;
    final bestScore = quizViewModel.bestScore;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: GoogleFonts.poppins(
                    fontSize: 40, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Chip(
                label: Text(
                  user.subscriptionStatus == 'Pro' ? 'Pro User' : 'Free Plan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 32),
              const Divider(color: Color(0xFFE0E0E0)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Quizzes Taken', quizzesTaken.toString()),
                  _buildStatCard('Average Score', '${averageScore.toStringAsFixed(1)}%'),
                  _buildStatCard('Best Score', '${bestScore.toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE0E0E0)),
              const Spacer(),
              if (user.subscriptionStatus != 'Pro')
                Column(
                  children: [
                    Text(
                      'Upgrade your plan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Handle upgrade logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        'Upgrade to Pro',
                        style: GoogleFonts.poppins(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock unlimited quizzes and summaries.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              TextButton(
                onPressed: () => authService.signOut(),
                child: Text(
                  'Log Out',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
