import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart';
import 'user_service.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  String? get currentUserId => _auth.currentUser?.uid;

  // Collection reference for workout data
  CollectionReference get _workoutCollection {
    if (currentUserId == null) {
      throw Exception('No authenticated user found');
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('workouts');
  }

  // Get user's weight for calorie calculation
  Future<double> _getUserWeight() async {
    try {
      final userProfile = await _userService.getUserProfile();
      return userProfile?['weight']?.toDouble() ?? 70.0; // Default 70kg
    } catch (e) {
      return 70.0; // Default weight if can't fetch
    }
  }

  // Create new workout record
  Future<String> createWorkout(WorkoutModel workout) async {
    try {
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      final now = DateTime.now();
      final userWeight = await _getUserWeight();

      // Calculate calories using local AI
      final calories = CalorieCalculator.calculateCalories(
        workoutType: workout.workoutType,
        durationMinutes: workout.durationMinutes,
        weightKg: userWeight,
      );

      final data = workout.copyWith(
        userId: currentUserId!,
        caloriesBurned: calories,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _workoutCollection.add(data.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create workout record: $e');
    }
  }

  // Get all workout records for current user
  Future<List<WorkoutModel>> getWorkoutRecords({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _workoutCollection.orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) =>
              WorkoutModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get workout records: $e');
    }
  }

  // Get workout record by ID
  Future<WorkoutModel?> getWorkoutById(String id) async {
    try {
      final doc = await _workoutCollection.doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return WorkoutModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get workout record: $e');
    }
  }

  // Get workout records for a specific date
  Future<List<WorkoutModel>> getWorkoutsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _workoutCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              WorkoutModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get workouts for date: $e');
    }
  }

  // Get workout records for a date range
  Future<List<WorkoutModel>> getWorkoutsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final snapshot = await _workoutCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              WorkoutModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get workouts for date range: $e');
    }
  }

  // Update workout record
  Future<void> updateWorkout(String id, WorkoutModel workout) async {
    try {
      final userWeight = await _getUserWeight();

      // Recalculate calories if workout type or duration changed
      final calories = CalorieCalculator.calculateCalories(
        workoutType: workout.workoutType,
        durationMinutes: workout.durationMinutes,
        weightKg: userWeight,
      );

      final data = workout.copyWith(
        id: id,
        caloriesBurned: calories,
        updatedAt: DateTime.now(),
      );

      await _workoutCollection.doc(id).update(data.toMap());
    } catch (e) {
      throw Exception('Failed to update workout record: $e');
    }
  }

  // Delete workout record
  Future<void> deleteWorkout(String id) async {
    try {
      await _workoutCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete workout record: $e');
    }
  }

  // Get chart data for different metrics
  Future<List<WorkoutChartData>> getChartData(
    String metric, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit = 30,
  }) async {
    try {
      final records = await getWorkoutRecords(
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      return records.map((record) {
        double value = 0.0;

        switch (metric.toLowerCase()) {
          case 'calories':
          case 'calories_burned':
            value = record.caloriesBurned;
            break;
          case 'duration':
          case 'duration_minutes':
            value = record.durationMinutes.toDouble();
            break;
          case 'workout_count':
            value = 1.0; // For counting workouts per day
            break;
          default:
            value = record.caloriesBurned;
        }

        return WorkoutChartData(
          date: record.date,
          value: value,
          type: metric,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get chart data: $e');
    }
  }

  // Get aggregated chart data (sum by date for multiple workouts per day)
  Future<List<WorkoutChartData>> getAggregatedChartData(
    String metric, {
    DateTime? startDate,
    DateTime? endDate,
    int? days = 30,
  }) async {
    try {
      final endDateTime = endDate ?? DateTime.now();
      final startDateTime =
          startDate ?? endDateTime.subtract(Duration(days: days!));

      final records = await getWorkoutRecords(
        startDate: startDateTime,
        endDate: endDateTime,
      );

      // Group by date and aggregate
      final Map<String, double> dateAggregation = {};

      for (final record in records) {
        final dateKey =
            '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';

        double value = 0.0;
        switch (metric.toLowerCase()) {
          case 'calories':
          case 'calories_burned':
            value = record.caloriesBurned;
            break;
          case 'duration':
          case 'duration_minutes':
            value = record.durationMinutes.toDouble();
            break;
          case 'workout_count':
            value = 1.0;
            break;
        }

        dateAggregation[dateKey] = (dateAggregation[dateKey] ?? 0.0) + value;
      }

      // Convert back to chart data
      return dateAggregation.entries.map((entry) {
        final dateParts = entry.key.split('-');
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );

        return WorkoutChartData(
          date: date,
          value: entry.value,
          type: metric,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      throw Exception('Failed to get aggregated chart data: $e');
    }
  }

  // Get workout summary
  Future<WorkoutSummary> getWorkoutSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final records = await getWorkoutRecords(
        startDate: startDate,
        endDate: endDate,
      );

      if (records.isEmpty) {
        return WorkoutSummary(
          totalCaloriesBurned: 0.0,
          totalWorkouts: 0,
          totalMinutes: 0,
          averageCaloriesPerWorkout: 0.0,
          averageDurationPerWorkout: 0.0,
          mostFrequentWorkout: 'None',
          workoutsThisWeek: 0,
          workoutsThisMonth: 0,
        );
      }

      // Calculate totals
      final totalCalories =
          records.fold(0.0, (sum, record) => sum + record.caloriesBurned);
      final totalMinutes =
          records.fold(0, (sum, record) => sum + record.durationMinutes);
      final totalWorkouts = records.length;

      // Calculate averages
      final averageCalories = totalCalories / totalWorkouts;
      final averageDuration = totalMinutes / totalWorkouts;

      // Find most frequent workout
      final workoutFrequency = <String, int>{};
      for (final record in records) {
        workoutFrequency[record.workoutType] =
            (workoutFrequency[record.workoutType] ?? 0) + 1;
      }
      final mostFrequent = workoutFrequency.isNotEmpty
          ? workoutFrequency.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : 'None';

      // Calculate this week and month
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      final workoutsThisWeek =
          records.where((r) => r.date.isAfter(weekStart)).length;
      final workoutsThisMonth =
          records.where((r) => r.date.isAfter(monthStart)).length;

      return WorkoutSummary(
        totalCaloriesBurned: totalCalories,
        totalWorkouts: totalWorkouts,
        totalMinutes: totalMinutes,
        averageCaloriesPerWorkout: averageCalories,
        averageDurationPerWorkout: averageDuration,
        mostFrequentWorkout: mostFrequent,
        workoutsThisWeek: workoutsThisWeek,
        workoutsThisMonth: workoutsThisMonth,
        lastWorkoutDate: records.isNotEmpty ? records.first.date : null,
      );
    } catch (e) {
      throw Exception('Failed to get workout summary: $e');
    }
  }

  // Get recent workout records (last 7 days)
  Future<List<WorkoutModel>> getRecentWorkouts() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      return await getWorkoutRecords(
        startDate: sevenDaysAgo,
        limit: 20,
      );
    } catch (e) {
      throw Exception('Failed to get recent workouts: $e');
    }
  }

  // Check if user has workout for today
  Future<bool> hasWorkoutForToday() async {
    try {
      final today = DateTime.now();
      final workouts = await getWorkoutsByDate(today);
      return workouts.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get workout statistics by type
  Future<Map<String, dynamic>> getWorkoutStatsByType({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final records = await getWorkoutRecords(
        startDate: startDate,
        endDate: endDate,
      );

      final Map<String, Map<String, dynamic>> stats = {};

      for (final record in records) {
        final type = record.workoutType;
        if (!stats.containsKey(type)) {
          stats[type] = {
            'count': 0,
            'totalMinutes': 0,
            'totalCalories': 0.0,
            'avgDuration': 0.0,
            'avgCalories': 0.0,
          };
        }

        stats[type]!['count'] += 1;
        stats[type]!['totalMinutes'] += record.durationMinutes;
        stats[type]!['totalCalories'] += record.caloriesBurned;
      }

      // Calculate averages
      for (final type in stats.keys) {
        final count = stats[type]!['count'];
        stats[type]!['avgDuration'] = stats[type]!['totalMinutes'] / count;
        stats[type]!['avgCalories'] = stats[type]!['totalCalories'] / count;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get workout stats by type: $e');
    }
  }

  // Get weekly workout goals progress
  Future<Map<String, dynamic>> getWeeklyProgress() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      final weekWorkouts = await getWorkoutRecords(
        startDate: weekStart,
        endDate: now,
      );

      final totalMinutes =
          weekWorkouts.fold(0, (sum, w) => sum + w.durationMinutes);
      final totalCalories =
          weekWorkouts.fold(0.0, (sum, w) => sum + w.caloriesBurned);
      final workoutDays = weekWorkouts
          .map((w) => '${w.date.year}-${w.date.month}-${w.date.day}')
          .toSet()
          .length;

      // Default goals (these could be fetched from user settings)
      const goalMinutesPerWeek = 150; // WHO recommendation
      const goalCaloriesPerWeek = 2000;
      const goalWorkoutDays = 3;

      return {
        'currentMinutes': totalMinutes,
        'goalMinutes': goalMinutesPerWeek,
        'minutesProgress': (totalMinutes / goalMinutesPerWeek).clamp(0.0, 1.0),
        'currentCalories': totalCalories,
        'goalCalories': goalCaloriesPerWeek,
        'caloriesProgress':
            (totalCalories / goalCaloriesPerWeek).clamp(0.0, 1.0),
        'currentWorkoutDays': workoutDays,
        'goalWorkoutDays': goalWorkoutDays,
        'workoutDaysProgress': (workoutDays / goalWorkoutDays).clamp(0.0, 1.0),
        'weekWorkouts': weekWorkouts.length,
      };
    } catch (e) {
      throw Exception('Failed to get weekly progress: $e');
    }
  }

  // Stream for real-time updates
  Stream<List<WorkoutModel>> workoutStream() {
    try {
      return _workoutCollection
          .orderBy('date', descending: true)
          .limit(30)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => WorkoutModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList());
    } catch (e) {
      throw Exception('Failed to create workout stream: $e');
    }
  }

  // Get calorie burn prediction for workout type and duration
  Future<double> predictCalorieBurn({
    required String workoutType,
    required int durationMinutes,
  }) async {
    try {
      final userWeight = await _getUserWeight();
      return CalorieCalculator.calculateCalories(
        workoutType: workoutType,
        durationMinutes: durationMinutes,
        weightKg: userWeight,
      );
    } catch (e) {
      return CalorieCalculator.calculateCalories(
        workoutType: workoutType,
        durationMinutes: durationMinutes,
        weightKg: 70.0, // Default weight
      );
    }
  }
}
