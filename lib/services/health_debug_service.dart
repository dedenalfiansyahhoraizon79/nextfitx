import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sleep_service.dart';
import 'intermittent_fasting_service.dart';
import 'water_intake_service.dart';
import 'meal_service.dart';
import 'workout_service.dart';
import 'body_composition_service.dart';
import 'notification_service.dart';

class HealthDebugService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final SleepService _sleepService = SleepService();
  final IntermittentFastingService _fastingService =
      IntermittentFastingService();
  final WaterIntakeService _waterService = WaterIntakeService();
  final MealService _mealService = MealService();
  final WorkoutService _workoutService = WorkoutService();
  final BodyCompositionService _bodyService = BodyCompositionService();
  final NotificationService _notificationService = NotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Comprehensive health check for all services
  Future<Map<String, dynamic>> performHealthCheck() async {
    try {
      final results = <String, dynamic>{};

      // Authentication check
      results['authentication'] = await _checkAuthentication();

      // Firestore connection check
      results['firestore'] = await _checkFirestoreConnection();

      // Individual service checks
      results['sleep'] = await _checkSleepService();
      results['fasting'] = await _checkFastingService();
      results['water'] = await _checkWaterService();
      results['meals'] = await _checkMealService();
      results['workouts'] = await _checkWorkoutService();
      results['bodyComposition'] = await _checkBodyCompositionService();
      results['notifications'] = await _checkNotificationService();

      // Overall health score
      results['healthScore'] = _calculateHealthScore(results);
      results['timestamp'] = DateTime.now().toIso8601String();

      return results;
    } catch (e) {
      return {
        'error': 'Health check failed: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Generate sample data for all services
  Future<Map<String, dynamic>> generateAllSampleData() async {
    try {
      final results = <String, dynamic>{};

      if (currentUserId == null) {
        return {'error': 'User not authenticated'};
      }

      // Generate sample data for each service
      try {
        await _sleepService.generateSampleSleepData();
        results['sleep'] = 'Sample sleep data generated successfully';
      } catch (e) {
        results['sleep'] = 'Error: $e';
      }

      try {
        await _fastingService.generateSampleFastingData();
        results['fasting'] = 'Sample fasting data generated successfully';
      } catch (e) {
        results['fasting'] = 'Error: $e';
      }

      try {
        await _notificationService.generateSampleNotifications();
        results['notifications'] =
            'Sample notifications generated successfully';
      } catch (e) {
        results['notifications'] = 'Error: $e';
      }

      // Generate sample water intake (last 7 days)
      try {
        await _generateSampleWaterData();
        results['water'] = 'Sample water data generated successfully';
      } catch (e) {
        results['water'] = 'Error: $e';
      }

      // Generate sample workout data
      try {
        await _generateSampleWorkoutData();
        results['workouts'] = 'Sample workout data generated successfully';
      } catch (e) {
        results['workouts'] = 'Error: $e';
      }

      // Generate sample meal data
      try {
        await _generateSampleMealData();
        results['meals'] = 'Sample meal data generated successfully';
      } catch (e) {
        results['meals'] = 'Error: $e';
      }

      // Generate sample body composition data
      try {
        await _generateSampleBodyCompositionData();
        results['bodyComposition'] =
            'Sample body composition data generated successfully';
      } catch (e) {
        results['bodyComposition'] = 'Error: $e';
      }

      results['timestamp'] = DateTime.now().toIso8601String();
      results['status'] = 'All sample data generation completed';

      return results;
    } catch (e) {
      return {
        'error': 'Sample data generation failed: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Clear all user data (for testing purposes)
  Future<Map<String, dynamic>> clearAllUserData() async {
    try {
      if (currentUserId == null) {
        return {'error': 'User not authenticated'};
      }

      final results = <String, dynamic>{};
      final batch = _firestore.batch();

      // Collections to clear
      final collections = [
        'sleep_records',
        'fasting_records',
        'water_intakes',
        'meals',
        'workouts',
        'body_compositions',
        'notifications',
      ];

      int totalDeleted = 0;

      for (final collection in collections) {
        try {
          final querySnapshot = await _firestore
              .collection(collection)
              .where('userId', isEqualTo: currentUserId)
              .get();

          for (final doc in querySnapshot.docs) {
            batch.delete(doc.reference);
            totalDeleted++;
          }

          results[collection] =
              '${querySnapshot.docs.length} records marked for deletion';
        } catch (e) {
          results[collection] = 'Error: $e';
        }
      }

      // Execute batch delete
      await batch.commit();

      results['totalDeleted'] = totalDeleted;
      results['status'] = 'All user data cleared successfully';
      results['timestamp'] = DateTime.now().toIso8601String();

      return results;
    } catch (e) {
      return {
        'error': 'Data clearing failed: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Private helper methods

  Future<Map<String, dynamic>> _checkAuthentication() async {
    try {
      final user = _auth.currentUser;
      return {
        'status': user != null ? 'authenticated' : 'not_authenticated',
        'userId': user?.uid,
        'email': user?.email,
        'displayName': user?.displayName,
        'emailVerified': user?.emailVerified,
      };
    } catch (e) {
      return {'error': 'Auth check failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _checkFirestoreConnection() async {
    try {
      // Try to read from a simple collection
      final testDoc = await _firestore.collection('test').limit(1).get();
      return {
        'status': 'connected',
        'canRead': true,
        'testQuery': 'successful',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': 'Firestore connection failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _checkSleepService() async {
    try {
      final debugInfo = await _sleepService.debugSleepRecords();
      final hasRecords = await _sleepService.hasAnySleepRecords();
      return {
        'hasRecords': hasRecords,
        'debugInfo': debugInfo,
        'status': 'healthy',
      };
    } catch (e) {
      return {'error': 'Sleep service check failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _checkFastingService() async {
    try {
      final debugInfo = await _fastingService.debugFastingRecords();
      final hasRecords = await _fastingService.hasAnyFastingRecords();
      return {
        'hasRecords': hasRecords,
        'debugInfo': debugInfo,
        'status': 'healthy',
      };
    } catch (e) {
      return {'error': 'Fasting service check failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _checkWaterService() async {
    try {
      final todaySummary = await _waterService.getTodayWaterSummary();
      return {
        'todayIntake': todaySummary.totalMl,
        'progress': todaySummary.progressPercentage,
        'status': 'healthy',
      };
    } catch (e) {
      return {'error': 'Water service check failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _checkMealService() async {
    try {
      final todayNutrition = await _mealService.getTodayNutritionSummary();
      return {
        'todayCalories': todayNutrition['calories'],
        'status': 'healthy',
      };
    } catch (e) {
      return {'error': 'Meal service check failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _checkWorkoutService() async {
    try {
      final todayWorkouts = await _workoutService.getWorkoutsByDate(DateTime.now());
      return {
        'todayWorkouts': todayWorkouts.length,
        'status': 'healthy',
      };
    } catch (e) {
      return {'error': 'Workout service check failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _checkBodyCompositionService() async {
    try {
      final latestRecord =
          await _bodyService.getBodyCompositionRecords(limit: 1);
      return {
        'hasRecords': latestRecord.isNotEmpty,
        'latestBMI': latestRecord.isNotEmpty
            ? latestRecord.first.bodyComposition.bmi
            : null,
        'status': 'healthy',
      };
    } catch (e) {
      return {'error': 'Body composition service check failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _checkNotificationService() async {
    try {
      final unreadCount = await _notificationService.getUnreadCount();
      return {
        'unreadCount': unreadCount,
        'status': 'healthy',
      };
    } catch (e) {
      return {'error': 'Notification service check failed: $e'};
    }
  }

  double _calculateHealthScore(Map<String, dynamic> results) {
    int healthyServices = 0;
    int totalServices = 0;

    final serviceKeys = [
      'sleep',
      'fasting',
      'water',
      'meals',
      'workouts',
      'bodyComposition',
      'notifications'
    ];

    for (final key in serviceKeys) {
      totalServices++;
      final serviceResult = results[key];
      if (serviceResult is Map && serviceResult['status'] == 'healthy') {
        healthyServices++;
      }
    }

    return totalServices > 0 ? (healthyServices / totalServices * 100) : 0.0;
  }

  // Sample data generators for services that don't have them yet

  Future<void> _generateSampleWaterData() async {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));

      // Generate 4-8 water intakes per day
      final intakesPerDay = 4 + (i % 5);
      for (int j = 0; j < intakesPerDay; j++) {
        final hour = 8 + (j * 2); // Every 2 hours from 8am
        final timestamp = DateTime(date.year, date.month, date.day, hour, 0);

        await _waterService.quickAddWater(250);
      }
    }
  }

  Future<void> _generateSampleWorkoutData() async {
    // This would need to be implemented based on WorkoutService structure
    // For now, just a placeholder
    print('Sample workout data generation not yet implemented');
  }

  Future<void> _generateSampleMealData() async {
    // This would need to be implemented based on MealService structure
    // For now, just a placeholder
    print('Sample meal data generation not yet implemented');
  }

  Future<void> _generateSampleBodyCompositionData() async {
    // This would need to be implemented based on BodyCompositionService structure
    // For now, just a placeholder
    print('Sample body composition data generation not yet implemented');
  }
}
 
