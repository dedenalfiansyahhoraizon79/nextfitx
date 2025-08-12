import 'package:cloud_firestore/cloud_firestore.dart';

class WaterIntakeModel {
  final String? id;
  final String userId;
  final DateTime date;
  final int amountMl;
  final WaterType waterType;
  final DateTime timestamp;
  final DateTime createdAt;

  WaterIntakeModel({
    this.id,
    required this.userId,
    required this.date,
    required this.amountMl,
    required this.waterType,
    required this.timestamp,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'amountMl': amountMl,
      'waterType': waterType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WaterIntakeModel.fromMap(Map<String, dynamic> map, String id) {
    return WaterIntakeModel(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      amountMl: map['amountMl'] ?? 0,
      waterType: WaterType.fromName(map['waterType'] ?? 'water'),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  WaterIntakeModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? amountMl,
    WaterType? waterType,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    return WaterIntakeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      amountMl: amountMl ?? this.amountMl,
      waterType: waterType ?? this.waterType,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Water types with different values
enum WaterType {
  water('Water', '💧', 1.0, 'Plain water'),
  tea('Tea', '🍵', 0.8, 'Tea and herbal tea'),
  coffee('Coffee', '☕', 0.6, 'Coffee and espresso'),
  juice('Juice', '🧃', 0.7, 'Natural fruit juice'),
  milk('Milk', '🥛', 0.9, 'Milk and dairy drinks'),
  soda('Soda', '🥤', 0.5, 'Soft drinks and soda'),
  sports('Sports Drink', '🥤', 0.8, 'Sports and energy drinks');

  const WaterType(
      this.displayName, this.emoji, this.hydrationValue, this.description);

  final String displayName;
  final String emoji;
  final double hydrationValue; // How much it counts towards hydration (0.0-1.0)
  final String description;

  static WaterType fromName(String name) {
    return WaterType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => WaterType.water,
    );
  }

  // Calculate effective hydration amount
  int getEffectiveAmount(int originalAmount) {
    return (originalAmount * hydrationValue).round();
  }
}

// Daily water summary
class WaterSummary {
  final DateTime date;
  final int totalMl;
  final int effectiveHydrationMl;
  final int targetMl;
  final List<WaterIntakeModel> intakes;
  final int glassesConsumed; // Assuming 250ml per glass

  WaterSummary({
    required this.date,
    required this.totalMl,
    required this.effectiveHydrationMl,
    required this.targetMl,
    required this.intakes,
    required this.glassesConsumed,
  });

  // Get progress percentage
  double get progressPercentage {
    return (effectiveHydrationMl / targetMl * 100).clamp(0.0, 100.0);
  }

  // Check if target is reached
  bool get isTargetReached {
    return effectiveHydrationMl >= targetMl;
  }

  // Get remaining amount to reach target
  int get remainingMl {
    return (targetMl - effectiveHydrationMl).clamp(0, targetMl);
  }

  // Get remaining glasses needed
  int get remainingGlasses {
    return (remainingMl / 250).ceil();
  }

  // Format total amount
  String get totalFormatted {
    if (totalMl >= 1000) {
      return '${(totalMl / 1000).toStringAsFixed(1)}L';
    } else {
      return '${totalMl}ml';
    }
  }

  // Format effective hydration
  String get effectiveHydrationFormatted {
    if (effectiveHydrationMl >= 1000) {
      return '${(effectiveHydrationMl / 1000).toStringAsFixed(1)}L';
    } else {
      return '${effectiveHydrationMl}ml';
    }
  }

  // Format target
  String get targetFormatted {
    if (targetMl >= 1000) {
      return '${(targetMl / 1000).toStringAsFixed(1)}L';
    } else {
      return '${targetMl}ml';
    }
  }

  // Get most consumed water type
  WaterType? get mostConsumedType {
    if (intakes.isEmpty) return null;

    Map<WaterType, int> typeCount = {};
    for (final intake in intakes) {
      typeCount[intake.waterType] =
          (typeCount[intake.waterType] ?? 0) + intake.amountMl;
    }

    WaterType? mostConsumed;
    int maxAmount = 0;

    for (final entry in typeCount.entries) {
      if (entry.value > maxAmount) {
        maxAmount = entry.value;
        mostConsumed = entry.key;
      }
    }

    return mostConsumed;
  }

  // Get hydration status
  String get hydrationStatus {
    if (progressPercentage >= 100) {
      return 'Excellent hydration! 🎉';
    } else if (progressPercentage >= 80) {
      return 'Good hydration 👍';
    } else if (progressPercentage >= 60) {
      return 'Moderate hydration 💧';
    } else if (progressPercentage >= 40) {
      return 'Need more water 📢';
    } else {
      return 'Dehydrated - drink water! 🚨';
    }
  }
}

// Water intake calculator utility
class WaterCalculator {
  /// Calculate daily water target based on weight and activity level
  static int calculateDailyTarget({
    required double weightKg,
    int activityMinutes = 0,
    bool isPregnant = false,
    bool isBreastfeeding = false,
  }) {
    // Base calculation: 35ml per kg of body weight
    double baseTarget = weightKg * 35;

    // Add for physical activity (12ml per minute of activity)
    baseTarget += activityMinutes * 12;

    // Adjust for special conditions
    if (isPregnant) {
      baseTarget += 300; // Additional 300ml for pregnancy
    }
    if (isBreastfeeding) {
      baseTarget += 700; // Additional 700ml for breastfeeding
    }

    // Minimum 1.5L, maximum 4L
    return baseTarget.clamp(1500, 4000).round();
  }

  /// Get recommended intake based on time of day
  static List<int> getRecommendedSchedule(int dailyTargetMl) {
    // Distribute throughout the day
    final glassSize = 250;
    final totalGlasses = (dailyTargetMl / glassSize).round();

    // Recommended distribution:
    // Morning (6-10am): 30%
    // Afternoon (10am-6pm): 50%
    // Evening (6-10pm): 20%

    final morningGlasses = (totalGlasses * 0.3).round();
    final afternoonGlasses = (totalGlasses * 0.5).round();
    final eveningGlasses = totalGlasses - morningGlasses - afternoonGlasses;

    return [morningGlasses, afternoonGlasses, eveningGlasses];
  }

  /// Calculate when to drink next based on current intake
  static DateTime? getNextReminderTime(WaterSummary summary) {
    final now = DateTime.now();
    final currentHour = now.hour;

    // Don't remind between 10 PM and 6 AM
    if (currentHour >= 22 || currentHour < 6) {
      return DateTime(
          now.year, now.month, now.day + 1, 7, 0); // Next day at 7 AM
    }

    // If target reached, remind in 2 hours
    if (summary.isTargetReached) {
      return now.add(const Duration(hours: 2));
    }

    // Based on remaining amount, calculate frequency
    final remainingHours = 22 - currentHour; // Until 10 PM
    final remainingGlasses = summary.remainingGlasses;

    if (remainingGlasses <= 0) return null;

    final intervalHours = (remainingHours / remainingGlasses).clamp(0.5, 2.0);
    return now.add(Duration(minutes: (intervalHours * 60).round()));
  }

  /// Get quick add suggestions
  static List<int> getQuickAddSuggestions() {
    return [100, 200, 250, 300, 500, 750]; // Common amounts in ml
  }

  /// Calculate hydration level based on urine color (for future enhancement)
  static String getHydrationLevelFromColor(String urineColor) {
    switch (urineColor.toLowerCase()) {
      case 'pale_yellow':
      case 'light_yellow':
        return 'Well hydrated';
      case 'dark_yellow':
        return 'Mild dehydration';
      case 'amber':
      case 'orange':
        return 'Moderate dehydration';
      case 'brown':
        return 'Severe dehydration';
      default:
        return 'Unknown';
    }
  }

  /// Get water temperature recommendations
  static String getTemperatureRecommendation(int hour) {
    if (hour >= 6 && hour <= 10) {
      return 'Start with room temperature water to kickstart metabolism';
    } else if (hour >= 11 && hour <= 15) {
      return 'Cold water can help with energy and focus';
    } else if (hour >= 16 && hour <= 20) {
      return 'Room temperature water for better digestion';
    } else {
      return 'Avoid too much water before bed';
    }
  }
}
