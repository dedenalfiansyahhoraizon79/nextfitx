import 'package:cloud_firestore/cloud_firestore.dart';

class FastingModel {
  final String? id;
  final String userId;
  final DateTime date;
  final FastingType fastingType;
  final DateTime startTime;
  final DateTime? endTime;
  final int targetDurationHours;
  final int? actualDurationMinutes;
  final FastingStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FastingModel({
    this.id,
    required this.userId,
    required this.date,
    required this.fastingType,
    required this.startTime,
    this.endTime,
    required this.targetDurationHours,
    this.actualDurationMinutes,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate current fasting duration in minutes
  int get currentDurationMinutes {
    if (status == FastingStatus.active) {
      return DateTime.now().difference(startTime).inMinutes;
    } else if (actualDurationMinutes != null) {
      return actualDurationMinutes!;
    }
    return 0;
  }

  // Calculate current fasting duration in hours
  double get currentDurationHours {
    return currentDurationMinutes / 60.0;
  }

  // Get formatted duration
  String get currentDurationFormatted {
    final duration = currentDurationMinutes;
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    return '${hours}h ${minutes}m';
  }

  // Get remaining time for target
  int get remainingMinutes {
    final targetMinutes = targetDurationHours * 60;
    final current = currentDurationMinutes;
    return (targetMinutes - current).clamp(0, targetMinutes);
  }

  // Get remaining time formatted
  String get remainingTimeFormatted {
    final remaining = remainingMinutes;
    final hours = remaining ~/ 60;
    final minutes = remaining % 60;
    return '${hours}h ${minutes}m';
  }

  // Get progress percentage
  double get progressPercentage {
    final targetMinutes = targetDurationHours * 60;
    final current = currentDurationMinutes;
    return (current / targetMinutes * 100).clamp(0.0, 100.0);
  }

  // Check if fasting is completed
  bool get isCompleted {
    return status == FastingStatus.completed ||
        currentDurationMinutes >= (targetDurationHours * 60);
  }

  // Get estimated end time
  DateTime get estimatedEndTime {
    return startTime.add(Duration(hours: targetDurationHours));
  }

  // Get actual end time or estimated
  DateTime get actualOrEstimatedEndTime {
    return endTime ?? estimatedEndTime;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'fastingType': fastingType.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'targetDurationHours': targetDurationHours,
      'actualDurationMinutes': actualDurationMinutes,
      'status': status.name,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FastingModel.fromMap(Map<String, dynamic> map, String id) {
    return FastingModel(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      fastingType: FastingType.fromName(map['fastingType'] ?? 'sixteen_eight'),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      targetDurationHours: map['targetDurationHours'] ?? 16,
      actualDurationMinutes: map['actualDurationMinutes'],
      status: FastingStatus.fromName(map['status'] ?? 'active'),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  FastingModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    FastingType? fastingType,
    DateTime? startTime,
    DateTime? endTime,
    int? targetDurationHours,
    int? actualDurationMinutes,
    FastingStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FastingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      fastingType: fastingType ?? this.fastingType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      targetDurationHours: targetDurationHours ?? this.targetDurationHours,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Fasting types with different protocols
enum FastingType {
  sixteen_eight('16:8', 16, 8, 'Fast for 16 hours, eat for 8 hours'),
  eighteen_six('18:6', 18, 6, 'Fast for 18 hours, eat for 6 hours'),
  twenty_four('24:0', 24, 0, 'Fast for 24 hours (OMAD)'),
  twenty_four_extended('36:0', 36, 0, 'Extended fast for 36 hours'),
  custom('Custom', 0, 0, 'Custom fasting schedule');

  const FastingType(
      this.displayName, this.fastHours, this.eatHours, this.description);

  final String displayName;
  final int fastHours;
  final int eatHours;
  final String description;

  static FastingType fromName(String name) {
    return FastingType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => FastingType.sixteen_eight,
    );
  }

  // Get icon for fasting type
  String get icon {
    switch (this) {
      case FastingType.sixteen_eight:
        return '⏰';
      case FastingType.eighteen_six:
        return '⏳';
      case FastingType.twenty_four:
        return '🚀';
      case FastingType.twenty_four_extended:
        return '💪';
      case FastingType.custom:
        return '⚙️';
    }
  }

  // Get difficulty level
  String get difficulty {
    switch (this) {
      case FastingType.sixteen_eight:
        return 'Beginner';
      case FastingType.eighteen_six:
        return 'Intermediate';
      case FastingType.twenty_four:
        return 'Advanced';
      case FastingType.twenty_four_extended:
        return 'Expert';
      case FastingType.custom:
        return 'Custom';
    }
  }

  // Get color for this fasting type
  String get colorHex {
    switch (this) {
      case FastingType.sixteen_eight:
        return '#4CAF50'; // Green
      case FastingType.eighteen_six:
        return '#FF9800'; // Orange
      case FastingType.twenty_four:
        return '#F44336'; // Red
      case FastingType.twenty_four_extended:
        return '#9C27B0'; // Purple
      case FastingType.custom:
        return '#2196F3'; // Blue
    }
  }
}

// Fasting status
enum FastingStatus {
  active('Active', 'Currently fasting'),
  completed('Completed', 'Fasting completed successfully'),
  broken('Broken', 'Fasting was interrupted'),
  paused('Paused', 'Fasting is temporarily paused');

  const FastingStatus(this.displayName, this.description);

  final String displayName;
  final String description;

  static FastingStatus fromName(String name) {
    return FastingStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => FastingStatus.active,
    );
  }

  // Get icon for status
  String get icon {
    switch (this) {
      case FastingStatus.active:
        return '🔥';
      case FastingStatus.completed:
        return '✅';
      case FastingStatus.broken:
        return '❌';
      case FastingStatus.paused:
        return '⏸️';
    }
  }
}

// Chart data for fasting analytics
class FastingChartData {
  final DateTime date;
  final double durationHours;
  final FastingType fastingType;
  final FastingStatus status;
  final double targetHours;

  FastingChartData({
    required this.date,
    required this.durationHours,
    required this.fastingType,
    required this.status,
    required this.targetHours,
  });

  // Calculate completion percentage
  double get completionPercentage {
    return (durationHours / targetHours * 100).clamp(0.0, 100.0);
  }
}

// Summary data for fasting analytics
class FastingSummary {
  final int totalFasts;
  final int completedFasts;
  final int activeFasts;
  final int brokenFasts;
  final double averageDurationHours;
  final double totalFastingHours;
  final double completionRate;
  final int currentStreak;
  final int longestStreak;
  final Map<FastingType, int> fastingTypeCount;
  final double averageTargetHours;

  FastingSummary({
    required this.totalFasts,
    required this.completedFasts,
    required this.activeFasts,
    required this.brokenFasts,
    required this.averageDurationHours,
    required this.totalFastingHours,
    required this.completionRate,
    required this.currentStreak,
    required this.longestStreak,
    required this.fastingTypeCount,
    required this.averageTargetHours,
  });

  // Get average duration formatted
  String get averageDurationFormatted {
    final hours = averageDurationHours.floor();
    final minutes = ((averageDurationHours - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }

  // Get total fasting hours formatted
  String get totalFastingHoursFormatted {
    final hours = totalFastingHours.floor();
    return '${hours}h';
  }

  // Get completion rate formatted
  String get completionRateFormatted {
    return '${completionRate.toStringAsFixed(1)}%';
  }

  // Get most used fasting type
  FastingType? get mostUsedFastingType {
    if (fastingTypeCount.isEmpty) return null;

    FastingType? mostUsed;
    int maxCount = 0;

    for (final entry in fastingTypeCount.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostUsed = entry.key;
      }
    }

    return mostUsed;
  }
}

// Fasting calculator utility
class FastingCalculator {
  /// Calculate optimal start time for a target end time
  static DateTime calculateStartTime({
    required DateTime targetEndTime,
    required int fastingHours,
  }) {
    return targetEndTime.subtract(Duration(hours: fastingHours));
  }

  /// Calculate estimated end time from start time and duration
  static DateTime calculateEndTime({
    required DateTime startTime,
    required int fastingHours,
  }) {
    return startTime.add(Duration(hours: fastingHours));
  }

  /// Get recommended fasting type for beginners
  static FastingType getRecommendedType({int experience = 0}) {
    if (experience == 0) {
      return FastingType.sixteen_eight;
    } else if (experience < 30) {
      return FastingType.eighteen_six;
    } else if (experience < 90) {
      return FastingType.twenty_four;
    } else {
      return FastingType.twenty_four_extended;
    }
  }

  /// Check if it's a good time to start fasting
  static bool isGoodTimeToStart(DateTime proposedStartTime) {
    final hour = proposedStartTime.hour;
    // Good times to start: after dinner (7-10 PM) or after breakfast (8-10 AM)
    return (hour >= 19 && hour <= 22) || (hour >= 8 && hour <= 10);
  }

  /// Calculate calories that could be saved during fasting
  static int estimateCaloriesSaved({
    required int fastingHours,
    required int avgCaloriesPerHour,
  }) {
    // Calculate calories saved during fasting hours
    return (fastingHours * avgCaloriesPerHour).round();
  }

  /// Get next meal time suggestion
  static DateTime getNextMealTime(DateTime fastEndTime) {
    final hour = fastEndTime.hour;

    // If fast ends in morning (6-11 AM), suggest breakfast
    if (hour >= 6 && hour <= 11) {
      return fastEndTime;
    }
    // If fast ends in afternoon (12-4 PM), suggest lunch
    else if (hour >= 12 && hour <= 16) {
      return fastEndTime;
    }
    // If fast ends in evening (5-9 PM), suggest dinner
    else if (hour >= 17 && hour <= 21) {
      return fastEndTime;
    }
    // Otherwise, suggest next meal time
    else {
      if (hour < 6) {
        // Fast ended very early, suggest breakfast at 7 AM
        return DateTime(
            fastEndTime.year, fastEndTime.month, fastEndTime.day, 7, 0);
      } else {
        // Fast ended late, suggest breakfast next day
        final nextDay = fastEndTime.add(const Duration(days: 1));
        return DateTime(nextDay.year, nextDay.month, nextDay.day, 7, 0);
      }
    }
  }
}
