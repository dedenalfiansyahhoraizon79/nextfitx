import 'package:cloud_firestore/cloud_firestore.dart';

// Main Workout Model
class WorkoutModel {
  final String? id;
  final String userId;
  final DateTime date;
  final String workoutType;
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutModel({
    this.id,
    required this.userId,
    required this.date,
    required this.workoutType,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'workoutType': workoutType,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutModel(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      workoutType: map['workoutType'] ?? '',
      durationMinutes: (map['durationMinutes'] ?? 0).toInt(),
      caloriesBurned: (map['caloriesBurned'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  WorkoutModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? workoutType,
    int? durationMinutes,
    double? caloriesBurned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      workoutType: workoutType ?? this.workoutType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Workout Type Definition
class WorkoutType {
  final String name;
  final String category;
  final double metValue; // Metabolic Equivalent of Task
  final String icon;
  final String description;

  const WorkoutType({
    required this.name,
    required this.category,
    required this.metValue,
    required this.icon,
    required this.description,
  });
}

// Predefined Workout Types with MET values for calorie calculation
class WorkoutTypes {
  static const List<WorkoutType> cardio = [
    WorkoutType(
      name: 'Running',
      category: 'Cardio',
      metValue: 8.0,
      icon: '🏃‍♂️',
      description: 'Running at moderate pace',
    ),
    WorkoutType(
      name: 'Cycling',
      category: 'Cardio',
      metValue: 6.8,
      icon: '🚴‍♂️',
      description: 'Cycling at moderate pace',
    ),
    WorkoutType(
      name: 'Swimming',
      category: 'Cardio',
      metValue: 7.0,
      icon: '🏊‍♂️',
      description: 'Swimming laps',
    ),
    WorkoutType(
      name: 'Walking',
      category: 'Cardio',
      metValue: 3.8,
      icon: '🚶‍♂️',
      description: 'Brisk walking',
    ),
    WorkoutType(
      name: 'Jump Rope',
      category: 'Cardio',
      metValue: 11.0,
      icon: '🪀',
      description: 'Jumping rope',
    ),
    WorkoutType(
      name: 'Elliptical',
      category: 'Cardio',
      metValue: 5.0,
      icon: '⚡',
      description: 'Elliptical machine',
    ),
  ];

  static const List<WorkoutType> strength = [
    WorkoutType(
      name: 'Weight Training',
      category: 'Strength',
      metValue: 6.0,
      icon: '🏋️‍♂️',
      description: 'General weight training',
    ),
    WorkoutType(
      name: 'Push-ups',
      category: 'Strength',
      metValue: 8.0,
      icon: '💪',
      description: 'Push-up exercises',
    ),
    WorkoutType(
      name: 'Pull-ups',
      category: 'Strength',
      metValue: 8.0,
      icon: '🔴',
      description: 'Pull-up exercises',
    ),
    WorkoutType(
      name: 'Squats',
      category: 'Strength',
      metValue: 5.0,
      icon: '🦵',
      description: 'Squat exercises',
    ),
    WorkoutType(
      name: 'Deadlifts',
      category: 'Strength',
      metValue: 6.0,
      icon: '⚖️',
      description: 'Deadlift exercises',
    ),
    WorkoutType(
      name: 'Bench Press',
      category: 'Strength',
      metValue: 5.0,
      icon: '🏋️',
      description: 'Bench press exercises',
    ),
  ];

  static const List<WorkoutType> flexibility = [
    WorkoutType(
      name: 'Yoga',
      category: 'Flexibility',
      metValue: 2.5,
      icon: '🧘‍♀️',
      description: 'Yoga practice',
    ),
    WorkoutType(
      name: 'Pilates',
      category: 'Flexibility',
      metValue: 3.0,
      icon: '🤸‍♀️',
      description: 'Pilates exercises',
    ),
    WorkoutType(
      name: 'Stretching',
      category: 'Flexibility',
      metValue: 2.3,
      icon: '🤲',
      description: 'Stretching exercises',
    ),
    WorkoutType(
      name: 'Tai Chi',
      category: 'Flexibility',
      metValue: 4.0,
      icon: '☯️',
      description: 'Tai Chi practice',
    ),
  ];

  static const List<WorkoutType> sports = [
    WorkoutType(
      name: 'Basketball',
      category: 'Sports',
      metValue: 8.0,
      icon: '🏀',
      description: 'Basketball game',
    ),
    WorkoutType(
      name: 'Football',
      category: 'Sports',
      metValue: 8.0,
      icon: '⚽',
      description: 'Football/Soccer',
    ),
    WorkoutType(
      name: 'Tennis',
      category: 'Sports',
      metValue: 7.0,
      icon: '🎾',
      description: 'Tennis match',
    ),
    WorkoutType(
      name: 'Badminton',
      category: 'Sports',
      metValue: 5.5,
      icon: '🏸',
      description: 'Badminton game',
    ),
    WorkoutType(
      name: 'Volleyball',
      category: 'Sports',
      metValue: 4.0,
      icon: '🏐',
      description: 'Volleyball game',
    ),
  ];

  static const List<WorkoutType> hiit = [
    WorkoutType(
      name: 'HIIT Training',
      category: 'HIIT',
      metValue: 12.0,
      icon: '🔥',
      description: 'High-Intensity Interval Training',
    ),
    WorkoutType(
      name: 'Circuit Training',
      category: 'HIIT',
      metValue: 8.0,
      icon: '🔄',
      description: 'Circuit training workout',
    ),
    WorkoutType(
      name: 'Crossfit',
      category: 'HIIT',
      metValue: 10.0,
      icon: '💥',
      description: 'CrossFit workout',
    ),
    WorkoutType(
      name: 'Burpees',
      category: 'HIIT',
      metValue: 12.0,
      icon: '🤾‍♂️',
      description: 'Burpee exercises',
    ),
  ];

  // Get all workout types
  static List<WorkoutType> get allWorkouts {
    return [...cardio, ...strength, ...flexibility, ...sports, ...hiit];
  }

  // Get workout types by category
  static List<WorkoutType> getByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return cardio;
      case 'strength':
        return strength;
      case 'flexibility':
        return flexibility;
      case 'sports':
        return sports;
      case 'hiit':
        return hiit;
      default:
        return allWorkouts;
    }
  }

  // Find workout type by name
  static WorkoutType? findByName(String name) {
    try {
      return allWorkouts.firstWhere((workout) => workout.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get categories
  static List<String> get categories {
    return ['Cardio', 'Strength', 'Flexibility', 'Sports', 'HIIT'];
  }
}

// Chart Data Model for workout analytics
class WorkoutChartData {
  final DateTime date;
  final double value;
  final String type;

  WorkoutChartData({
    required this.date,
    required this.value,
    required this.type,
  });
}

// Workout Summary Model
class WorkoutSummary {
  final double totalCaloriesBurned;
  final int totalWorkouts;
  final int totalMinutes;
  final double averageCaloriesPerWorkout;
  final double averageDurationPerWorkout;
  final String mostFrequentWorkout;
  final int workoutsThisWeek;
  final int workoutsThisMonth;
  final DateTime? lastWorkoutDate;

  WorkoutSummary({
    required this.totalCaloriesBurned,
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.averageCaloriesPerWorkout,
    required this.averageDurationPerWorkout,
    required this.mostFrequentWorkout,
    required this.workoutsThisWeek,
    required this.workoutsThisMonth,
    this.lastWorkoutDate,
  });
}

// Local AI Calorie Calculator
class CalorieCalculator {
  // Calculate calories burned using MET formula
  // Calories = MET × weight (kg) × time (hours)
  static double calculateCalories({
    required String workoutType,
    required int durationMinutes,
    double weightKg =
        70.0, // Default weight, should be fetched from user profile
  }) {
    final workout = WorkoutTypes.findByName(workoutType);
    if (workout == null) {
      // Default MET value if workout type not found
      return durationMinutes * 0.1 * weightKg;
    }

    final durationHours = durationMinutes / 60.0;
    final calories = workout.metValue * weightKg * durationHours;

    // Round to 1 decimal place
    return double.parse(calories.toStringAsFixed(1));
  }

  // Enhanced calorie calculation with intensity factors
  static double calculateCaloriesWithIntensity({
    required String workoutType,
    required int durationMinutes,
    double weightKg = 70.0,
    double intensityMultiplier = 1.0, // 0.5-1.5 range
  }) {
    final baseCalories = calculateCalories(
      workoutType: workoutType,
      durationMinutes: durationMinutes,
      weightKg: weightKg,
    );

    return double.parse(
        (baseCalories * intensityMultiplier).toStringAsFixed(1));
  }

  // Get recommended duration for target calories
  static int getRecommendedDuration({
    required String workoutType,
    required double targetCalories,
    double weightKg = 70.0,
  }) {
    final workout = WorkoutTypes.findByName(workoutType);
    if (workout == null) return 30; // Default 30 minutes

    final hoursNeeded = targetCalories / (workout.metValue * weightKg);
    final minutesNeeded = (hoursNeeded * 60).round();

    // Ensure reasonable duration (5-180 minutes)
    return minutesNeeded.clamp(5, 180);
  }
}
