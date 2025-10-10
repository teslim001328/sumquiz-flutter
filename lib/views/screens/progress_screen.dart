import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/firestore_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Future<Map<String, dynamic>>? _statsFuture;
  User? _user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<User?>(context);
    if (user != _user) {
      setState(() {
        _user = user;
        if (user != null) {
          _statsFuture = _loadStats(user.uid);
        } else {
          _statsFuture = null;
        }
      });
    }
  }

  Future<Map<String, dynamic>> _loadStats(String userId) async {
    try {
      final dbService = LocalDatabaseService();
      await dbService.init();
      final srsService = SpacedRepetitionService(dbService.getSpacedRepetitionBox());
      final firestoreService = FirestoreService();

      final srsStats = await srsService.getStatistics(userId);
      final firestoreStats = await firestoreService.streamAllItems(userId).first;

      final summariesCount = firestoreStats['summaries']?.length ?? 0;
      final quizzesCount = firestoreStats['quizzes']?.length ?? 0;
      final flashcardsCount = firestoreStats['flashcards']?.length ?? 0;

      final result = {
        ...srsStats,
        'summariesCount': summariesCount,
        'quizzesCount': quizzesCount,
        'flashcardsCount': flashcardsCount,
      };
      developer.log('Stats loaded successfully: $result', name: 'ProgressScreen');
      return result;
    } catch (e, s) {
      developer.log('Error loading stats', name: 'ProgressScreen', error: e, stackTrace: s);
      return {}; // Return empty map on error to avoid breaking the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text('Please log in to view your progress.', style: TextStyle(color: Colors.white)));
    }
    
    if (_statsFuture == null) {
        return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Progress', style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
          }
          if (snapshot.hasError) {
            developer.log('FutureBuilder error', name: 'ProgressScreen', error: snapshot.error);
            return _buildEmptyState();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final stats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _statsFuture = _loadStats(_user!.uid);
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopMetrics(stats),
                  const SizedBox(height: 24),
                  _buildReviewBanner(stats['dueForReviewCount'] ?? 0),
                  const SizedBox(height: 24),
                  _buildUpcomingReviews(stats['upcomingReviews'] ?? []),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopMetrics(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Metrics', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetricChip('Total Summaries', (stats['summariesCount'] ?? 0).toString()),
            const SizedBox(width: 10),
            _buildMetricChip('Total Quizzes', (stats['quizzesCount'] ?? 0).toString()),
          ],
        ),
        const SizedBox(height: 10),
        _buildMetricChip('Total Flashcards', (stats['flashcardsCount'] ?? 0).toString(), isFullWidth: true),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, {bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('$label: $value', style: GoogleFonts.roboto(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildReviewBanner(int dueCount) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: const DecorationImage(
          image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/genie-a0445.appspot.com/o/images%2Freview_banner.png?alt=media&token=1a2a3b4b-5c6d-7e8f-9a0b-1c2d3e4f5a6b'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '$dueCount items due for review',
              style: GoogleFonts.oswald(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingReviews(List<MapEntry<DateTime, int>> upcomingReviews) {
    final weeklyData = _prepareWeeklyData(upcomingReviews);
    final totalUpcoming = upcomingReviews.fold<int>(0, (sum, item) => sum + item.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Reviews', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(totalUpcoming.toString(), style: GoogleFonts.oswald(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Text('Next 7 Days', style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 16)),
            const SizedBox(width: 8),
            const Text('+10%', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)), // Placeholder for percentage
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: weeklyData.map((data) {
                final day = data.key;
                final count = data.value;
                return BarChartGroupData(
                  x: day,
                  barRods: [BarChartRodData(toY: count.toDouble(), color: Colors.grey[700], width: 20, borderRadius: const BorderRadius.all(Radius.circular(4)))],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final day = DateFormat.E().format(DateTime.now().add(Duration(days: value.toInt())));
                      return SideTitleWidget(axisSide: meta.axisSide, child: Text(day, style: TextStyle(color: Colors.grey[400], fontSize: 12)));
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
  
  List<MapEntry<int, int>> _prepareWeeklyData(List<MapEntry<DateTime, int>> upcomingReviews) {
    final today = DateTime.now();
    final weeklyData = List.generate(7, (i) => MapEntry(i, 0));

    for (var review in upcomingReviews) {
      final dayIndex = review.key.difference(today).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        weeklyData[dayIndex] = MapEntry(dayIndex, weeklyData[dayIndex].value + review.value);
      }
    }
    return weeklyData;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.leaderboard_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No Progress Data Yet', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Complete some quizzes or flashcard reviews to see your progress here.',
              style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
