import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'dart:developer' as developer;

import '../../models/user_model.dart';
import '../../services/spaced_repetition_service.dart';
import '../../models/spaced_repetition_item.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  ProgressScreenState createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
  late SpacedRepetitionService _spacedRepetitionService;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _dailyStats = {};
  List<Map<String, dynamic>> _weeklyStats = [];
  Map<String, dynamic> _spacedRepetitionStats = {};

  @override
  void initState() {
    super.initState();
    final box = Hive.box<SpacedRepetitionItem>('spaced_repetition');
    _spacedRepetitionService = SpacedRepetitionService(box);
    _loadStats();
  }

  Future<void> _loadStats() async {
    // Load stats for the current user
    // This would typically involve querying Firestore for user activity data
    setState(() {
      // Mock data for demonstration
      _dailyStats = {
        'summaries': 3,
        'quizzes': 2,
        'flashcards': 5,
        'quizScore': 85.5,
      };
      
      _weeklyStats = [
        {'date': DateTime.now().subtract(const Duration(days: 6)), 'count': 5},
        {'date': DateTime.now().subtract(const Duration(days: 5)), 'count': 7},
        {'date': DateTime.now().subtract(const Duration(days: 4)), 'count': 3},
        {'date': DateTime.now().subtract(const Duration(days: 3)), 'count': 8},
        {'date': DateTime.now().subtract(const Duration(days: 2)), 'count': 6},
        {'date': DateTime.now().subtract(const Duration(days: 1)), 'count': 4},
        {'date': DateTime.now(), 'count': 9},
      ];
    });
    
    _loadSpacedRepetitionStats();
  }

  Future<void> _loadSpacedRepetitionStats() async {
    try {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        final stats = await _spacedRepetitionService.getStatistics(user.uid);
        setState(() {
          _spacedRepetitionStats = stats;
        });
      }
    } catch (e, s) {
      developer.log('Error loading spaced repetition stats: $e', name: 'my_app.progress', error: e, stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel?>(context);

    return userModel == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 20),
                  _buildDailyStatsCard(),
                  const SizedBox(height: 20),
                  _buildSpacedRepetitionStatsCard(),
                  const SizedBox(height: 20),
                  _buildWeeklyChart(),
                  const SizedBox(height: 20),
                  _buildAchievementsSection(),
                ],
              ),
            ),
          );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
          },
        ),
        Text(
          DateFormat('MMMM dd, yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            if (_selectedDate.isBefore(DateTime.now())) {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDailyStatsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.article, 'Summaries', _dailyStats['summaries']?.toString() ?? '0'),
                _buildStatItem(Icons.quiz, 'Quizzes', _dailyStats['quizzes']?.toString() ?? '0'),
                _buildStatItem(Icons.style, 'Flashcards', _dailyStats['flashcards']?.toString() ?? '0'),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuizScoreBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSpacedRepetitionStatsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spaced Repetition',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.school, 
                  'Total Cards', 
                  _spacedRepetitionStats['totalCards']?.toString() ?? '0'
                ),
                _buildStatItem(
                  Icons.access_time, 
                  'Due Now', 
                  _spacedRepetitionStats['dueCards']?.toString() ?? '0'
                ),
                _buildStatItem(
                  Icons.check, 
                  'Reviewed Today', 
                  _spacedRepetitionStats['reviewedToday']?.toString() ?? '0'
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to spaced repetition screen
                Navigator.pushNamed(context, '/spaced_repetition');
              },
              child: const Text('Start Review Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizScoreBar() {
    final score = _dailyStats['quizScore'] ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quiz Performance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            score >= 80
                ? Colors.green
                : score >= 60
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text('${score.toStringAsFixed(1)}% average score'),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_weeklyStats[group.x.toInt()]['count']} items',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _weeklyStats.length) {
                            final date = _weeklyStats[index]['date'] as DateTime;
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                DateFormat('E').format(date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: _weeklyStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: stat['count'].toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.zero,
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildAchievementCard(
                    Icons.auto_stories,
                    'First Summary',
                    'Created your first summary',
                    true,
                  ),
                  const SizedBox(width: 16),
                  _buildAchievementCard(
                    Icons.quiz,
                    'Quiz Master',
                    'Completed 10 quizzes',
                    false,
                  ),
                  const SizedBox(width: 16),
                  _buildAchievementCard(
                    Icons.style,
                    'Flashcard Pro',
                    'Created 50 flashcards',
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(IconData icon, String title, String description, bool unlocked) {
    return Card(
      color: unlocked ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[300],
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: unlocked ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: unlocked ? Colors.black : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: unlocked ? Colors.grey[700] : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
