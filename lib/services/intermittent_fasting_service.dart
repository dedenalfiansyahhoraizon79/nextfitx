import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/intermittent_fasting_model.dart';
import 'dart:math';

class IntermittentFastingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new fasting session
  Future<String> createFasting(FastingModel fasting) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final docRef =
          await _firestore.collection('fasting_records').add(fasting.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating fasting record: $e');
      rethrow;
    }
  }

  // Get all fasting records for current user
  Future<List<FastingModel>> getFastingRecords({int? limit}) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      Query query = _firestore
          .collection('fasting_records')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) =>
              FastingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting fasting records: $e');
      return [];
    }
  }

  // Get fasting record for a specific date
  Future<FastingModel?> getFastingForDate(DateTime date) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('fasting_records')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return FastingModel.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      print('Error getting fasting for date: $e');
      return null;
    }
  }

  // Get fasting records for a date range
  Future<List<FastingModel>> getFastingForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('fasting_records')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              FastingModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting fasting for date range: $e');
      return [];
    }
  }

  // Update an existing fasting record
  Future<void> updateFasting(FastingModel fasting) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (fasting.id == null) {
        throw Exception('Fasting ID is required for update');
      }

      final updatedFasting = fasting.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('fasting_records')
          .doc(fasting.id)
          .update(updatedFasting.toMap());
    } catch (e) {
      print('Error updating fasting record: $e');
      rethrow;
    }
  }

  // Delete a fasting record
  Future<void> deleteFasting(String fastingId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('fasting_records').doc(fastingId).delete();
    } catch (e) {
      print('Error deleting fasting record: $e');
      rethrow;
    }
  }

  // Start a new fasting session
  Future<FastingModel> startFasting({
    required FastingType fastingType,
    required DateTime startTime,
    int? customDurationHours,
    String? notes,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if there's already an active fasting
      final activeFasting = await getActiveFasting();
      if (activeFasting != null) {
        throw Exception('You already have an active fasting session');
      }

      final targetHours = customDurationHours ?? fastingType.fastHours;

      final fasting = FastingModel(
        userId: currentUserId!,
        date: DateTime(startTime.year, startTime.month, startTime.day),
        fastingType: fastingType,
        startTime: startTime,
        targetDurationHours: targetHours,
        status: FastingStatus.active,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final fastingId = await createFasting(fasting);
      return fasting.copyWith(id: fastingId);
    } catch (e) {
      print('Error starting fasting: $e');
      rethrow;
    }
  }

  // End current active fasting
  Future<FastingModel?> endFasting({
    required String fastingId,
    FastingStatus status = FastingStatus.completed,
    String? notes,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get the current fasting record
      final doc =
          await _firestore.collection('fasting_records').doc(fastingId).get();
      if (!doc.exists) {
        throw Exception('Fasting record not found');
      }

      final fasting = FastingModel.fromMap(doc.data()!, doc.id);

      final endTime = DateTime.now();
      final actualDuration = endTime.difference(fasting.startTime).inMinutes;

      final updatedFasting = fasting.copyWith(
        endTime: endTime,
        actualDurationMinutes: actualDuration,
        status: status,
        notes: notes ?? fasting.notes,
        updatedAt: DateTime.now(),
      );

      await updateFasting(updatedFasting);
      return updatedFasting;
    } catch (e) {
      print('Error ending fasting: $e');
      rethrow;
    }
  }

  // Get current active fasting
  Future<FastingModel?> getActiveFasting() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('fasting_records')
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'active')
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return FastingModel.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      print('Error getting active fasting: $e');
      return null;
    }
  }

  // Pause current active fasting
  Future<void> pauseFasting(String fastingId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final doc =
          await _firestore.collection('fasting_records').doc(fastingId).get();
      if (!doc.exists) {
        throw Exception('Fasting record not found');
      }

      final fasting = FastingModel.fromMap(doc.data()!, doc.id);

      final updatedFasting = fasting.copyWith(
        status: FastingStatus.paused,
        updatedAt: DateTime.now(),
      );

      await updateFasting(updatedFasting);
    } catch (e) {
      print('Error pausing fasting: $e');
      rethrow;
    }
  }

  // Resume paused fasting
  Future<void> resumeFasting(String fastingId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final doc =
          await _firestore.collection('fasting_records').doc(fastingId).get();
      if (!doc.exists) {
        throw Exception('Fasting record not found');
      }

      final fasting = FastingModel.fromMap(doc.data()!, doc.id);

      final updatedFasting = fasting.copyWith(
        status: FastingStatus.active,
        updatedAt: DateTime.now(),
      );

      await updateFasting(updatedFasting);
    } catch (e) {
      print('Error resuming fasting: $e');
      rethrow;
    }
  }

  // Get chart data for a date range
  Future<List<FastingChartData>> getChartData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final fastingRecords = await getFastingForDateRange(startDate, endDate);

      return fastingRecords
          .map((fasting) => FastingChartData(
                date: fasting.date,
                durationHours: fasting.currentDurationHours,
                fastingType: fasting.fastingType,
                status: fasting.status,
                targetHours: fasting.targetDurationHours.toDouble(),
              ))
          .toList();
    } catch (e) {
      print('Error getting chart data: $e');
      return [];
    }
  }

  // Get fasting summary for a date range
  Future<FastingSummary> getFastingSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final fastingRecords = await getFastingForDateRange(startDate, endDate);

      if (fastingRecords.isEmpty) {
        return FastingSummary(
          totalFasts: 0,
          completedFasts: 0,
          activeFasts: 0,
          brokenFasts: 0,
          averageDurationHours: 0.0,
          totalFastingHours: 0.0,
          completionRate: 0.0,
          currentStreak: 0,
          longestStreak: 0,
          fastingTypeCount: {},
          averageTargetHours: 0.0,
        );
      }

      // Calculate statistics
      int completedCount = 0;
      int activeCount = 0;
      int brokenCount = 0;
      double totalHours = 0;
      double totalTargetHours = 0;
      Map<FastingType, int> typeCount = {};

      for (final fasting in fastingRecords) {
        switch (fasting.status) {
          case FastingStatus.completed:
            completedCount++;
            break;
          case FastingStatus.active:
            activeCount++;
            break;
          case FastingStatus.broken:
            brokenCount++;
            break;
          case FastingStatus.paused:
            // Count paused as active for statistics
            activeCount++;
            break;
        }

        totalHours += fasting.currentDurationHours;
        totalTargetHours += fasting.targetDurationHours;

        typeCount[fasting.fastingType] =
            (typeCount[fasting.fastingType] ?? 0) + 1;
      }

      final totalCount = fastingRecords.length;
      final averageDuration = totalHours / totalCount;
      final averageTarget = totalTargetHours / totalCount;
      final completionRate = completedCount / totalCount * 100;

      // Calculate streaks
      final currentStreak = await _calculateCurrentStreak();
      final longestStreak = await _calculateLongestStreak();

      return FastingSummary(
        totalFasts: totalCount,
        completedFasts: completedCount,
        activeFasts: activeCount,
        brokenFasts: brokenCount,
        averageDurationHours: double.parse(averageDuration.toStringAsFixed(2)),
        totalFastingHours: double.parse(totalHours.toStringAsFixed(1)),
        completionRate: double.parse(completionRate.toStringAsFixed(1)),
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        fastingTypeCount: typeCount,
        averageTargetHours: double.parse(averageTarget.toStringAsFixed(1)),
      );
    } catch (e) {
      print('Error getting fasting summary: $e');
      return FastingSummary(
        totalFasts: 0,
        completedFasts: 0,
        activeFasts: 0,
        brokenFasts: 0,
        averageDurationHours: 0.0,
        totalFastingHours: 0.0,
        completionRate: 0.0,
        currentStreak: 0,
        longestStreak: 0,
        fastingTypeCount: {},
        averageTargetHours: 0.0,
      );
    }
  }

  // Calculate current fasting streak
  Future<int> _calculateCurrentStreak() async {
    try {
      final endDate = DateTime.now();
      final startDate =
          endDate.subtract(const Duration(days: 90)); // Check last 90 days
      final fastingRecords = await getFastingForDateRange(startDate, endDate);

      if (fastingRecords.isEmpty) return 0;

      // Sort by date (most recent first)
      fastingRecords.sort((a, b) => b.date.compareTo(a.date));

      int streak = 0;
      for (final fasting in fastingRecords) {
        if (fasting.status == FastingStatus.completed) {
          streak++;
        } else if (fasting.status == FastingStatus.broken) {
          break; // Streak broken
        }
        // Continue counting if active or paused
      }

      return streak;
    } catch (e) {
      print('Error calculating current streak: $e');
      return 0;
    }
  }

  // Calculate longest fasting streak
  Future<int> _calculateLongestStreak() async {
    try {
      final endDate = DateTime.now();
      final startDate =
          endDate.subtract(const Duration(days: 365)); // Check last year
      final fastingRecords = await getFastingForDateRange(startDate, endDate);

      if (fastingRecords.isEmpty) return 0;

      // Sort by date (oldest first)
      fastingRecords.sort((a, b) => a.date.compareTo(b.date));

      int longestStreak = 0;
      int currentStreak = 0;

      for (final fasting in fastingRecords) {
        if (fasting.status == FastingStatus.completed) {
          currentStreak++;
          longestStreak = max(longestStreak, currentStreak);
        } else if (fasting.status == FastingStatus.broken) {
          currentStreak = 0; // Reset streak
        }
        // Continue streak if active or paused
      }

      return longestStreak;
    } catch (e) {
      print('Error calculating longest streak: $e');
      return 0;
    }
  }

  // Get weekly chart data (7 days)
  Future<List<FastingChartData>> getWeeklyChartData() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6));
    return getChartData(startDate: startDate, endDate: endDate);
  }

  // Get monthly chart data (30 days)
  Future<List<FastingChartData>> getMonthlyChartData() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 29));
    return getChartData(startDate: startDate, endDate: endDate);
  }

  // Get today's fasting
  Future<FastingModel?> getTodayFasting() async {
    return getFastingForDate(DateTime.now());
  }

  // Search fasting records by notes
  Future<List<FastingModel>> searchFastingByNotes(String query) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('fasting_records')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true)
          .get();

      final allFasting = querySnapshot.docs
          .map((doc) =>
              FastingModel.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by notes locally (Firestore doesn't support text search easily)
      return allFasting
          .where((fasting) =>
              fasting.notes != null &&
              fasting.notes!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching fasting records: $e');
      return [];
    }
  }

  // Get fasting records stream for real-time updates
  Stream<List<FastingModel>> getFastingRecordsStream({int? limit}) {
    if (currentUserId == null) {
      print('getFastingRecordsStream: User not authenticated');
      return Stream.value([]);
    }

    try {
      // Try simple query first to avoid potential index issues
      Query query = _firestore
          .collection('fasting_records')
          .where('userId', isEqualTo: currentUserId);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        print(
            'Fasting records fetched: ${snapshot.docs.length} records for user: $currentUserId');

        final records = snapshot.docs
            .map((doc) {
              try {
                final fasting = FastingModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
                print(
                    'Parsed fasting record: ${fasting.date} - ${fasting.fastingType.displayName}');
                return fasting;
              } catch (e) {
                print('Error parsing fasting record ${doc.id}: $e');
                print('Document data: ${doc.data()}');
                return null;
              }
            })
            .where((fasting) => fasting != null)
            .cast<FastingModel>()
            .toList();

        // Sort manually by date descending
        records.sort((a, b) => b.date.compareTo(a.date));

        return records;
      });
    } catch (e) {
      print('Error in getFastingRecordsStream: $e');
      return Stream.value([]);
    }
  }

  // Generate sample fasting data for testing
  Future<void> generateSampleFastingData() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final sampleData = <FastingModel>[];

      // Generate 14 days of sample fasting data
      for (int i = 1; i <= 14; i++) {
        final date = now.subtract(Duration(days: i));

        // Generate varied fasting types
        final types = [
          FastingType.sixteen_eight,
          FastingType.eighteen_six,
          FastingType.twenty_four,
        ];
        final fastingType = types[i % types.length];

        // Generate realistic start times (evening)
        final startHour = 18 + (i % 4); // 18:00 - 21:00
        final startMinute = (i * 10) % 60; // Varied minutes
        final startTime =
            DateTime(date.year, date.month, date.day, startHour, startMinute);

        // Calculate end time based on fasting type
        final targetMinutes = fastingType.fastHours * 60;
        final endTime = startTime.add(Duration(minutes: targetMinutes));

        // Calculate actual duration (sometimes slightly different)
        final variance = (i % 3 - 1) * 30; // -30, 0, +30 minutes variance
        final actualDuration = targetMinutes + variance;

        // Generate varied status (mostly completed)
        final status =
            i % 5 == 0 ? FastingStatus.broken : FastingStatus.completed;

        // Generate sample notes
        final notes = _generateSampleFastingNotes(fastingType, status, i);

        final fastingRecord = FastingModel(
          userId: currentUserId!,
          date: DateTime(date.year, date.month, date.day),
          fastingType: fastingType,
          startTime: startTime,
          endTime: endTime,
          targetDurationHours: fastingType.fastHours,
          actualDurationMinutes: actualDuration,
          status: status,
          notes: notes,
          createdAt: now.subtract(Duration(days: i)),
          updatedAt: now.subtract(Duration(days: i)),
        );

        sampleData.add(fastingRecord);
      }

      // Add sample data to Firestore
      final batch = _firestore.batch();
      for (final fasting in sampleData) {
        final docRef = _firestore.collection('fasting_records').doc();
        batch.set(docRef, fasting.toMap());
      }

      await batch.commit();
      print(
          'Successfully generated ${sampleData.length} sample fasting records');
    } catch (e) {
      print('Error generating sample fasting data: $e');
      rethrow;
    }
  }

  String _generateSampleFastingNotes(
      FastingType type, FastingStatus status, int dayIndex) {
    final completedNotes = [
      'Completed successfully! Felt energized',
      'Great fasting session, no cravings',
      'Smooth fast, broke with healthy meal',
      'Felt focused and clear-minded',
      'Easy fast, body is adapting well',
    ];

    final brokenNotes = [
      'Had to break early due to social event',
      'Felt too hungry, broke with light snack',
      'Work stress led to early break',
      'Couldn\'t sleep well, broke in morning',
      'Listened to body signals and stopped',
    ];

    final typeSpecificNotes = {
      FastingType.sixteen_eight: ' - 16:8 is my sweet spot',
      FastingType.eighteen_six: ' - 18:6 was challenging but rewarding',
      FastingType.twenty_four: ' - 24h fast completed!',
    };

    final baseNote = status == FastingStatus.completed
        ? completedNotes[dayIndex % completedNotes.length]
        : brokenNotes[dayIndex % brokenNotes.length];

    return baseNote + (typeSpecificNotes[type] ?? '');
  }

  // Check if user has any fasting records
  Future<bool> hasAnyFastingRecords() async {
    try {
      if (currentUserId == null) return false;

      final querySnapshot = await _firestore
          .collection('fasting_records')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking fasting records: $e');
      return false;
    }
  }

  // Debug method to check Firestore connection and data
  Future<Map<String, dynamic>> debugFastingRecords() async {
    try {
      if (currentUserId == null) {
        return {'error': 'User not authenticated'};
      }

      // Check if collection exists and has data
      final allRecords =
          await _firestore.collection('fasting_records').limit(5).get();

      final userRecords = await _firestore
          .collection('fasting_records')
          .where('userId', isEqualTo: currentUserId)
          .limit(5)
          .get();

      // Test data creation
      final hasAnyRecords = await hasAnyFastingRecords();

      return {
        'status': 'Fasting Records Debug Info',
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
                  'type': doc.data()['type'],
                  'status': doc.data()['status'],
                  'targetDurationMinutes': doc.data()['targetDurationMinutes'],
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

  // Get active fasting stream for real-time timer updates
  Stream<FastingModel?> getActiveFastingStream() {
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('fasting_records')
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .orderBy('startTime', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return FastingModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  // Check if fasting record exists for a date
  Future<bool> hasFastingForDate(DateTime date) async {
    final fasting = await getFastingForDate(date);
    return fasting != null;
  }

  // Get fasting completion rate for a period
  Future<double> getCompletionRate({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));
      final fastingRecords = await getFastingForDateRange(startDate, endDate);

      if (fastingRecords.isEmpty) return 0.0;

      final completedCount = fastingRecords
          .where((fasting) => fasting.status == FastingStatus.completed)
          .length;

      return (completedCount / fastingRecords.length * 100);
    } catch (e) {
      print('Error calculating completion rate: $e');
      return 0.0;
    }
  }

  // Get average fasting duration for a period
  Future<double> getAverageFastingDuration({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));
      final fastingRecords = await getFastingForDateRange(startDate, endDate);

      if (fastingRecords.isEmpty) return 0.0;

      final totalHours = fastingRecords
          .map((fasting) => fasting.currentDurationHours)
          .reduce((a, b) => a + b);

      return totalHours / fastingRecords.length;
    } catch (e) {
      print('Error calculating average duration: $e');
      return 0.0;
    }
  }

  // Get fasting insights based on recent data
  Future<Map<String, String>> getFastingInsights() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      final summary =
          await getFastingSummary(startDate: startDate, endDate: endDate);

      Map<String, String> insights = {};

      // Completion rate insight
      if (summary.completionRate >= 80) {
        insights['completion'] =
            'Excellent! You\'re consistently completing your fasts.';
      } else if (summary.completionRate >= 60) {
        insights['completion'] =
            'Good progress! Try to maintain consistency for better results.';
      } else if (summary.completionRate >= 40) {
        insights['completion'] =
            'You\'re getting there! Consider shorter fasts to build the habit.';
      } else {
        insights['completion'] =
            'Start with easier fasting schedules like 16:8 to build consistency.';
      }

      // Duration insight
      if (summary.averageDurationHours >= 18) {
        insights['duration'] =
            'Great job on extended fasting! Make sure to stay hydrated.';
      } else if (summary.averageDurationHours >= 16) {
        insights['duration'] =
            'Perfect! You\'re in the sweet spot for intermittent fasting.';
      } else if (summary.averageDurationHours >= 12) {
        insights['duration'] =
            'Good start! Try gradually increasing your fasting window.';
      } else {
        insights['duration'] =
            'Consider extending your fasting window for better benefits.';
      }

      // Streak insight
      if (summary.currentStreak >= 7) {
        insights['streak'] =
            'Amazing streak! You\'re building a strong fasting habit.';
      } else if (summary.currentStreak >= 3) {
        insights['streak'] = 'Nice streak going! Keep up the momentum.';
      } else {
        insights['streak'] =
            'Focus on building consistency to create a strong fasting habit.';
      }

      return insights;
    } catch (e) {
      print('Error getting fasting insights: $e');
      return {};
    }
  }
}
