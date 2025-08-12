import 'package:cloud_firestore/cloud_firestore.dart';

class SleepModel {
  final String? id;
  final String userId;
  final DateTime date;
  final DateTime bedtime;
  final DateTime wakeTime;
  final int durationMinutes;
  final int quality; // 1-5 scale (1=Poor, 5=Excellent)
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SleepModel({
    this.id,
    required this.userId,
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    required this.durationMinutes,
    this.quality = 3,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate duration in hours and minutes format
  String get durationFormatted {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  // Calculate duration in hours (decimal)
  double get durationHours {
    return durationMinutes / 60.0;
  }

  // Get quality text
  String get qualityText {
    switch (quality) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  // Get bedtime formatted as time string
  String get bedtimeFormatted {
    return '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}';
  }

  // Get wake time formatted as time string
  String get wakeTimeFormatted {
    return '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'bedtime': Timestamp.fromDate(bedtime),
      'wakeTime': Timestamp.fromDate(wakeTime),
      'durationMinutes': durationMinutes,
      'quality': quality,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SleepModel.fromMap(Map<String, dynamic> map, String id) {
    return SleepModel(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      bedtime: (map['bedtime'] as Timestamp).toDate(),
      wakeTime: (map['wakeTime'] as Timestamp).toDate(),
      durationMinutes: map['durationMinutes'] ?? 0,
      quality: map['quality'] ?? 3,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  SleepModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    DateTime? bedtime,
    DateTime? wakeTime,
    int? durationMinutes,
    int? quality,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Sleep quality options
class SleepQuality {
  static const int poor = 1;
  static const int fair = 2;
  static const int good = 3;
  static const int veryGood = 4;
  static const int excellent = 5;

  static const List<int> all = [poor, fair, good, veryGood, excellent];

  static String getText(int quality) {
    switch (quality) {
      case poor:
        return 'Poor';
      case fair:
        return 'Fair';
      case good:
        return 'Good';
      case veryGood:
        return 'Very Good';
      case excellent:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  static String getEmoji(int quality) {
    switch (quality) {
      case poor:
        return '😴';
      case fair:
        return '😪';
      case good:
        return '😊';
      case veryGood:
        return '😄';
      case excellent:
        return '🌟';
      default:
        return '😐';
    }
  }
}

// Sleep duration calculator
class SleepCalculator {
  /// Calculate sleep duration in minutes between bedtime and wake time
  static int calculateDuration({
    required DateTime bedtime,
    required DateTime wakeTime,
  }) {
    // Handle case where wake time is next day
    DateTime actualWakeTime = wakeTime;

    // If wake time is before bedtime, it means wake time is next day
    if (wakeTime.isBefore(bedtime)) {
      actualWakeTime = wakeTime.add(const Duration(days: 1));
    }

    final duration = actualWakeTime.difference(bedtime);
    return duration.inMinutes;
  }

  /// Get sleep quality based on duration
  static int getQualityFromDuration(int durationMinutes) {
    final hours = durationMinutes / 60.0;

    if (hours >= 7.5 && hours <= 9) {
      return SleepQuality.excellent; // Optimal sleep
    } else if (hours >= 7 && hours < 7.5) {
      return SleepQuality.veryGood; // Good sleep
    } else if (hours >= 6 && hours < 7) {
      return SleepQuality.good; // Adequate sleep
    } else if (hours >= 5 && hours < 6) {
      return SleepQuality.fair; // Poor sleep
    } else {
      return SleepQuality.poor; // Very poor sleep
    }
  }

  /// Get recommended bedtime for a target wake time and sleep duration
  static DateTime getRecommendedBedtime({
    required DateTime targetWakeTime,
    required int targetSleepHours,
  }) {
    return targetWakeTime.subtract(Duration(hours: targetSleepHours));
  }

  /// Check if sleep duration is healthy
  static bool isHealthyDuration(int durationMinutes) {
    final hours = durationMinutes / 60.0;
    return hours >= 6.5 && hours <= 9.5;
  }

  /// Get sleep efficiency (percentage of time in bed actually sleeping)
  static double calculateEfficiency({
    required int actualSleepMinutes,
    required int timeInBedMinutes,
  }) {
    if (timeInBedMinutes == 0) return 0.0;
    return (actualSleepMinutes / timeInBedMinutes) * 100;
  }
}

// Chart data for sleep analytics
class SleepChartData {
  final DateTime date;
  final double durationHours;
  final int quality;
  final DateTime bedtime;
  final DateTime wakeTime;

  SleepChartData({
    required this.date,
    required this.durationHours,
    required this.quality,
    required this.bedtime,
    required this.wakeTime,
  });
}

// Summary data for sleep analytics
class SleepSummary {
  final int totalNights;
  final double averageDurationHours;
  final double totalSleepHours;
  final double averageQuality;
  final int bestQuality;
  final int worstQuality;
  final double averageBedtimeHour; // 24-hour format
  final double averageWakeTimeHour; // 24-hour format
  final int daysWithHealthySleep; // 7-9 hours
  final double sleepConsistency; // Standard deviation of sleep times

  SleepSummary({
    required this.totalNights,
    required this.averageDurationHours,
    required this.totalSleepHours,
    required this.averageQuality,
    required this.bestQuality,
    required this.worstQuality,
    required this.averageBedtimeHour,
    required this.averageWakeTimeHour,
    required this.daysWithHealthySleep,
    required this.sleepConsistency,
  });

  // Get average bedtime as formatted string
  String get averageBedtimeFormatted {
    final hour = averageBedtimeHour.floor();
    final minute = ((averageBedtimeHour - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // Get average wake time as formatted string
  String get averageWakeTimeFormatted {
    final hour = averageWakeTimeHour.floor();
    final minute = ((averageWakeTimeHour - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // Get average duration formatted
  String get averageDurationFormatted {
    final hours = averageDurationHours.floor();
    final minutes = ((averageDurationHours - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }

  // Get sleep efficiency percentage
  double get sleepEfficiencyPercentage {
    return daysWithHealthySleep / totalNights * 100;
  }

  // Get consistency rating
  String get consistencyRating {
    if (sleepConsistency <= 0.5) {
      return 'Excellent';
    } else if (sleepConsistency <= 1.0) {
      return 'Good';
    } else if (sleepConsistency <= 1.5) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }
}
