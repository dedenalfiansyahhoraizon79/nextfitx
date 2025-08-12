import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isRead;
  final bool isActionable;
  final String? actionData; // JSON string for action parameters
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.scheduledFor,
    this.isRead = false,
    this.isActionable = false,
    this.actionData,
    this.imageUrl,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledFor':
          scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'isRead': isRead,
      'isActionable': isActionable,
      'actionData': actionData,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.fromName(map['type'] ?? 'general'),
      priority: NotificationPriority.fromName(map['priority'] ?? 'normal'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      scheduledFor: map['scheduledFor'] != null
          ? (map['scheduledFor'] as Timestamp).toDate()
          : null,
      isRead: map['isRead'] ?? false,
      isActionable: map['isActionable'] ?? false,
      actionData: map['actionData'],
      imageUrl: map['imageUrl'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? scheduledFor,
    bool? isRead,
    bool? isActionable,
    String? actionData,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isRead: isRead ?? this.isRead,
      isActionable: isActionable ?? this.isActionable,
      actionData: actionData ?? this.actionData,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isOverdue {
    if (scheduledFor == null) return false;
    return DateTime.now().isAfter(scheduledFor!);
  }

  bool get isToday {
    if (scheduledFor == null) return false;
    final now = DateTime.now();
    final scheduled = scheduledFor!;
    return now.year == scheduled.year &&
        now.month == scheduled.month &&
        now.day == scheduled.day;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Notification types with different behaviors
enum NotificationType {
  general('General', '📋', 'General notifications'),
  water('Water Reminder', '💧', 'Hydration reminders'),
  workout('Workout', '💪', 'Exercise and fitness'),
  meal('Meal Reminder', '🍽️', 'Nutrition and meal tracking'),
  sleep('Sleep Reminder', '😴', 'Sleep schedule and quality'),
  fasting('Fasting', '⏱️', 'Intermittent fasting updates'),
  bodyComp('Body Composition', '📊', 'Body metrics tracking'),
  achievement('Achievement', '🏆', 'Goals and milestones'),
  reminder('Reminder', '⏰', 'Custom reminders'),
  system('System', '⚙️', 'App updates and system notifications');

  const NotificationType(this.displayName, this.emoji, this.description);

  final String displayName;
  final String emoji;
  final String description;

  static NotificationType fromName(String name) {
    return NotificationType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => NotificationType.general,
    );
  }
}

// Notification priority levels
enum NotificationPriority {
  low('Low', 1),
  normal('Normal', 2),
  high('High', 3),
  urgent('Urgent', 4);

  const NotificationPriority(this.displayName, this.level);

  final String displayName;
  final int level;

  static NotificationPriority fromName(String name) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.name == name,
      orElse: () => NotificationPriority.normal,
    );
  }
}

// Notification action types
enum NotificationAction {
  openFeature('Open Feature'),
  quickAdd('Quick Add'),
  viewDetails('View Details'),
  startTimer('Start Timer'),
  logActivity('Log Activity'),
  updateGoal('Update Goal'),
  dismiss('Dismiss');

  const NotificationAction(this.displayName);

  final String displayName;
}

// Notification builder for creating common notifications
class NotificationBuilder {
  // Water reminder notifications
  static NotificationModel createWaterReminder(String userId) {
    return NotificationModel(
      userId: userId,
      title: 'Time to Hydrate! 💧',
      message: 'You haven\'t logged water in the last 2 hours. Stay hydrated!',
      type: NotificationType.water,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      isActionable: true,
      actionData: '{"action": "quick_add_water", "amount": 250}',
    );
  }

  // Workout reminder notifications
  static NotificationModel createWorkoutReminder(String userId) {
    return NotificationModel(
      userId: userId,
      title: 'Time to Move! 💪',
      message: 'Haven\'t seen a workout today. Let\'s get active!',
      type: NotificationType.workout,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      isActionable: true,
      actionData: '{"action": "open_workout"}',
    );
  }

  // Meal reminder notifications
  static NotificationModel createMealReminder(String userId, String mealType) {
    return NotificationModel(
      userId: userId,
      title: '$mealType Time! 🍽️',
      message:
          'Don\'t forget to log your $mealType for proper nutrition tracking.',
      type: NotificationType.meal,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      isActionable: true,
      actionData: '{"action": "open_meal", "meal_type": "$mealType"}',
    );
  }

  // Sleep reminder notifications
  static NotificationModel createSleepReminder(String userId) {
    return NotificationModel(
      userId: userId,
      title: 'Good Night! 😴',
      message: 'Time to wind down for better sleep quality.',
      type: NotificationType.sleep,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      isActionable: true,
      actionData: '{"action": "start_sleep_timer"}',
    );
  }

  // Fasting notifications
  static NotificationModel createFastingStarted(
      String userId, String fastingType) {
    return NotificationModel(
      userId: userId,
      title: 'Fasting Started! ⏱️',
      message: 'Your $fastingType fasting session has begun. Good luck!',
      type: NotificationType.fasting,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      isActionable: true,
      actionData: '{"action": "view_fasting_timer"}',
    );
  }

  static NotificationModel createFastingComplete(
      String userId, String duration) {
    return NotificationModel(
      userId: userId,
      title: 'Fasting Complete! 🎉',
      message: 'Congratulations! You\'ve completed your $duration fast.',
      type: NotificationType.fasting,
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      isActionable: true,
      actionData: '{"action": "break_fast"}',
    );
  }

  // Achievement notifications
  static NotificationModel createAchievement(
      String userId, String title, String description) {
    return NotificationModel(
      userId: userId,
      title: 'Achievement Unlocked! 🏆',
      message: '$title - $description',
      type: NotificationType.achievement,
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      isActionable: false,
    );
  }

  // Goal completion notifications
  static NotificationModel createGoalCompleted(
      String userId, String goalType, String details) {
    return NotificationModel(
      userId: userId,
      title: 'Goal Achieved! 🎯',
      message: 'You\'ve reached your $goalType goal! $details',
      type: NotificationType.achievement,
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      isActionable: false,
    );
  }

  // Streak notifications
  static NotificationModel createStreakMilestone(
      String userId, String feature, int days) {
    return NotificationModel(
      userId: userId,
      title: 'Streak Milestone! 🔥',
      message: '$days day $feature streak! Keep the momentum going!',
      type: NotificationType.achievement,
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      isActionable: false,
    );
  }

  // Weekly summary notifications
  static NotificationModel createWeeklySummary(
      String userId, Map<String, dynamic> stats) {
    return NotificationModel(
      userId: userId,
      title: 'Weekly Summary 📊',
      message: 'Here\'s how you did this week! Tap to see your progress.',
      type: NotificationType.general,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      isActionable: true,
      actionData: '{"action": "view_weekly_summary"}',
      metadata: stats,
    );
  }

  // System notifications
  static NotificationModel createWelcome(String userId) {
    return NotificationModel(
      userId: userId,
      title: 'Welcome to nextfitX! 👋',
      message:
          'Start your fitness journey by setting up your profile and goals.',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      isActionable: true,
      actionData: '{"action": "setup_profile"}',
    );
  }

  static NotificationModel createAppUpdate(String userId, String version) {
    return NotificationModel(
      userId: userId,
      title: 'App Updated! ✨',
      message:
          'nextfitX has been updated to version $version with new features!',
      type: NotificationType.system,
      priority: NotificationPriority.low,
      createdAt: DateTime.now(),
      isActionable: false,
    );
  }
}
