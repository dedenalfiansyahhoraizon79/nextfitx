import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/water_intake_model.dart';

class WaterIntakeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new water intake record
  Future<String> addWaterIntake(WaterIntakeModel intake) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final docRef =
          await _firestore.collection('water_intakes').add(intake.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding water intake: $e');
      rethrow;
    }
  }

  // Quick add water with default type (plain water)
  Future<String> quickAddWater(int amountMl) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final intake = WaterIntakeModel(
        userId: currentUserId!,
        date: DateTime(now.year, now.month, now.day),
        amountMl: amountMl,
        waterType: WaterType.water,
        timestamp: now,
        createdAt: now,
      );

      return await addWaterIntake(intake);
    } catch (e) {
      print('Error quick adding water: $e');
      rethrow;
    }
  }

  // Get water intakes for a specific date
  Future<List<WaterIntakeModel>> getWaterIntakesForDate(DateTime date) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('water_intakes')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => WaterIntakeModel.fromMap(
              doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting water intakes for date: $e');
      return [];
    }
  }

  // Get water intakes for a date range
  Future<List<WaterIntakeModel>> getWaterIntakesForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('water_intakes')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => WaterIntakeModel.fromMap(
              doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting water intakes for date range: $e');
      return [];
    }
  }

  // Get today's water summary
  Future<WaterSummary> getTodayWaterSummary() async {
    try {
      final today = DateTime.now();
      final intakes = await getWaterIntakesForDate(today);

      int totalMl = 0;
      int effectiveHydrationMl = 0;

      for (final intake in intakes) {
        totalMl += intake.amountMl;
        effectiveHydrationMl +=
            intake.waterType.getEffectiveAmount(intake.amountMl);
      }

      // Calculate target based on default weight (70kg) for now
      // This could be enhanced to use actual user weight from profile
      final targetMl = WaterCalculator.calculateDailyTarget(weightKg: 70.0);
      final glassesConsumed = (totalMl / 250).round();

      return WaterSummary(
        date: today,
        totalMl: totalMl,
        effectiveHydrationMl: effectiveHydrationMl,
        targetMl: targetMl,
        intakes: intakes,
        glassesConsumed: glassesConsumed,
      );
    } catch (e) {
      print('Error getting today water summary: $e');
      return WaterSummary(
        date: DateTime.now(),
        totalMl: 0,
        effectiveHydrationMl: 0,
        targetMl: 2500, // Default target
        intakes: [],
        glassesConsumed: 0,
      );
    }
  }

  // Get water summary for a specific date
  Future<WaterSummary> getWaterSummaryForDate(DateTime date) async {
    try {
      final intakes = await getWaterIntakesForDate(date);

      int totalMl = 0;
      int effectiveHydrationMl = 0;

      for (final intake in intakes) {
        totalMl += intake.amountMl;
        effectiveHydrationMl +=
            intake.waterType.getEffectiveAmount(intake.amountMl);
      }

      final targetMl = WaterCalculator.calculateDailyTarget(weightKg: 70.0);
      final glassesConsumed = (totalMl / 250).round();

      return WaterSummary(
        date: date,
        totalMl: totalMl,
        effectiveHydrationMl: effectiveHydrationMl,
        targetMl: targetMl,
        intakes: intakes,
        glassesConsumed: glassesConsumed,
      );
    } catch (e) {
      print('Error getting water summary for date: $e');
      return WaterSummary(
        date: date,
        totalMl: 0,
        effectiveHydrationMl: 0,
        targetMl: 2500,
        intakes: [],
        glassesConsumed: 0,
      );
    }
  }

  // Update water intake record
  Future<void> updateWaterIntake(WaterIntakeModel intake) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (intake.id == null) {
        throw Exception('Water intake ID is required for update');
      }

      await _firestore
          .collection('water_intakes')
          .doc(intake.id)
          .update(intake.toMap());
    } catch (e) {
      print('Error updating water intake: $e');
      rethrow;
    }
  }

  // Delete water intake record
  Future<void> deleteWaterIntake(String intakeId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('water_intakes').doc(intakeId).delete();
    } catch (e) {
      print('Error deleting water intake: $e');
      rethrow;
    }
  }

  // Get weekly water summary
  Future<Map<DateTime, WaterSummary>> getWeeklyWaterSummary() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 6));

      Map<DateTime, WaterSummary> weeklySummary = {};

      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final summary = await getWaterSummaryForDate(date);
        weeklySummary[date] = summary;
      }

      return weeklySummary;
    } catch (e) {
      print('Error getting weekly water summary: $e');
      return {};
    }
  }

  // Get monthly water summary
  Future<Map<DateTime, WaterSummary>> getMonthlyWaterSummary() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 29));

      Map<DateTime, WaterSummary> monthlySummary = {};

      for (int i = 0; i < 30; i++) {
        final date = startDate.add(Duration(days: i));
        final summary = await getWaterSummaryForDate(date);
        monthlySummary[date] = summary;
      }

      return monthlySummary;
    } catch (e) {
      print('Error getting monthly water summary: $e');
      return {};
    }
  }

  // Get water intake stream for real-time updates
  Stream<List<WaterIntakeModel>> getTodayWaterIntakeStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('water_intakes')
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WaterIntakeModel.fromMap(
              doc.data(), doc.id))
          .toList();
    });
  }

  // Get today's water summary stream
  Stream<WaterSummary> getTodayWaterSummaryStream() {
    return getTodayWaterIntakeStream().map((intakes) {
      int totalMl = 0;
      int effectiveHydrationMl = 0;

      for (final intake in intakes) {
        totalMl += intake.amountMl;
        effectiveHydrationMl +=
            intake.waterType.getEffectiveAmount(intake.amountMl);
      }

      final targetMl = WaterCalculator.calculateDailyTarget(weightKg: 70.0);
      final glassesConsumed = (totalMl / 250).round();

      return WaterSummary(
        date: DateTime.now(),
        totalMl: totalMl,
        effectiveHydrationMl: effectiveHydrationMl,
        targetMl: targetMl,
        intakes: intakes,
        glassesConsumed: glassesConsumed,
      );
    });
  }

  // Get hydration streak (consecutive days meeting target)
  Future<int> getHydrationStreak() async {
    try {
      final endDate =
          DateTime.now().subtract(const Duration(days: 1)); // Yesterday
      final startDate =
          endDate.subtract(const Duration(days: 30)); // Last 30 days

      int streak = 0;
      for (int i = 0; i < 30; i++) {
        final date = endDate.subtract(Duration(days: i));
        final summary = await getWaterSummaryForDate(date);

        if (summary.isTargetReached) {
          streak++;
        } else {
          break; // Streak broken
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating hydration streak: $e');
      return 0;
    }
  }

  // Get average daily water intake for a period
  Future<double> getAverageDailyIntake({int days = 7}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));

      double totalMl = 0;
      int daysWithData = 0;

      for (int i = 0; i < days; i++) {
        final date = endDate.subtract(Duration(days: i));
        final summary = await getWaterSummaryForDate(date);

        if (summary.intakes.isNotEmpty) {
          totalMl += summary.totalMl;
          daysWithData++;
        }
      }

      return daysWithData > 0 ? totalMl / daysWithData : 0.0;
    } catch (e) {
      print('Error calculating average daily intake: $e');
      return 0.0;
    }
  }

  // Get hydration insights
  Future<Map<String, String>> getHydrationInsights() async {
    try {
      final todaySummary = await getTodayWaterSummary();
      final weeklyAverage = await getAverageDailyIntake(days: 7);
      final streak = await getHydrationStreak();

      Map<String, String> insights = {};

      // Today's hydration insight
      if (todaySummary.progressPercentage >= 100) {
        insights['today'] =
            'Great job! You\'ve reached your hydration goal today! 🎉';
      } else if (todaySummary.progressPercentage >= 80) {
        insights['today'] =
            'You\'re almost there! Just ${todaySummary.remainingGlasses} more glasses to go! 💧';
      } else if (todaySummary.progressPercentage >= 50) {
        insights['today'] =
            'Keep going! You\'re halfway to your daily hydration goal. 👍';
      } else {
        insights['today'] =
            'Time to hydrate! Remember to drink water regularly throughout the day. 💦';
      }

      // Weekly average insight
      if (weeklyAverage >= 2000) {
        insights['weekly'] =
            'Your weekly hydration average is excellent! Keep it up! 🌟';
      } else if (weeklyAverage >= 1500) {
        insights['weekly'] =
            'Good weekly hydration habits! Try to increase slightly for optimal health. 👌';
      } else {
        insights['weekly'] =
            'Your weekly water intake could be improved. Set reminders to drink more! 📱';
      }

      // Streak insight
      if (streak >= 7) {
        insights['streak'] =
            'Amazing! You have a $streak-day hydration streak! 🔥';
      } else if (streak >= 3) {
        insights['streak'] =
            'Nice $streak-day streak! Keep the momentum going! 💪';
      } else {
        insights['streak'] =
            'Start building your hydration streak by meeting your daily goal! 🎯';
      }

      return insights;
    } catch (e) {
      print('Error getting hydration insights: $e');
      return {};
    }
  }

  // Get personalized water target (enhanced version with user data)
  Future<int> getPersonalizedWaterTarget() async {
    try {
      // This could be enhanced to fetch actual user data
      // For now, using default values
      return WaterCalculator.calculateDailyTarget(
        weightKg: 70.0, // Could fetch from user profile
        activityMinutes: 60, // Could fetch from today's workout
      );
    } catch (e) {
      print('Error getting personalized water target: $e');
      return 2500; // Default target
    }
  }

  // Check if user has consumed water in the last N hours
  Future<bool> hasConsumedWaterRecently({int hours = 2}) async {
    try {
      if (currentUserId == null) return false;

      final cutoffTime = DateTime.now().subtract(Duration(hours: hours));

      final querySnapshot = await _firestore
          .collection('water_intakes')
          .where('userId', isEqualTo: currentUserId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffTime))
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking recent water consumption: $e');
      return false;
    }
  }

  // Get most consumed water type today
  Future<WaterType?> getMostConsumedTypeToday() async {
    try {
      final todaySummary = await getTodayWaterSummary();
      return todaySummary.mostConsumedType;
    } catch (e) {
      print('Error getting most consumed water type: $e');
      return null;
    }
  }

  // Bulk add water intakes (for importing data or testing)
  Future<void> bulkAddWaterIntakes(List<WaterIntakeModel> intakes) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();

      for (final intake in intakes) {
        final docRef = _firestore.collection('water_intakes').doc();
        batch.set(docRef, intake.toMap());
      }

      await batch.commit();
    } catch (e) {
      print('Error bulk adding water intakes: $e');
      rethrow;
    }
  }
}
