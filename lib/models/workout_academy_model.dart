import 'package:cloud_firestore/cloud_firestore.dart';

// Individual workout tutorial/exercise
class WorkoutTutorialModel {
  final String? id;
  final String title;
  final String description;
  final String youtubeVideoId; // YouTube video ID (e.g., "dQw4w9WgXcQ")
  final String thumbnailUrl;
  final WorkoutCategory category;
  final DifficultyLevel difficulty;
  final int durationMinutes;
  final double estimatedCalories;
  final List<String> equipmentRequired;
  final List<String> muscleGroups;
  final List<WorkoutInstruction> instructions;
  final List<String> tips;
  final List<String> commonMistakes;
  final String instructor;
  final int viewCount;
  final double rating;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutTutorialModel({
    this.id,
    required this.title,
    required this.description,
    required this.youtubeVideoId,
    required this.thumbnailUrl,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.equipmentRequired,
    required this.muscleGroups,
    required this.instructions,
    required this.tips,
    required this.commonMistakes,
    required this.instructor,
    this.viewCount = 0,
    this.rating = 0.0,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get YouTube video URL
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$youtubeVideoId';

  // Get YouTube thumbnail URL
  String get youtubeThumbnail =>
      'https://img.youtube.com/vi/$youtubeVideoId/maxresdefault.jpg';

  // Get difficulty color
  String get difficultyColor {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return '#4CAF50'; // Green
      case DifficultyLevel.intermediate:
        return '#FF9800'; // Orange
      case DifficultyLevel.advanced:
        return '#F44336'; // Red
    }
  }

  // Get formatted duration
  String get durationFormatted {
    if (durationMinutes < 60) {
      return '${durationMinutes}m';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  // Get equipment summary
  String get equipmentSummary {
    if (equipmentRequired.isEmpty) return 'No equipment needed';
    if (equipmentRequired.length == 1) return equipmentRequired.first;
    if (equipmentRequired.length <= 3) return equipmentRequired.join(', ');
    return '${equipmentRequired.take(2).join(', ')} +${equipmentRequired.length - 2} more';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'youtubeVideoId': youtubeVideoId,
      'thumbnailUrl': thumbnailUrl,
      'category': category.name,
      'difficulty': difficulty.name,
      'durationMinutes': durationMinutes,
      'estimatedCalories': estimatedCalories,
      'equipmentRequired': equipmentRequired,
      'muscleGroups': muscleGroups,
      'instructions': instructions.map((inst) => inst.toMap()).toList(),
      'tips': tips,
      'commonMistakes': commonMistakes,
      'instructor': instructor,
      'viewCount': viewCount,
      'rating': rating,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WorkoutTutorialModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutTutorialModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      youtubeVideoId: map['youtubeVideoId'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      category: WorkoutCategory.fromName(map['category'] ?? 'strength'),
      difficulty: DifficultyLevel.fromName(map['difficulty'] ?? 'beginner'),
      durationMinutes: map['durationMinutes'] ?? 0,
      estimatedCalories: (map['estimatedCalories'] ?? 0.0).toDouble(),
      equipmentRequired: List<String>.from(map['equipmentRequired'] ?? []),
      muscleGroups: List<String>.from(map['muscleGroups'] ?? []),
      instructions: (map['instructions'] as List<dynamic>? ?? [])
          .map((inst) => WorkoutInstruction.fromMap(inst))
          .toList(),
      tips: List<String>.from(map['tips'] ?? []),
      commonMistakes: List<String>.from(map['commonMistakes'] ?? []),
      instructor: map['instructor'] ?? '',
      viewCount: map['viewCount'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  WorkoutTutorialModel copyWith({
    String? id,
    String? title,
    String? description,
    String? youtubeVideoId,
    String? thumbnailUrl,
    WorkoutCategory? category,
    DifficultyLevel? difficulty,
    int? durationMinutes,
    double? estimatedCalories,
    List<String>? equipmentRequired,
    List<String>? muscleGroups,
    List<WorkoutInstruction>? instructions,
    List<String>? tips,
    List<String>? commonMistakes,
    String? instructor,
    int? viewCount,
    double? rating,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutTutorialModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      equipmentRequired: equipmentRequired ?? this.equipmentRequired,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      instructions: instructions ?? this.instructions,
      tips: tips ?? this.tips,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      instructor: instructor ?? this.instructor,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Individual workout instruction step
class WorkoutInstruction {
  final int step;
  final String title;
  final String description;
  final String? imageUrl;
  final int? durationSeconds;
  final int? repetitions;
  final int? sets;

  WorkoutInstruction({
    required this.step,
    required this.title,
    required this.description,
    this.imageUrl,
    this.durationSeconds,
    this.repetitions,
    this.sets,
  });

  // Get formatted step info
  String get stepInfo {
    if (durationSeconds != null) {
      return '${durationSeconds}s';
    } else if (repetitions != null && sets != null) {
      return '${sets}x$repetitions';
    } else if (repetitions != null) {
      return '$repetitions reps';
    }
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'step': step,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'durationSeconds': durationSeconds,
      'repetitions': repetitions,
      'sets': sets,
    };
  }

  factory WorkoutInstruction.fromMap(Map<String, dynamic> map) {
    return WorkoutInstruction(
      step: map['step'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      durationSeconds: map['durationSeconds'],
      repetitions: map['repetitions'],
      sets: map['sets'],
    );
  }
}

// Workout categories
enum WorkoutCategory {
  strength('Strength Training', '💪', 'Build muscle and increase strength'),
  cardio('Cardio', '🏃‍♂️', 'Improve cardiovascular health'),
  flexibility('Flexibility', '🧘‍♀️', 'Increase flexibility and mobility'),
  yoga('Yoga', '🕉️', 'Mind-body wellness and flexibility'),
  pilates('Pilates', '🤸‍♀️', 'Core strength and body control'),
  hiit('HIIT', '⚡', 'High-intensity interval training'),
  crossfit('CrossFit', '🏋️‍♂️', 'Functional fitness and conditioning'),
  bodyweight('Bodyweight', '🤾‍♂️', 'No equipment needed exercises'),
  martial_arts('Martial Arts', '🥋', 'Self-defense and discipline'),
  dance('Dance Fitness', '💃', 'Fun cardio through dance'),
  swimming('Swimming', '🏊‍♂️', 'Full-body aquatic exercise'),
  running('Running', '🏃‍♀️', 'Endurance and speed training');

  const WorkoutCategory(this.displayName, this.icon, this.description);

  final String displayName;
  final String icon;
  final String description;

  static WorkoutCategory fromName(String name) {
    return WorkoutCategory.values.firstWhere(
      (category) => category.name == name,
      orElse: () => WorkoutCategory.strength,
    );
  }
}

// Difficulty levels
enum DifficultyLevel {
  beginner('Beginner', 1, 'Perfect for starting your fitness journey'),
  intermediate('Intermediate', 2, 'For those with some fitness experience'),
  advanced('Advanced', 3, 'Challenging workouts for experienced athletes');

  const DifficultyLevel(this.displayName, this.level, this.description);

  final String displayName;
  final int level;
  final String description;

  static DifficultyLevel fromName(String name) {
    return DifficultyLevel.values.firstWhere(
      (difficulty) => difficulty.name == name,
      orElse: () => DifficultyLevel.beginner,
    );
  }

  // Get color for difficulty
  String get colorHex {
    switch (this) {
      case DifficultyLevel.beginner:
        return '#4CAF50'; // Green
      case DifficultyLevel.intermediate:
        return '#FF9800'; // Orange
      case DifficultyLevel.advanced:
        return '#F44336'; // Red
    }
  }
}

// Workout program (collection of tutorials)
class WorkoutProgramModel {
  final String? id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final WorkoutCategory category;
  final DifficultyLevel difficulty;
  final List<String> tutorialIds; // References to WorkoutTutorialModel
  final int totalDurationMinutes;
  final double totalEstimatedCalories;
  final String instructor;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutProgramModel({
    this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.category,
    required this.difficulty,
    required this.tutorialIds,
    required this.totalDurationMinutes,
    required this.totalEstimatedCalories,
    required this.instructor,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get number of exercises
  int get exerciseCount => tutorialIds.length;

  // Get formatted duration
  String get durationFormatted {
    if (totalDurationMinutes < 60) {
      return '${totalDurationMinutes}m';
    } else {
      final hours = totalDurationMinutes ~/ 60;
      final minutes = totalDurationMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'category': category.name,
      'difficulty': difficulty.name,
      'tutorialIds': tutorialIds,
      'totalDurationMinutes': totalDurationMinutes,
      'totalEstimatedCalories': totalEstimatedCalories,
      'instructor': instructor,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WorkoutProgramModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutProgramModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      category: WorkoutCategory.fromName(map['category'] ?? 'strength'),
      difficulty: DifficultyLevel.fromName(map['difficulty'] ?? 'beginner'),
      tutorialIds: List<String>.from(map['tutorialIds'] ?? []),
      totalDurationMinutes: map['totalDurationMinutes'] ?? 0,
      totalEstimatedCalories: (map['totalEstimatedCalories'] ?? 0.0).toDouble(),
      instructor: map['instructor'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}

// Academy statistics
class WorkoutAcademyStats {
  final int totalTutorials;
  final int totalPrograms;
  final Map<WorkoutCategory, int> tutorialsByCategory;
  final Map<DifficultyLevel, int> tutorialsByDifficulty;
  final double averageRating;
  final int totalViewCount;

  WorkoutAcademyStats({
    required this.totalTutorials,
    required this.totalPrograms,
    required this.tutorialsByCategory,
    required this.tutorialsByDifficulty,
    required this.averageRating,
    required this.totalViewCount,
  });
}
