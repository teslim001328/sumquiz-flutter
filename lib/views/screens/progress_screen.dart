import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService _progressService = ProgressService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final firebaseUser = Provider.of<User?>(context);

    if (user == null || firebaseUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: user.subscriptionStatus == 'Pro'
          ? _buildProContent(context, firebaseUser.uid)
          : _buildFreeContent(context),
    );
  }

  Widget _buildFreeContent(BuildContext context) {
    return Stack(
      children: [
        _buildProContent(context, '', blurred: true),
        Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Upgrade to Pro',
                      style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unlock detailed analytics and track your progress by upgrading to a Pro account.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to subscription page
                      },
                      child: const Text('Upgrade Now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProContent(BuildContext context, String userId, {bool blurred = false}) {
    return FutureBuilder(
        future: Future.wait([
          _progressService.getSummariesCount(userId),
          _progressService.getQuizzesCount(userId),
          _progressService.getFlashcardsCount(userId),
          _progressService.getWeeklyActivity(userId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final summariesCount = snapshot.data![0] as int;
          final quizzesCount = snapshot.data![1] as int;
          final flashcardsCount = snapshot.data![2] as int;
          final weeklyActivity = snapshot.data![3] as List<FlSpot>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Progress',
                  style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your learning activity and achievements',
                  style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                _buildMetricCards(summariesCount, quizzesCount, flashcardsCount),
                const SizedBox(height: 24),
                _buildWeeklyActivityChart(weeklyActivity),
                const SizedBox(height: 24),
                _buildContentDistributionChart(
                    summariesCount, quizzesCount, flashcardsCount),
              ],
            ),
          );
        });
  }

  Widget _buildMetricCards(int summariesCount, int quizzesCount, int flashcardsCount) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard('Summaries', summariesCount.toString(), Icons.article),
        _buildMetricCard('Quizzes', quizzesCount.toString(), Icons.quiz),
        _buildMetricCard('Flashcards', flashcardsCount.toString(), Icons.style),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.deepPurple),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityChart(List<FlSpot> weeklyActivity) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyActivity,
                      isCurved: true,
                      color: Colors.deepPurple,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentDistributionChart(
      int summariesCount, int quizzesCount, int flashcardsCount) {
    final total = summariesCount + quizzesCount + flashcardsCount;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Distribution',
              style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.deepPurple[400],
                      value: (summariesCount / total) * 100,
                      title: 'Summaries',
                      radius: 80,
                      titleStyle: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      color: Colors.deepPurple[200],
                      value: (quizzesCount / total) * 100,
                      title: 'Quizzes',
                      radius: 80,
                      titleStyle: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      color: Colors.deepPurple[100],
                      value: (flashcardsCount / total) * 100,
                      title: 'Flashcards',
                      radius: 80,
                      titleStyle: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
