import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sleep_model.dart';
import 'dart:math';

class SleepService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new sleep record
  Future<String> createSleep(SleepModel sleep) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final docRef =
          await _firestore.collection('sleep_records').add(sleep.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating sleep record: $e');
      rethrow;
    }
  }

  // Get all sleep records for current user
  Future<List<SleepModel>> getSleepRecords({int? limit}) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      Query query = _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) =>
              SleepModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting sleep records: $e');
      return [];
    }
  }

  // Get sleep record for a specific date
  Future<SleepModel?> getSleepForDate(DateTime date) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return SleepModel.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      print('Error getting sleep for date: $e');
      return null;
    }
  }

  // Get sleep records for a date range
  Future<List<SleepModel>> getSleepForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SleepModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting sleep for date range: $e');
      return [];
    }
  }

  // Wrapper method for getSleepForDateRange (for compatibility)
  Future<List<SleepModel>> getSleepRecordsByDateRange(
      DateTime startDate, DateTime endDate) async {
    return await getSleepForDateRange(startDate, endDate);
  }

  // Update an existing sleep record
  Future<void> updateSleep(SleepModel sleep) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (sleep.id == null) {
        throw Exception('Sleep ID is required for update');
      }

      final updatedSleep = sleep.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('sleep_records')
          .doc(sleep.id)
          .update(updatedSleep.toMap());
    } catch (e) {
      print('Error updating sleep record: $e');
      rethrow;
    }
  }

  // Delete a sleep record
  Future<void> deleteSleep(String sleepId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('sleep_records').doc(sleepId).delete();
    } catch (e) {
      print('Error deleting sleep record: $e');
      rethrow;
    }
  }

  // Create sleep record with automatic duration calculation
  Future<SleepModel> createSleepWithCalculation({
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
    int? quality,
    String? notes,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate duration
      final duration = SleepCalculator.calculateDuration(
        bedtime: bedtime,
        wakeTime: wakeTime,
      );

      // Auto-suggest quality based on duration if not provided
      final autoQuality =
          quality ?? SleepCalculator.getQualityFromDuration(duration);

      final sleep = SleepModel(
        userId: currentUserId!,
        date: date,
        bedtime: bedtime,
        wakeTime: wakeTime,
        durationMinutes: duration,
        quality: autoQuality,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final sleepId = await createSleep(sleep);
      return sleep.copyWith(id: sleepId);
    } catch (e) {
      print('Error creating sleep with calculation: $e');
      rethrow;
    }
  }

  // Get chart data for a date range
  Future<List<SleepChartData>> getChartData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final sleepRecords = await getSleepForDateRange(startDate, endDate);

      return sleepRecords
          .map((sleep) => SleepChartData(
                date: sleep.date,
                durationHours: sleep.durationHours,
                quality: sleep.quality,
                bedtime: sleep.bedtime,
                wakeTime: sleep.wakeTime,
              ))
          .toList();
    } catch (e) {
      print('Error getting chart data: $e');
      return [];
    }
  }

  // Get sleep summary for a date range
  Future<SleepSummary> getSleepSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final sleepRecords = await getSleepForDateRange(startDate, endDate);

      if (sleepRecords.isEmpty) {
        return SleepSummary(
          totalNights: 0,
          averageDurationHours: 0.0,
          totalSleepHours: 0.0,
          averageQuality: 0.0,
          bestQuality: 0,
          worstQuality: 0,
          averageBedtimeHour: 0.0,
          averageWakeTimeHour: 0.0,
          daysWithHealthySleep: 0,
          sleepConsistency: 0.0,
        );
      }

      // Calculate totals and averages
      double totalHours = 0;
      double totalQuality = 0;
      int bestQuality = sleepRecords.first.quality;
      int worstQuality = sleepRecords.first.quality;
      double totalBedtimeHour = 0;
      double totalWakeTimeHour = 0;
      int healthySleepCount = 0;
      List<double> bedtimes = [];

      for (final sleep in sleepRecords) {
        totalHours += sleep.durationHours;
        totalQuality += sleep.quality;

        if (sleep.quality > bestQuality) bestQuality = sleep.quality;
        if (sleep.quality < worstQuality) worstQuality = sleep.quality;

        final bedtimeHour = sleep.bedtime.hour + (sleep.bedtime.minute / 60.0);
        final wakeTimeHour =
            sleep.wakeTime.hour + (sleep.wakeTime.minute / 60.0);

        totalBedtimeHour += bedtimeHour;
        totalWakeTimeHour += wakeTimeHour;
        bedtimes.add(bedtimeHour);

        if (SleepCalculator.isHealthyDuration(sleep.durationMinutes)) {
          healthySleepCount++;
        }
      }

      final count = sleepRecords.length;
      final averageDuration = totalHours / count;
      final averageQuality = totalQuality / count;
      final averageBedtime = totalBedtimeHour / count;
      final averageWakeTime = totalWakeTimeHour / count;

      // Calculate sleep consistency (standard deviation of bedtimes)
      double consistency = 0.0;
      if (bedtimes.length > 1) {
        final mean = bedtimes.reduce((a, b) => a + b) / bedtimes.length;
        final variance = bedtimes
                .map((bedtime) => pow(bedtime - mean, 2))
                .reduce((a, b) => a + b) /
            bedtimes.length;
        consistency = sqrt(variance);
      }

      return SleepSummary(
        totalNights: count,
        averageDurationHours: double.parse(averageDuration.toStringAsFixed(2)),
        totalSleepHours: double.parse(totalHours.toStringAsFixed(1)),
        averageQuality: double.parse(averageQuality.toStringAsFixed(1)),
        bestQuality: bestQuality,
        worstQuality: worstQuality,
        averageBedtimeHour: double.parse(averageBedtime.toStringAsFixed(2)),
        averageWakeTimeHour: double.parse(averageWakeTime.toStringAsFixed(2)),
        daysWithHealthySleep: healthySleepCount,
        sleepConsistency: double.parse(consistency.toStringAsFixed(2)),
      );
    } catch (e) {
      print('Error getting sleep summary: $e');
      return SleepSummary(
        totalNights: 0,
        averageDurationHours: 0.0,
        totalSleepHours: 0.0,
        averageQuality: 0.0,
        bestQuality: 0,
        worstQuality: 0,
        averageBedtimeHour: 0.0,
        averageWakeTimeHour: 0.0,
        daysWithHealthySleep: 0,
        sleepConsistency: 0.0,
      );
    }
  }

  // Get weekly chart data (7 days)
  Future<List<SleepChartData>> getWeeklyChartData() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6));
    return getChartData(startDate: startDate, endDate: endDate);
  }

  // Get monthly chart data (30 days)
  Future<List<SleepChartData>> getMonthlyChartData() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 29));
    return getChartData(startDate: startDate, endDate: endDate);
  }

  // Get today's sleep
  Future<SleepModel?> getTodaySleep() async {
    return getSleepForDate(DateTime.now());
  }

  // Get most recent sleep record (fallback method)
  Future<SleepModel?> getRecentSleep() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return SleepModel.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      print('Error getting recent sleep: $e');
      return null;
    }
  }

  // Get last night's sleep (for morning review) - Enhanced version
  Future<SleepModel?> getLastNightSleepEnhanced() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Try multiple approaches to find sleep data
      final now = DateTime.now();

      // Approach 1: Look for yesterday's date
      final yesterday = now.subtract(const Duration(days: 1));
      var sleep = await getSleepForDate(yesterday);
      if (sleep != null) {
        print('Found sleep for yesterday: ${sleep.durationHours}h');
        return sleep;
      }

      // Approach 2: Look for today's date (in case user input today for last night)
      sleep = await getSleepForDate(now);
      if (sleep != null) {
        print('Found sleep for today: ${sleep.durationHours}h');
        return sleep;
      }

      // Approach 3: Look for last 3 days
      for (int i = 2; i <= 3; i++) {
        final checkDate = now.subtract(Duration(days: i));
        sleep = await getSleepForDate(checkDate);
        if (sleep != null) {
          print('Found sleep for $i days ago: ${sleep.durationHours}h');
          return sleep;
        }
      }

      // Approach 4: Get most recent sleep record regardless of date
      sleep = await getRecentSleep();
      if (sleep != null) {
        print(
            'Found most recent sleep: ${sleep.durationHours}h on ${sleep.date}');
        return sleep;
      }

      print('No sleep data found at all');
      return null;
    } catch (e) {
      print('Error in getLastNightSleepEnhanced: $e');
      return null;
    }
  }

  // Get last night's sleep (for morning review) - Original method
  Future<SleepModel?> getLastNightSleep() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getSleepForDate(yesterday);
  }

  // Search sleep records by notes
  Future<List<SleepModel>> searchSleepByNotes(String query) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true)
          .get();

      final allSleep = querySnapshot.docs
          .map((doc) =>
              SleepModel.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by notes locally (Firestore doesn't support text search easily)
      return allSleep
          .where((sleep) =>
              sleep.notes != null &&
              sleep.notes!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching sleep records: $e');
      return [];
    }
  }

  // Get sleep records stream for real-time updates
  Stream<List<SleepModel>> getSleepRecordsStream({int? limit}) {
    if (currentUserId == null) {
      print('getSleepRecordsStream: User not authenticated');
      return Stream.value([]);
    }

    try {
      // Try simple query first to avoid potential index issues
      Query query = _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: currentUserId);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        print(
            'Sleep records fetched: ${snapshot.docs.length} records for user: $currentUserId');

        final records = snapshot.docs
            .map((doc) {
              try {
                final sleep = SleepModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
                print(
                    'Parsed sleep record: ${sleep.date} - ${sleep.durationFormatted}');
                return sleep;
              } catch (e) {
                print('Error parsing sleep record ${doc.id}: $e');
                print('Document data: ${doc.data()}');
                return null;
              }
            })
            .where((sleep) => sleep != null)
            .cast<SleepModel>()
            .toList();

        // Sort manually by date descending
        records.sort((a, b) => b.date.compareTo(a.date));

        return records;
      });
    } catch (e) {
      print('Error in getSleepRecordsStream: $e');
      return Stream.value([]);
    }
  }

  // Generate sample sleep data for testing
  Future<void> generateSampleSleepData() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final sampleData = <SleepModel>[];

      // Generate 14 days of sample sleep data
      for (int i = 1; i <= 14; i++) {
        final date = now.subtract(Duration(days: i));

        // Generate realistic sleep times
        final bedtimeHour = 22 + (i % 3) - 1; // 21:00 - 23:00
        final bedtimeMinute = (i * 15) % 60; // Varied minutes
        final sleepDuration = 7.0 + (i % 3) * 0.5; // 7.0 - 8.0 hours
        final wakeTimeHour = (bedtimeHour + sleepDuration.round()) % 24;
        final wakeTimeMinute = bedtimeMinute;

        final bedtime = DateTime(
            date.year, date.month, date.day, bedtimeHour, bedtimeMinute);
        final wakeTime = DateTime(
            date.year,
            date.month,
            date.day + (wakeTimeHour < bedtimeHour ? 1 : 0),
            wakeTimeHour,
            wakeTimeMinute);

        // Calculate actual duration
        final duration = wakeTime.difference(bedtime);
        final durationMinutes = duration.inMinutes;

        // Generate varied quality (1-5)
        final quality = ((i % 5) + 1);

        // Generate sample notes
        final notes = _generateSampleNotes(quality, i);

        final sleepRecord = SleepModel(
          userId: currentUserId!,
          date: DateTime(date.year, date.month, date.day),
          bedtime: bedtime,
          wakeTime: wakeTime,
          durationMinutes: durationMinutes,
          quality: quality,
          notes: notes,
          createdAt: now.subtract(Duration(days: i)),
          updatedAt: now.subtract(Duration(days: i)),
        );

        sampleData.add(sleepRecord);
      }

      // Add sample data to Firestore
      final batch = _firestore.batch();
      for (final sleep in sampleData) {
        final docRef = _firestore.collection('sleep_records').doc();
        batch.set(docRef, sleep.toMap());
      }

      await batch.commit();
      print('Successfully generated ${sampleData.length} sample sleep records');
    } catch (e) {
      print('Error generating sample sleep data: $e');
      rethrow;
    }
  }

  String _generateSampleNotes(int quality, int dayIndex) {
    final goodNotes = [
      'Slept well, felt refreshed',
      'Great sleep quality',
      'Woke up naturally',
      'Deep and restful sleep',
      'Perfect temperature and comfort',
    ];

    final averageNotes = [
      'Average sleep, some interruptions',
      'Woke up once during the night',
      'Felt okay in the morning',
      'Normal sleep pattern',
      'Room was a bit noisy',
    ];

    final poorNotes = [
      'Restless night, multiple wake-ups',
      'Couldn\'t fall asleep easily',
      'Woke up tired',
      'Stressed about work',
      'Room too hot/cold',
    ];

    switch (quality) {
      case 4:
      case 5:
        return goodNotes[dayIndex % goodNotes.length];
      case 3:
        return averageNotes[dayIndex % averageNotes.length];
      case 1:
      case 2:
        return poorNotes[dayIndex % poorNotes.length];
      default:
        return 'No notes';
    }
  }

  // Check if user has any sleep records
  Future<bool> hasAnySleepRecords() async {
    try {
      if (currentUserId == null) return false;

      final querySnapshot = await _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking sleep records: $e');
      return false;
    }
  }

  // Debug method to check Firestore connection and data
  Future<Map<String, dynamic>> debugSleepRecords() async {
    try {
      if (currentUserId == null) {
        return {'error': 'User not authenticated'};
      }

      // Check if collection exists and has data
      final allRecords =
          await _firestore.collection('sleep_records').limit(5).get();

      final userRecords = await _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: currentUserId)
          .limit(5)
          .get();

      // Test data creation
      final hasAnyRecords = await hasAnySleepRecords();

      return {
        'status': 'Sleep Records Debug Info',
        'currentUserId': currentUserId,
        'totalRecordsInCollection': allRecords.docs.length,
        'userRecordsCount': userRecords.docs.length,
        'hasAnyUserRecords': hasAnyRecords,
        'troubleshooting': {
          'if_no_records': 'Use Generate Sample Data button',
          'if_auth_error': 'Check Firebase Authentication',
          'if_firestore_error': 'Check Firestore rules and indexes'
        },
        'sampleUserRecords': userRecords.docs
            .map((doc) => {
                  'id': doc.id,
                  'date': doc.data()['date']?.toString(),
                  'durationMinutes': doc.data()['durationMinutes'],
                  'quality': doc.data()['quality'],
                })
            .toList(),
      };
    } catch (e) {
      return {
        'error': 'Debug error: $e',
        'troubleshooting': {
          'firestore_rules': 'Check if Firestore rules allow read/write',
          'network': 'Check internet connection',
          'auth': 'Make sure user is authenticated',
        }
      };
    }
  }

  // Get sleep debt (difference from recommended 8 hours)
  Future<double> getSleepDebt({int days = 7}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));
      final sleepRecords = await getSleepForDateRange(startDate, endDate);

      const recommendedHours = 8.0;
      double totalDebt = 0.0;

      for (final sleep in sleepRecords) {
        final debt = recommendedHours - sleep.durationHours;
        if (debt > 0) {
          totalDebt += debt;
        }
      }

      return double.parse(totalDebt.toStringAsFixed(1));
    } catch (e) {
      print('Error calculating sleep debt: $e');
      return 0.0;
    }
  }

  // Get sleep streak (consecutive days with healthy sleep)
  Future<int> getSleepStreak() async {
    try {
      final endDate = DateTime.now();
      final startDate =
          endDate.subtract(const Duration(days: 30)); // Check last 30 days
      final sleepRecords = await getSleepForDateRange(startDate, endDate);

      if (sleepRecords.isEmpty) return 0;

      // Sort by date (most recent first)
      sleepRecords.sort((a, b) => b.date.compareTo(a.date));

      int streak = 0;
      for (final sleep in sleepRecords) {
        if (SleepCalculator.isHealthyDuration(sleep.durationMinutes)) {
          streak++;
        } else {
          break; // Streak broken
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating sleep streak: $e');
      return 0;
    }
  }

  // Check if sleep record exists for a date
  Future<bool> hasSleepForDate(DateTime date) async {
    final sleep = await getSleepForDate(date);
    return sleep != null;
  }

  // Get recommended bedtime based on wake time
  DateTime getRecommendedBedtime({
    required DateTime targetWakeTime,
    int targetSleepHours = 8,
  }) {
    return SleepCalculator.getRecommendedBedtime(
      targetWakeTime: targetWakeTime,
      targetSleepHours: targetSleepHours,
    );
  }

  // Get sleep insights based on recent data
  Future<Map<String, String>> getSleepInsights() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      final summary =
          await getSleepSummary(startDate: startDate, endDate: endDate);

      Map<String, String> insights = {};

      // Duration insight
      if (summary.averageDurationHours < 6.5) {
        insights['duration'] =
            'You\'re getting less sleep than recommended. Try to sleep 7-9 hours per night.';
      } else if (summary.averageDurationHours > 9.5) {
        insights['duration'] =
            'You might be sleeping too much. Consider adjusting your sleep schedule.';
      } else {
        insights['duration'] =
            'Great! You\'re getting a healthy amount of sleep.';
      }

      // Quality insight
      if (summary.averageQuality < 3) {
        insights['quality'] =
            'Your sleep quality could be improved. Consider your sleep environment and bedtime routine.';
      } else if (summary.averageQuality >= 4) {
        insights['quality'] = 'Excellent sleep quality! Keep up the good work.';
      } else {
        insights['quality'] =
            'Your sleep quality is decent, but there\'s room for improvement.';
      }

      // Consistency insight
      if (summary.sleepConsistency > 1.5) {
        insights['consistency'] =
            'Try to maintain a more consistent bedtime to improve your sleep quality.';
      } else {
        insights['consistency'] =
            'Good job maintaining a consistent sleep schedule!';
      }

      return insights;
    } catch (e) {
      print('Error getting sleep insights: $e');
      return {};
    }
  }
}
