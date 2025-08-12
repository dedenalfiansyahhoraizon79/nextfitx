import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new notification
  Future<String> createNotification(NotificationModel notification) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // Get all notifications for current user
  Future<List<NotificationModel>> getUserNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  // Get notifications by type
  Future<List<NotificationModel>> getNotificationsByType(
    NotificationType type, {
    int limit = 20,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromMap(
              doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting notifications by type: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
      rethrow;
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      if (currentUserId == null) return 0;

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Get real-time notifications stream
  Stream<List<NotificationModel>> getNotificationsStream({int limit = 50}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(
              doc.data(), doc.id))
          .toList();
    });
  }

  // Get real-time unread count stream
  Stream<int> getUnreadCountStream() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Smart notification generators
  Future<void> generateSmartNotifications() async {
    try {
      if (currentUserId == null) return;

      final now = DateTime.now();

      // Check for water reminder (every 2 hours during day)
      if (now.hour >= 8 && now.hour <= 22 && now.hour % 2 == 0) {
        // Check if user hasn't logged water recently
        // This would integrate with WaterIntakeService
        await _generateWaterReminder();
      }

      // Check for meal reminders
      if (_isMealTime(now)) {
        await _generateMealReminder(now);
      }

      // Check for sleep reminder
      if (now.hour == 22) {
        await _generateSleepReminder();
      }

      // Check for workout reminder
      if (now.hour == 18) {
        await _generateWorkoutReminder();
      }
    } catch (e) {
      print('Error generating smart notifications: $e');
    }
  }

  // Generate sample notifications for demo/testing
  Future<void> generateSampleNotifications() async {
    try {
      if (currentUserId == null) return;

      final notifications = [
        NotificationBuilder.createWaterReminder(currentUserId!),
        NotificationBuilder.createWorkoutReminder(currentUserId!),
        NotificationBuilder.createMealReminder(currentUserId!, 'Lunch'),
        NotificationBuilder.createAchievement(
            currentUserId!,
            'First Week Complete',
            'You\'ve successfully tracked your health for 7 days!'),
        NotificationBuilder.createStreakMilestone(
            currentUserId!, 'water intake', 5),
        NotificationBuilder.createFastingComplete(currentUserId!, '16:8'),
        NotificationBuilder.createWeeklySummary(currentUserId!,
            {'workouts': 4, 'water_goal_met': 5, 'calories_burned': 2400}),
        NotificationBuilder.createWelcome(currentUserId!),
      ];

      // Add notifications with slight delays to show different times
      for (int i = 0; i < notifications.length; i++) {
        final notification = notifications[i].copyWith(
            createdAt: DateTime.now().subtract(Duration(hours: i * 2)));
        await createNotification(notification);
      }
    } catch (e) {
      print('Error generating sample notifications: $e');
    }
  }

  // Private helper methods
  Future<void> _generateWaterReminder() async {
    try {
      // Check if we already sent a water reminder in the last 2 hours
      final recentWaterNotifications = await getNotificationsByType(
        NotificationType.water,
        limit: 1,
      );

      if (recentWaterNotifications.isNotEmpty) {
        final lastNotification = recentWaterNotifications.first;
        final timeDiff = DateTime.now().difference(lastNotification.createdAt);
        if (timeDiff.inHours < 2) {
          return; // Don't spam notifications
        }
      }

      final notification =
          NotificationBuilder.createWaterReminder(currentUserId!);
      await createNotification(notification);
    } catch (e) {
      print('Error generating water reminder: $e');
    }
  }

  Future<void> _generateMealReminder(DateTime now) async {
    try {
      String mealType;
      if (now.hour >= 6 && now.hour <= 10) {
        mealType = 'Breakfast';
      } else if (now.hour >= 12 && now.hour <= 14) {
        mealType = 'Lunch';
      } else if (now.hour >= 18 && now.hour <= 20) {
        mealType = 'Dinner';
      } else {
        return;
      }

      final notification =
          NotificationBuilder.createMealReminder(currentUserId!, mealType);
      await createNotification(notification);
    } catch (e) {
      print('Error generating meal reminder: $e');
    }
  }

  Future<void> _generateSleepReminder() async {
    try {
      final notification =
          NotificationBuilder.createSleepReminder(currentUserId!);
      await createNotification(notification);
    } catch (e) {
      print('Error generating sleep reminder: $e');
    }
  }

  Future<void> _generateWorkoutReminder() async {
    try {
      final notification =
          NotificationBuilder.createWorkoutReminder(currentUserId!);
      await createNotification(notification);
    } catch (e) {
      print('Error generating workout reminder: $e');
    }
  }

  bool _isMealTime(DateTime time) {
    final hour = time.hour;
    return (hour == 8) || (hour == 13) || (hour == 19); // 8am, 1pm, 7pm
  }

  // Handle notification actions
  Future<void> handleNotificationAction(NotificationModel notification) async {
    try {
      if (!notification.isActionable || notification.actionData == null) {
        return;
      }

      final actionData = json.decode(notification.actionData!);
      final action = actionData['action'] as String;

      switch (action) {
        case 'quick_add_water':
          // This would integrate with WaterIntakeService
          // await _waterService.quickAddWater(actionData['amount'] ?? 250);
          break;
        case 'open_workout':
          // Navigation would be handled in the UI layer
          break;
        case 'open_meal':
          // Navigation would be handled in the UI layer
          break;
        case 'start_sleep_timer':
          // This would integrate with SleepService
          break;
        case 'view_fasting_timer':
          // Navigation would be handled in the UI layer
          break;
        case 'break_fast':
          // This would integrate with FastingService
          break;
        case 'setup_profile':
          // Navigation would be handled in the UI layer
          break;
        case 'view_weekly_summary':
          // Navigation would be handled in the UI layer
          break;
      }

      // Mark notification as read after action
      if (notification.id != null) {
        await markAsRead(notification.id!);
      }
    } catch (e) {
      print('Error handling notification action: $e');
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      if (currentUserId == null) return {};

      final allNotifications = await getUserNotifications(limit: 100);
      final unreadNotifications =
          allNotifications.where((n) => !n.isRead).toList();

      Map<String, int> typeCount = {};
      Map<String, int> priorityCount = {};

      for (final notification in allNotifications) {
        typeCount[notification.type.displayName] =
            (typeCount[notification.type.displayName] ?? 0) + 1;
        priorityCount[notification.priority.displayName] =
            (priorityCount[notification.priority.displayName] ?? 0) + 1;
      }

      return {
        'total': allNotifications.length,
        'unread': unreadNotifications.length,
        'read': allNotifications.length - unreadNotifications.length,
        'byType': typeCount,
        'byPriority': priorityCount,
        'mostRecentType': allNotifications.isNotEmpty
            ? allNotifications.first.type.displayName
            : null,
      };
    } catch (e) {
      print('Error getting notification stats: $e');
      return {};
    }
  }

  // Clear old notifications (cleanup)
  Future<void> clearOldNotifications({int daysOld = 30}) async {
    try {
      if (currentUserId == null) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing old notifications: $e');
    }
  }

  // Search notifications
  Future<List<NotificationModel>> searchNotifications(String query) async {
    try {
      if (currentUserId == null) return [];

      final notifications = await getUserNotifications(limit: 100);

      return notifications.where((notification) {
        return notification.title.toLowerCase().contains(query.toLowerCase()) ||
            notification.message.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching notifications: $e');
      return [];
    }
  }
}
