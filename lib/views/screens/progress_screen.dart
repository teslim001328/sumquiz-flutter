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

  @override
  void initState() {
    super.initState();
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      _statsFuture = _loadStats(user.uid);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<User?>(context);
    // If the user logs in or out, reload the stats.
    if (_statsFuture == null && user != null) {
      setState(() {
        _statsFuture = _loadStats(user.uid);
      });
    } else if (user == null && _statsFuture != null) {
      setState(() {
        _statsFuture = null;
      });
    }
  }

  Future<Map<String, dynamic>> _loadStats(String userId) async {
    try {
      final dbService = LocalDatabaseService();
      await dbService.init(); // Ensure initialized
      final srsService = SpacedRepetitionService(dbService.getSpacedRepetitionBox());
      final firestoreService = FirestoreService();

      // Fetch all data in parallel
      final srsStatsFuture = srsService.getStatistics(userId);
      final firestoreStatsFuture = firestoreService.streamAllItems(userId).first;

      final results = await Future.wait([srsStatsFuture, firestoreStatsFuture]);
      final srsStats = results[0];
      final firestoreStats = results[1] as Map<String, List<dynamic>>;

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
      // Rethrow the error to be caught by the FutureBuilder
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const Center(child: Text('Please log in to view your progress.', style: TextStyle(color: Colors.white)));
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
            developer.log('FutureBuilder error', name: 'ProgressScreen', error: snapshot.error, stackTrace: snapshot.stackTrace);
            return _buildErrorState(user.uid, snapshot.error!);
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(user.uid);
          }

          final stats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _statsFuture = _loadStats(user.uid);
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
                  _buildReviewBanner(stats['dueForReviewCount'] as int? ?? 0),
                  const SizedBox(height: 24),
                  _buildUpcomingReviews(stats['upcomingReviews'] as List<MapEntry<DateTime, int>>? ?? []),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String userId, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Something went wrong.', style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Could not load your progress. Please try again later.', style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Details: ${error.toString()}', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => setState(() => _statsFuture = _loadStats(userId)), child: const Text('Retry'))
          ],
        ),
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
          children: [
            Expanded(child: _buildMetricChip('Summaries', (stats['summariesCount'] ?? 0).toString())),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricChip('Quizzes', (stats['quizzesCount'] ?? 0).toString())),
          ],
        ),
        const SizedBox(height: 10),
        _buildMetricChip('Flashcards', (stats['flashcardsCount'] ?? 0).toString(), isFullWidth: true),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, {bool isFullWidth = false}) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.oswald(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 14)),
          ],
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
          image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/genie-a0445.appspot.com/o/images%2Freview_banner.png?alt=media&token=8f3955e8-1269-482d-9793-1fe2a27b134b'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [const Color.fromRGBO(0, 0, 0, 0.7), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dueCount items', style: GoogleFonts.oswald(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                Text('Due for review today', style: GoogleFonts.roboto(color: Colors.white.withAlpha(230), fontSize: 16)),
              ],
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
            Text('in the next 7 days', style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 16)),
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
                  barRods: [
                    BarChartRodData(
                      toY: count.toDouble(),
                      color: const Color(0xFF6EE7B7),
                      width: 22,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
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
                      final now = DateTime.now();
                      final day = now.add(Duration(days: value.toInt()));
                      return Text(DateFormat.E().format(day), style: TextStyle(color: Colors.grey[500], fontSize: 12));
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<MapEntry<int, int>> _prepareWeeklyData(List<MapEntry<DateTime, int>> upcomingReviews) {
    final weeklyMap = { for (var i = 0; i < 7; i++) i: 0 };
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    for (var review in upcomingReviews) {
      final reviewDate = review.key;
      final startOfReviewDay = DateTime(reviewDate.year, reviewDate.month, reviewDate.day);
      final dayIndex = startOfReviewDay.difference(startOfToday).inDays;

      if (dayIndex >= 0 && dayIndex < 7) {
        weeklyMap.update(dayIndex, (value) => value + review.value, ifAbsent: () => review.value);
      }
    }
    return weeklyMap.entries.toList();
  }

  Widget _buildEmptyState(String userId) {
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
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => setState(() => _statsFuture = _loadStats(userId)), child: const Text('Refresh'))
        ],
      ),
    );
  }
}
