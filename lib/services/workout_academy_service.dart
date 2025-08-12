import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_academy_model.dart';

class WorkoutAcademyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // CRUD Operations for Tutorials

  // Get all tutorials
  Future<List<WorkoutTutorialModel>> getAllTutorials({int? limit}) async {
    try {
      Query query = _firestore.collection('workout_tutorials');

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => WorkoutTutorialModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting tutorials: $e');
      return [];
    }
  }

  // Get tutorials by category
  Future<List<WorkoutTutorialModel>> getTutorialsByCategory(
      WorkoutCategory category,
      {int? limit}) async {
    try {
      Query query = _firestore
          .collection('workout_tutorials')
          .where('category', isEqualTo: category.name);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => WorkoutTutorialModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting tutorials by category: $e');
      return [];
    }
  }

  // Get tutorials by difficulty
  Future<List<WorkoutTutorialModel>> getTutorialsByDifficulty(
      DifficultyLevel difficulty,
      {int? limit}) async {
    try {
      Query query = _firestore
          .collection('workout_tutorials')
          .where('difficulty', isEqualTo: difficulty.name);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => WorkoutTutorialModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting tutorials by difficulty: $e');
      return [];
    }
  }

  // Search tutorials
  Future<List<WorkoutTutorialModel>> searchTutorials(String query) async {
    try {
      // Get all tutorials and filter locally since Firestore has limited text search
      final allTutorials = await getAllTutorials();

      final lowercaseQuery = query.toLowerCase();

      return allTutorials.where((tutorial) {
        return tutorial.title.toLowerCase().contains(lowercaseQuery) ||
            tutorial.description.toLowerCase().contains(lowercaseQuery) ||
            tutorial.instructor.toLowerCase().contains(lowercaseQuery) ||
            tutorial.tags
                .any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
            tutorial.muscleGroups
                .any((muscle) => muscle.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      print('Error searching tutorials: $e');
      return [];
    }
  }

  // Get tutorial by ID
  Future<WorkoutTutorialModel?> getTutorialById(String tutorialId) async {
    try {
      final doc = await _firestore
          .collection('workout_tutorials')
          .doc(tutorialId)
          .get();

      if (!doc.exists) return null;

      return WorkoutTutorialModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting tutorial by ID: $e');
      return null;
    }
  }

  // Get popular tutorials (by view count)
  Future<List<WorkoutTutorialModel>> getPopularTutorials(
      {int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('workout_tutorials')
          .orderBy('viewCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => WorkoutTutorialModel.fromMap(
              doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting popular tutorials: $e');
      return [];
    }
  }

  // Get featured tutorials (high rating)
  Future<List<WorkoutTutorialModel>> getFeaturedTutorials(
      {int limit = 8}) async {
    try {
      final querySnapshot = await _firestore
          .collection('workout_tutorials')
          .where('rating', isGreaterThanOrEqualTo: 4.0)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => WorkoutTutorialModel.fromMap(
              doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting featured tutorials: $e');
      return [];
    }
  }

  // Get tutorials by equipment
  Future<List<WorkoutTutorialModel>> getTutorialsByEquipment(
      List<String> equipment) async {
    try {
      final allTutorials = await getAllTutorials();

      return allTutorials.where((tutorial) {
        // Check if tutorial requires only the equipment user has
        return tutorial.equipmentRequired
            .every((required) => equipment.contains(required));
      }).toList();
    } catch (e) {
      print('Error getting tutorials by equipment: $e');
      return [];
    }
  }

  // Get no-equipment tutorials
  Future<List<WorkoutTutorialModel>> getNoEquipmentTutorials(
      {int? limit}) async {
    try {
      final allTutorials = await getAllTutorials(limit: limit);

      return allTutorials
          .where((tutorial) =>
              tutorial.equipmentRequired.isEmpty ||
              tutorial.equipmentRequired.every((eq) =>
                  eq.toLowerCase() == 'none' ||
                  eq.toLowerCase() == 'bodyweight'))
          .toList();
    } catch (e) {
      print('Error getting no-equipment tutorials: $e');
      return [];
    }
  }

  // Update tutorial view count
  Future<void> incrementViewCount(String tutorialId) async {
    try {
      await _firestore.collection('workout_tutorials').doc(tutorialId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // CRUD Operations for Programs

  // Get all programs
  Future<List<WorkoutProgramModel>> getAllPrograms({int? limit}) async {
    try {
      Query query = _firestore.collection('workout_programs');

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => WorkoutProgramModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting programs: $e');
      return [];
    }
  }

  // Get program by ID with tutorials
  Future<Map<String, dynamic>?> getProgramWithTutorials(
      String programId) async {
    try {
      final programDoc =
          await _firestore.collection('workout_programs').doc(programId).get();

      if (!programDoc.exists) return null;

      final program =
          WorkoutProgramModel.fromMap(programDoc.data()!, programDoc.id);

      // Get all tutorials for this program
      final tutorials = <WorkoutTutorialModel>[];
      for (final tutorialId in program.tutorialIds) {
        final tutorial = await getTutorialById(tutorialId);
        if (tutorial != null) {
          tutorials.add(tutorial);
        }
      }

      return {
        'program': program,
        'tutorials': tutorials,
      };
    } catch (e) {
      print('Error getting program with tutorials: $e');
      return null;
    }
  }

  // Get academy statistics
  Future<WorkoutAcademyStats> getAcademyStats() async {
    try {
      final tutorials = await getAllTutorials();
      final programs = await getAllPrograms();

      // Count by category
      final categoryCount = <WorkoutCategory, int>{};
      for (final category in WorkoutCategory.values) {
        categoryCount[category] =
            tutorials.where((tutorial) => tutorial.category == category).length;
      }

      // Count by difficulty
      final difficultyCount = <DifficultyLevel, int>{};
      for (final difficulty in DifficultyLevel.values) {
        difficultyCount[difficulty] = tutorials
            .where((tutorial) => tutorial.difficulty == difficulty)
            .length;
      }

      // Calculate average rating
      final totalRating =
          tutorials.fold<double>(0.0, (sum, tutorial) => sum + tutorial.rating);
      final averageRating =
          tutorials.isNotEmpty ? totalRating / tutorials.length : 0.0;

      // Calculate total view count
      final totalViews =
          tutorials.fold<int>(0, (sum, tutorial) => sum + tutorial.viewCount);

      return WorkoutAcademyStats(
        totalTutorials: tutorials.length,
        totalPrograms: programs.length,
        tutorialsByCategory: categoryCount,
        tutorialsByDifficulty: difficultyCount,
        averageRating: averageRating,
        totalViewCount: totalViews,
      );
    } catch (e) {
      print('Error getting academy stats: $e');
      return WorkoutAcademyStats(
        totalTutorials: 0,
        totalPrograms: 0,
        tutorialsByCategory: {},
        tutorialsByDifficulty: {},
        averageRating: 0.0,
        totalViewCount: 0,
      );
    }
  }

  // Generate sample data for testing
  Future<void> generateSampleAcademyData() async {
    try {
      final now = DateTime.now();
      
      // Comprehensive sample tutorials data with real YouTube videos
      final sampleTutorials = [
        // STRENGTH TRAINING CATEGORY
        WorkoutTutorialModel(
          title: "Perfect Push-Up Form",
          description: "Master the fundamental push-up with proper form and technique. Learn variations from beginner to advanced level.",
          youtubeVideoId: "R08gYyypGto", // Real fitness video
          thumbnailUrl: "https://img.youtube.com/vi/R08gYyypGto/maxresdefault.jpg",
          category: WorkoutCategory.strength,
          difficulty: DifficultyLevel.beginner,
          durationMinutes: 15,
          estimatedCalories: 75,
          equipmentRequired: [],
          muscleGroups: ["Chest", "Shoulders", "Triceps", "Core"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Starting Position",
              description: "Place hands slightly wider than shoulder-width apart, body in straight line from head to heels.",
              repetitions: 1,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Descent",
              description: "Lower body until chest nearly touches the floor, maintaining straight body line.",
              repetitions: 10,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Push Up",
              description: "Press through palms to return to starting position, exhaling as you push up.",
              repetitions: 10,
              sets: 3,
            ),
          ],
          tips: [
            "Keep your core engaged throughout the movement",
            "Don't let your hips sag or pike up",
            "Control the descent - don't drop down quickly",
            "Start with knee push-ups if regular push-ups are too difficult"
          ],
          commonMistakes: [
            "Hands too wide or too narrow",
            "Not maintaining straight body line",
            "Partial range of motion",
            "Holding breath during the exercise"
          ],
          instructor: "Athlean-X",
          rating: 4.8,
          tags: ["push-up", "bodyweight", "chest", "beginner", "form"],
          createdAt: now,
          updatedAt: now,
        ),

        WorkoutTutorialModel(
          title: "Complete Squat Tutorial",
          description: "Learn proper squat technique with step-by-step breakdown. From bodyweight to weighted squats.",
          youtubeVideoId: "YaXPRqUwItQ", // Real squat tutorial
          thumbnailUrl: "https://img.youtube.com/vi/YaXPRqUwItQ/maxresdefault.jpg",
          category: WorkoutCategory.strength,
          difficulty: DifficultyLevel.beginner,
          durationMinutes: 12,
          estimatedCalories: 60,
          equipmentRequired: [],
          muscleGroups: ["Quadriceps", "Glutes", "Hamstrings", "Core"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Foot Position",
              description: "Stand with feet shoulder-width apart, toes slightly pointed out.",
              repetitions: 1,
            ),
            WorkoutInstruction(
              step: 2,
              title: "The Descent",
              description: "Initiate by pushing hips back, then bend knees to lower down.",
              repetitions: 15,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 3,
              title: "The Rise",
              description: "Drive through heels to return to standing position.",
              repetitions: 15,
              sets: 3,
            ),
          ],
          tips: [
            "Keep your chest up throughout the movement",
            "Weight should be on your heels",
            "Knees track in line with toes",
            "Go as deep as your mobility allows"
          ],
          commonMistakes: [
            "Knees caving inward",
            "Leaning too far forward",
            "Not going deep enough",
            "Rising up on toes"
          ],
          instructor: "Jeff Nippard",
          rating: 4.9,
          tags: ["squat", "legs", "bodyweight", "form", "beginner"],
          createdAt: now,
          updatedAt: now,
        ),

        WorkoutTutorialModel(
          title: "Home Pull-Up Progression",
          description: "Build up to your first pull-up with these progression exercises you can do at home.",
          youtubeVideoId: "fO3dKSQayfg", // Real pull-up progression
          thumbnailUrl: "https://img.youtube.com/vi/fO3dKSQayfg/maxresdefault.jpg",
          category: WorkoutCategory.strength,
          difficulty: DifficultyLevel.intermediate,
          durationMinutes: 18,
          estimatedCalories: 95,
          equipmentRequired: ["Pull-up Bar", "Resistance Bands"],
          muscleGroups: ["Lats", "Biceps", "Rhomboids", "Middle Traps"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Dead Hang",
              description: "Hang from the bar with arms fully extended for time.",
              durationSeconds: 30,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Negative Pull-ups",
              description: "Jump to top position, slowly lower yourself down.",
              repetitions: 5,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Assisted Pull-ups",
              description: "Use resistance bands to assist the pulling motion.",
              repetitions: 8,
              sets: 3,
            ),
          ],
          tips: [
            "Focus on slow, controlled movements",
            "Engage your core throughout",
            "Pull your shoulder blades down and back",
            "Practice consistently for best results"
          ],
          commonMistakes: [
            "Using momentum to swing up",
            "Not engaging lats properly",
            "Gripping too wide or too narrow",
            "Rushing through the negative portion"
          ],
          instructor: "Al Kavadlo",
          rating: 4.7,
          tags: ["pull-up", "back", "progression", "intermediate", "calisthenics"],
          createdAt: now,
          updatedAt: now,
        ),

        // CARDIO CATEGORY
        WorkoutTutorialModel(
          title: "HIIT Cardio for Beginners",
          description: "High-intensity interval training that burns calories and improves cardiovascular fitness in just 20 minutes.",
          youtubeVideoId: "ml6cT4AZdqI", // Real HIIT video
          thumbnailUrl: "https://img.youtube.com/vi/ml6cT4AZdqI/maxresdefault.jpg",
          category: WorkoutCategory.hiit,
          difficulty: DifficultyLevel.beginner,
          durationMinutes: 20,
          estimatedCalories: 180,
          equipmentRequired: [],
          muscleGroups: ["Full Body", "Cardiovascular"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Warm-up",
              description: "Light jogging in place and dynamic stretching to prepare your body.",
              durationSeconds: 300,
            ),
            WorkoutInstruction(
              step: 2,
              title: "High Intensity",
              description: "Perform exercise at maximum effort for 30 seconds.",
              durationSeconds: 30,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Rest Period",
              description: "Active recovery with light movement for 30 seconds.",
              durationSeconds: 30,
            ),
            WorkoutInstruction(
              step: 4,
              title: "Repeat",
              description: "Repeat high intensity and rest cycle 8 times.",
              repetitions: 8,
            ),
          ],
          tips: [
            "Start slow and build intensity gradually",
            "Focus on form even when tired",
            "Stay hydrated throughout the workout",
            "Listen to your body and rest when needed"
          ],
          commonMistakes: [
            "Going too hard too fast",
            "Skipping the warm-up",
            "Not staying hydrated",
            "Poor form when fatigued"
          ],
          instructor: "Fitness Blender",
          rating: 4.6,
          tags: ["HIIT", "cardio", "fat-loss", "interval", "beginner"],
          createdAt: now,
          updatedAt: now,
        ),

        WorkoutTutorialModel(
          title: "Fat Burning Cardio Workout",
          description: "30-minute full-body cardio workout designed to maximize fat burning and improve endurance.",
          youtubeVideoId: "gC_L9qAHVJ8", // Real cardio workout
          thumbnailUrl: "https://img.youtube.com/vi/gC_L9qAHVJ8/maxresdefault.jpg",
          category: WorkoutCategory.cardio,
          difficulty: DifficultyLevel.intermediate,
          durationMinutes: 30,
          estimatedCalories: 250,
          equipmentRequired: [],
          muscleGroups: ["Full Body", "Cardiovascular"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Dynamic Warm-up",
              description: "Prepare your body with dynamic movements and stretches.",
              durationSeconds: 300,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Cardio Circuit",
              description: "Perform each exercise for 45 seconds with 15 seconds rest.",
              durationSeconds: 45,
              sets: 6,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Cool Down",
              description: "Gentle stretching and breathing exercises.",
              durationSeconds: 300,
            ),
          ],
          tips: [
            "Maintain proper form throughout",
            "Keep your heart rate in the fat-burning zone",
            "Modify exercises as needed",
            "Stay consistent with your breathing"
          ],
          commonMistakes: [
            "Exercising at too high intensity",
            "Neglecting proper form",
            "Not drinking enough water",
            "Skipping the cool-down"
          ],
          instructor: "Pamela Reif",
          rating: 4.8,
          tags: ["cardio", "fat-burning", "full-body", "intermediate", "no-equipment"],
          createdAt: now,
          updatedAt: now,
        ),

        // YOGA CATEGORY
        WorkoutTutorialModel(
          title: "Morning Yoga Flow",
          description: "Gentle yoga sequence to energize your body and mind for the day ahead. Perfect for beginners.",
          youtubeVideoId: "VaoV1PrYft4", // Real yoga video
          thumbnailUrl: "https://img.youtube.com/vi/VaoV1PrYft4/maxresdefault.jpg",
          category: WorkoutCategory.yoga,
          difficulty: DifficultyLevel.beginner,
          durationMinutes: 25,
          estimatedCalories: 85,
          equipmentRequired: ["Yoga Mat"],
          muscleGroups: ["Full Body", "Flexibility", "Core"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Child's Pose",
              description: "Start in child's pose to center yourself and focus on breathing.",
              durationSeconds: 60,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Cat-Cow Stretch",
              description: "Move through cat and cow poses to warm up the spine.",
              repetitions: 10,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Sun Salutation",
              description: "Flow through the classic sun salutation sequence.",
              repetitions: 3,
            ),
          ],
          tips: [
            "Focus on your breathing throughout the practice",
            "Don't force any poses - work within your range",
            "Use props if needed for support",
            "Practice on an empty stomach"
          ],
          commonMistakes: [
            "Holding breath during poses",
            "Forcing flexibility",
            "Comparing yourself to others",
            "Rushing through transitions"
          ],
          instructor: "Adriene Mishler",
          rating: 4.9,
          tags: ["yoga", "morning", "flexibility", "mindfulness", "beginner"],
          createdAt: now,
          updatedAt: now,
        ),

        WorkoutTutorialModel(
          title: "Yoga for Flexibility",
          description: "Deep stretching yoga practice to improve flexibility and release tension in tight muscles.",
          youtubeVideoId: "Yzm3fA2HhkQ", // Real flexibility yoga
          thumbnailUrl: "https://img.youtube.com/vi/Yzm3fA2HhkQ/maxresdefault.jpg",
          category: WorkoutCategory.flexibility,
          difficulty: DifficultyLevel.intermediate,
          durationMinutes: 35,
          estimatedCalories: 120,
          equipmentRequired: ["Yoga Mat", "Yoga Blocks"],
          muscleGroups: ["Hip Flexors", "Hamstrings", "Shoulders", "Spine"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Gentle Warm-up",
              description: "Begin with gentle movements to warm up the body.",
              durationSeconds: 300,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Deep Stretches",
              description: "Hold each stretch for 60-90 seconds, breathing deeply.",
              durationSeconds: 90,
              sets: 8,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Relaxation",
              description: "End with restorative poses and meditation.",
              durationSeconds: 300,
            ),
          ],
          tips: [
            "Never force a stretch",
            "Breathe deeply into each pose",
            "Use props to support your practice",
            "Hold stretches for at least 30 seconds"
          ],
          commonMistakes: [
            "Bouncing in stretches",
            "Holding your breath",
            "Comparing flexibility to others",
            "Stretching cold muscles"
          ],
          instructor: "Yin Yoga with Kassandra",
          rating: 4.7,
          tags: ["flexibility", "stretching", "yoga", "recovery", "intermediate"],
          createdAt: now,
          updatedAt: now,
        ),

        // CORE/ABS CATEGORY
        WorkoutTutorialModel(
          title: "6-Minute Abs Workout",
          description: "Intense core workout targeting all abdominal muscles. No equipment needed, just your body weight.",
          youtubeVideoId: "DHD1-2P94DI", // Real abs video
          thumbnailUrl: "https://img.youtube.com/vi/DHD1-2P94DI/maxresdefault.jpg",
          category: WorkoutCategory.strength,
          difficulty: DifficultyLevel.intermediate,
          durationMinutes: 6,
          estimatedCalories: 45,
          equipmentRequired: [],
          muscleGroups: ["Core", "Abs", "Obliques"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Bicycle Crunches",
              description: "Alternate bringing elbow to opposite knee in cycling motion.",
              durationSeconds: 45,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Plank Hold",
              description: "Hold plank position with proper form.",
              durationSeconds: 30,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Russian Twists",
              description: "Sit with feet elevated, twist torso side to side.",
              durationSeconds: 45,
            ),
          ],
          tips: [
            "Quality over quantity - focus on proper form",
            "Engage your core throughout each exercise",
            "Don't pull on your neck during crunches",
            "Breathe steadily, don't hold your breath"
          ],
          commonMistakes: [
            "Using momentum instead of muscle control",
            "Neck strain during crunches",
            "Not engaging deep core muscles",
            "Rushing through the movements"
          ],
          instructor: "Athlean-X",
          rating: 4.7,
          tags: ["abs", "core", "bodyweight", "quick", "intermediate"],
          createdAt: now,
          updatedAt: now,
        ),

        WorkoutTutorialModel(
          title: "Complete Core Strengthening",
          description: "Comprehensive core workout targeting all muscle groups for functional strength and stability.",
          youtubeVideoId: "Tz-QFUmP0vg", // Real core workout
          thumbnailUrl: "https://img.youtube.com/vi/Tz-QFUmP0vg/maxresdefault.jpg",
          category: WorkoutCategory.strength,
          difficulty: DifficultyLevel.advanced,
          durationMinutes: 15,
          estimatedCalories: 110,
          equipmentRequired: [],
          muscleGroups: ["Core", "Abs", "Obliques", "Lower Back"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Plank Variations",
              description: "Standard plank, side planks, and plank-ups.",
              durationSeconds: 60,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Dynamic Core",
              description: "Mountain climbers, dead bugs, and bird dogs.",
              repetitions: 20,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Isometric Holds",
              description: "Hollow body holds and glute bridges.",
              durationSeconds: 45,
              sets: 3,
            ),
          ],
          tips: [
            "Focus on controlling the movement",
            "Keep your spine neutral",
            "Breathe consistently throughout",
            "Progress gradually to avoid injury"
          ],
          commonMistakes: [
            "Allowing hips to sag in plank",
            "Using neck muscles instead of core",
            "Moving too quickly",
            "Not maintaining proper alignment"
          ],
          instructor: "Yoga with Adriene",
          rating: 4.8,
          tags: ["core", "strength", "functional", "advanced", "bodyweight"],
          createdAt: now,
          updatedAt: now,
        ),

        // FULL BODY WORKOUTS
        WorkoutTutorialModel(
          title: "30-Minute Full Body Strength",
          description: "Complete strength training workout targeting all major muscle groups. Perfect for home gym setup.",
          youtubeVideoId: "UBMk30rjy0o", // Real strength video
          thumbnailUrl: "https://img.youtube.com/vi/UBMk30rjy0o/maxresdefault.jpg",
          category: WorkoutCategory.strength,
          difficulty: DifficultyLevel.intermediate,
          durationMinutes: 30,
          estimatedCalories: 220,
          equipmentRequired: ["Dumbbells", "Resistance Bands"],
          muscleGroups: ["Full Body", "Legs", "Arms", "Back", "Chest"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Warm-up",
              description: "Dynamic warm-up to prepare muscles and joints.",
              durationSeconds: 300,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Compound Movements",
              description: "Squats, deadlifts, and presses targeting multiple muscle groups.",
              repetitions: 12,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Isolation Exercises",
              description: "Target specific muscle groups with focused movements.",
              repetitions: 15,
              sets: 2,
            ),
          ],
          tips: [
            "Choose weights that challenge you while maintaining form",
            "Rest 60-90 seconds between sets",
            "Progress gradually by increasing weight or reps",
            "Cool down with stretching"
          ],
          commonMistakes: [
            "Using weights that are too heavy",
            "Not warming up properly",
            "Incomplete range of motion",
            "Skipping rest periods"
          ],
          instructor: "Calisthenic Movement",
          rating: 4.5,
          tags: ["strength", "full-body", "dumbbells", "muscle-building", "intermediate"],
          createdAt: now,
          updatedAt: now,
        ),

        WorkoutTutorialModel(
          title: "No Equipment Full Body Workout",
          description: "Complete bodyweight workout that can be done anywhere. Perfect for travel or home workouts.",
          youtubeVideoId: "vc1E5CfRfos", // Real bodyweight workout
          thumbnailUrl: "https://img.youtube.com/vi/vc1E5CfRfos/maxresdefault.jpg",
          category: WorkoutCategory.bodyweight,
          difficulty: DifficultyLevel.beginner,
          durationMinutes: 25,
          estimatedCalories: 150,
          equipmentRequired: [],
          muscleGroups: ["Full Body", "Core", "Legs", "Arms"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Dynamic Warm-up",
              description: "Arm circles, leg swings, and light cardio movements.",
              durationSeconds: 300,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Upper Body Circuit",
              description: "Push-ups, pike push-ups, and tricep dips.",
              repetitions: 12,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Lower Body Circuit",
              description: "Squats, lunges, and single-leg deadlifts.",
              repetitions: 15,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 4,
              title: "Core Finisher",
              description: "Plank variations and mountain climbers.",
              durationSeconds: 30,
              sets: 3,
            ),
          ],
          tips: [
            "Focus on perfect form over speed",
            "Modify exercises as needed",
            "Take breaks when necessary",
            "Progress by increasing reps or sets"
          ],
          commonMistakes: [
            "Rushing through movements",
            "Not engaging core properly",
            "Poor alignment in exercises",
            "Skipping warm-up or cool-down"
          ],
          instructor: "FitnessBlender",
          rating: 4.6,
          tags: ["bodyweight", "full-body", "no-equipment", "beginner", "home-workout"],
          createdAt: now,
          updatedAt: now,
        ),

        // DANCE FITNESS
        WorkoutTutorialModel(
          title: "Dance Cardio Workout",
          description: "Fun and energetic dance workout that burns calories while learning simple dance moves.",
          youtubeVideoId: "6RvOlCuJgPY", // Real dance workout
          thumbnailUrl: "https://img.youtube.com/vi/6RvOlCuJgPY/maxresdefault.jpg",
          category: WorkoutCategory.dance,
          difficulty: DifficultyLevel.beginner,
          durationMinutes: 20,
          estimatedCalories: 140,
          equipmentRequired: [],
          muscleGroups: ["Full Body", "Cardiovascular"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Warm-up Dance",
              description: "Start with simple moves to warm up your body.",
              durationSeconds: 300,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Learn the Routine",
              description: "Follow along with the dance choreography.",
              durationSeconds: 900,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Full Routine",
              description: "Put it all together and dance the full routine.",
              durationSeconds: 300,
            ),
          ],
          tips: [
            "Don't worry about perfect moves - just have fun",
            "Stay hydrated throughout the workout",
            "Start slow and build up intensity",
            "Let loose and enjoy the music"
          ],
          commonMistakes: [
            "Being too focused on perfection",
            "Not moving with the music",
            "Comparing yourself to the instructor",
            "Forgetting to smile and have fun"
          ],
          instructor: "The Fitness Marshall",
          rating: 4.8,
          tags: ["dance", "cardio", "fun", "beginner", "full-body"],
          createdAt: now,
          updatedAt: now,
        ),

        // PILATES
        WorkoutTutorialModel(
          title: "Pilates for Beginners",
          description: "Introduction to Pilates focusing on core strength, posture, and controlled movements.",
          youtubeVideoId: "Hh6CYpNPQZQ", // Real Pilates workout
          thumbnailUrl: "https://img.youtube.com/vi/Hh6CYpNPQZQ/maxresdefault.jpg",
          category: WorkoutCategory.pilates,
          difficulty: DifficultyLevel.beginner,
          durationMinutes: 30,
          estimatedCalories: 100,
          equipmentRequired: ["Yoga Mat"],
          muscleGroups: ["Core", "Glutes", "Back", "Posture"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Breathing Preparation",
              description: "Learn proper Pilates breathing technique.",
              durationSeconds: 180,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Basic Movements",
              description: "Practice fundamental Pilates exercises.",
              repetitions: 10,
              sets: 2,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Flow Sequence",
              description: "Combine movements into flowing sequences.",
              repetitions: 5,
            ),
          ],
          tips: [
            "Focus on quality over quantity",
            "Engage your powerhouse (core) throughout",
            "Move with control and precision",
            "Coordinate movement with breath"
          ],
          commonMistakes: [
            "Holding breath during exercises",
            "Moving too quickly",
            "Not engaging the core properly",
            "Tensing shoulders and neck"
          ],
          instructor: "Blogilates",
          rating: 4.7,
          tags: ["pilates", "core", "posture", "beginner", "controlled"],
          createdAt: now,
          updatedAt: now,
        ),

        // CROSSFIT STYLE
        WorkoutTutorialModel(
          title: "CrossFit WOD for Beginners",
          description: "Introduction to CrossFit-style workout with functional movements and high intensity.",
          youtubeVideoId: "EoFdGkE9wLo", // Real CrossFit workout
          thumbnailUrl: "https://img.youtube.com/vi/EoFdGkE9wLo/maxresdefault.jpg",
          category: WorkoutCategory.crossfit,
          difficulty: DifficultyLevel.intermediate,
          durationMinutes: 25,
          estimatedCalories: 200,
          equipmentRequired: ["Kettlebell", "Jump Rope"],
          muscleGroups: ["Full Body", "Cardiovascular", "Functional"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Movement Prep",
              description: "Practice each movement with proper form.",
              durationSeconds: 300,
            ),
            WorkoutInstruction(
              step: 2,
              title: "WOD Execution",
              description: "Complete the workout as prescribed, scaling as needed.",
              repetitions: 21,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Cool Down",
              description: "Stretching and mobility work.",
              durationSeconds: 300,
            ),
          ],
          tips: [
            "Scale movements to your ability level",
            "Maintain good form even when tired",
            "Track your time and progress",
            "Stay hydrated throughout"
          ],
          commonMistakes: [
            "Going too heavy too soon",
            "Sacrificing form for speed",
            "Not scaling appropriately",
            "Skipping warm-up"
          ],
          instructor: "CrossFit Inc.",
          rating: 4.5,
          tags: ["crossfit", "functional", "high-intensity", "intermediate", "conditioning"],
          createdAt: now,
          updatedAt: now,
        ),

        // RUNNING/CARDIO
        WorkoutTutorialModel(
          title: "Running Technique for Beginners",
          description: "Learn proper running form and technique to improve efficiency and prevent injury.",
          youtubeVideoId: "brFHyOtTBWo", // Real running technique
          thumbnailUrl: "https://img.youtube.com/vi/brFHyOtTBWo/maxresdefault.jpg",
          category: WorkoutCategory.running,
          difficulty: DifficultyLevel.beginner,
          durationMinutes: 15,
          estimatedCalories: 80,
          equipmentRequired: ["Running Shoes"],
          muscleGroups: ["Legs", "Cardiovascular", "Core"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Posture Check",
              description: "Learn proper running posture and alignment.",
              durationSeconds: 180,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Foot Strike",
              description: "Practice proper foot landing technique.",
              durationSeconds: 300,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Cadence Practice",
              description: "Work on optimal running cadence and rhythm.",
              durationSeconds: 420,
            ),
          ],
          tips: [
            "Land on midfoot, not heel",
            "Keep your cadence around 180 steps per minute",
            "Maintain relaxed shoulders",
            "Breathe rhythmically"
          ],
          commonMistakes: [
            "Overstriding",
            "Heel striking too hard",
            "Tensing upper body",
            "Holding breath"
          ],
          instructor: "Global Triathlon Network",
          rating: 4.6,
          tags: ["running", "technique", "beginner", "form", "endurance"],
          createdAt: now,
          updatedAt: now,
        ),

        // MARTIAL ARTS
        WorkoutTutorialModel(
          title: "Basic Kickboxing Workout",
          description: "Learn fundamental kickboxing techniques while getting an excellent cardio workout.",
          youtubeVideoId: "PZZiJ9KE5Uw", // Real kickboxing workout
          thumbnailUrl: "https://img.youtube.com/vi/PZZiJ9KE5Uw/maxresdefault.jpg",
          category: WorkoutCategory.martial_arts,
          difficulty: DifficultyLevel.beginner,
          durationMinutes: 35,
          estimatedCalories: 280,
          equipmentRequired: ["Boxing Gloves"],
          muscleGroups: ["Full Body", "Cardiovascular", "Core"],
          instructions: [
            WorkoutInstruction(
              step: 1,
              title: "Basic Stance",
              description: "Learn proper fighting stance and guard position.",
              durationSeconds: 300,
            ),
            WorkoutInstruction(
              step: 2,
              title: "Punch Combinations",
              description: "Practice jab, cross, hook, and uppercut combinations.",
              repetitions: 20,
              sets: 4,
            ),
            WorkoutInstruction(
              step: 3,
              title: "Kick Techniques",
              description: "Learn front kicks, side kicks, and knee strikes.",
              repetitions: 15,
              sets: 3,
            ),
            WorkoutInstruction(
              step: 4,
              title: "Combo Workout",
              description: "Put together punch and kick combinations.",
              durationSeconds: 600,
            ),
          ],
          tips: [
            "Keep your guard up at all times",
            "Rotate your hips with punches and kicks",
            "Stay light on your feet",
            "Focus on technique before power"
          ],
          commonMistakes: [
            "Dropping hands after punching",
            "Not rotating hips",
            "Overextending kicks",
            "Tensing up too much"
          ],
          instructor: "Sean Vigue Fitness",
          rating: 4.7,
          tags: ["kickboxing", "martial-arts", "cardio", "beginner", "self-defense"],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Add tutorials to Firestore
      final batch = _firestore.batch();
      for (final tutorial in sampleTutorials) {
        final docRef = _firestore.collection('workout_tutorials').doc();
        batch.set(docRef, tutorial.toMap());
      }

      await batch.commit();
      print('Successfully generated ${sampleTutorials.length} sample workout tutorials');
    } catch (e) {
      print('Error generating sample academy data: $e');
      rethrow;
    }
  }

  // Get tutorials stream for real-time updates
  Stream<List<WorkoutTutorialModel>> getTutorialsStream({
    WorkoutCategory? category,
    DifficultyLevel? difficulty,
    int? limit,
  }) {
    try {
      Query query = _firestore.collection('workout_tutorials');

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.name);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => WorkoutTutorialModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      print('Error in tutorials stream: $e');
      return Stream.value([]);
    }
  }
}
