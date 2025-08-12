import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_model.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new meal record
  Future<String> createMeal(MealModel meal) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final docRef = await _firestore.collection('meals').add(meal.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating meal: $e');
      rethrow;
    }
  }

  // Get all meal records for current user
  Future<List<MealModel>> getMealRecords({int? limit}) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      Query query = _firestore
          .collection('meals')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) =>
              MealModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting meal records: $e');
      return [];
    }
  }

  // Get meal records for a specific date
  Future<List<MealModel>> getMealsForDate(DateTime date) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting meals for date: $e');
      return [];
    }
  }

  // Get meal records for a date range
  Future<List<MealModel>> getMealsForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting meals for date range: $e');
      return [];
    }
  }

  // Update an existing meal record
  Future<void> updateMeal(MealModel meal) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (meal.id == null) {
        throw Exception('Meal ID is required for update');
      }

      final updatedMeal = meal.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('meals')
          .doc(meal.id)
          .update(updatedMeal.toMap());
    } catch (e) {
      print('Error updating meal: $e');
      rethrow;
    }
  }

  // Delete a meal record
  Future<void> deleteMeal(String mealId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('meals').doc(mealId).delete();
    } catch (e) {
      print('Error deleting meal: $e');
      rethrow;
    }
  }

  // Get meal records with nutrition calculation
  Future<MealModel> createMealWithNutrition({
    required DateTime date,
    required String mealType,
    required String foodName,
    required double weightGrams,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate nutrition using local AI
      final nutrition = NutritionCalculator.calculateNutrition(
        foodName: foodName,
        weightGrams: weightGrams,
      );

      final meal = MealModel(
        userId: currentUserId!,
        date: date,
        mealType: mealType,
        foodName: foodName,
        weightGrams: weightGrams,
        calories: nutrition['calories']!,
        protein: nutrition['protein']!,
        carbs: nutrition['carbs']!,
        fat: nutrition['fat']!,
        fiber: nutrition['fiber']!,
        sugar: nutrition['sugar']!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mealId = await createMeal(meal);
      return meal.copyWith(id: mealId);
    } catch (e) {
      print('Error creating meal with nutrition: $e');
      rethrow;
    }
  }

  // Get chart data for a date range
  Future<List<MealChartData>> getChartData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final meals = await getMealsForDateRange(startDate, endDate);
      final Map<String, Map<String, double>> dailyData = {};

      // Group meals by date and calculate daily totals
      for (final meal in meals) {
        final dateKey = "${meal.date.year}-${meal.date.month}-${meal.date.day}";

        if (!dailyData.containsKey(dateKey)) {
          dailyData[dateKey] = {
            'calories': 0.0,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
          };
        }

        dailyData[dateKey]!['calories'] =
            dailyData[dateKey]!['calories']! + meal.calories;
        dailyData[dateKey]!['protein'] =
            dailyData[dateKey]!['protein']! + meal.protein;
        dailyData[dateKey]!['carbs'] =
            dailyData[dateKey]!['carbs']! + meal.carbs;
        dailyData[dateKey]!['fat'] = dailyData[dateKey]!['fat']! + meal.fat;
      }

      // Convert to chart data
      final List<MealChartData> chartData = [];
      for (final entry in dailyData.entries) {
        final dateParts = entry.key.split('-');
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );

        chartData.add(MealChartData(
          date: date,
          calories: entry.value['calories']!,
          protein: entry.value['protein']!,
          carbs: entry.value['carbs']!,
          fat: entry.value['fat']!,
        ));
      }

      // Sort by date
      chartData.sort((a, b) => a.date.compareTo(b.date));
      return chartData;
    } catch (e) {
      print('Error getting chart data: $e');
      return [];
    }
  }

  // Get meal summary for a date range
  Future<MealSummary> getMealSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final meals = await getMealsForDateRange(startDate, endDate);

      if (meals.isEmpty) {
        return MealSummary(
          totalMeals: 0,
          totalCalories: 0.0,
          averageCaloriesPerMeal: 0.0,
          totalProtein: 0.0,
          totalCarbs: 0.0,
          totalFat: 0.0,
          totalFiber: 0.0,
          totalSugar: 0.0,
          mealTypeCount: {},
          categoryCalories: {},
        );
      }

      // Calculate totals
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalFiber = 0;
      double totalSugar = 0;

      Map<String, int> mealTypeCount = {};
      Map<String, double> categoryCalories = {};

      for (final meal in meals) {
        totalCalories += meal.calories;
        totalProtein += meal.protein;
        totalCarbs += meal.carbs;
        totalFat += meal.fat;
        totalFiber += meal.fiber;
        totalSugar += meal.sugar;

        // Count meal types
        mealTypeCount[meal.mealType] = (mealTypeCount[meal.mealType] ?? 0) + 1;

        // Group calories by food category
        final food = FoodDatabase.findByName(meal.foodName);
        final category = food?.category ?? 'Other';
        categoryCalories[category] =
            (categoryCalories[category] ?? 0) + meal.calories;
      }

      return MealSummary(
        totalMeals: meals.length,
        totalCalories: double.parse(totalCalories.toStringAsFixed(1)),
        averageCaloriesPerMeal:
            double.parse((totalCalories / meals.length).toStringAsFixed(1)),
        totalProtein: double.parse(totalProtein.toStringAsFixed(1)),
        totalCarbs: double.parse(totalCarbs.toStringAsFixed(1)),
        totalFat: double.parse(totalFat.toStringAsFixed(1)),
        totalFiber: double.parse(totalFiber.toStringAsFixed(1)),
        totalSugar: double.parse(totalSugar.toStringAsFixed(1)),
        mealTypeCount: mealTypeCount,
        categoryCalories: categoryCalories,
      );
    } catch (e) {
      print('Error getting meal summary: $e');
      return MealSummary(
        totalMeals: 0,
        totalCalories: 0.0,
        averageCaloriesPerMeal: 0.0,
        totalProtein: 0.0,
        totalCarbs: 0.0,
        totalFat: 0.0,
        totalFiber: 0.0,
        totalSugar: 0.0,
        mealTypeCount: {},
        categoryCalories: {},
      );
    }
  }

  // Get weekly chart data (7 days)
  Future<List<MealChartData>> getWeeklyChartData() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6));
    return getChartData(startDate: startDate, endDate: endDate);
  }

  // Get monthly chart data (30 days)
  Future<List<MealChartData>> getMonthlyChartData() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 29));
    return getChartData(startDate: startDate, endDate: endDate);
  }

  // Get today's meals
  Future<List<MealModel>> getTodayMeals() async {
    return getMealsForDate(DateTime.now());
  }

  // Get today's nutrition summary
  Future<Map<String, double>> getTodayNutritionSummary() async {
    try {
      final todayMeals = await getTodayMeals();
      return NutritionCalculator.calculateDailySummary(todayMeals);
    } catch (e) {
      print('Error getting today nutrition summary: $e');
      return {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
      };
    }
  }

  // Get nutrition summary for a specific date
  Future<Map<String, double>> getNutritionSummaryForDate(DateTime date) async {
    try {
      final mealsForDate = await getMealsForDate(date);
      return NutritionCalculator.calculateDailySummary(mealsForDate);
    } catch (e) {
      print('Error getting nutrition summary for date: $e');
      return {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
      };
    }
  }

  // Search meals by food name
  Future<List<MealModel>> searchMeals(String query) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true)
          .get();

      final allMeals = querySnapshot.docs
          .map((doc) => MealModel.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by food name locally (Firestore doesn't support text search easily)
      return allMeals
          .where((meal) =>
              meal.foodName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching meals: $e');
      return [];
    }
  }

  // Get meal records stream for real-time updates
  Stream<List<MealModel>> getMealRecordsStream({int? limit}) {
    print('🍽️ Starting meal records stream for user: $currentUserId');

    if (currentUserId == null) {
      print('❌ No authenticated user, returning empty stream');
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('meals')
        .where('userId', isEqualTo: currentUserId);
    // Removed orderBy to avoid potential index issues, will sort client-side

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      print('📊 Meal query returned ${snapshot.docs.length} documents');

      try {
        final records = snapshot.docs
            .map((doc) {
              try {
                return MealModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
              } catch (e) {
                print('❌ Error parsing meal document ${doc.id}: $e');
                return null;
              }
            })
            .whereType<MealModel>()
            .toList();

        // Sort client-side to avoid index issues
        records.sort((a, b) => b.date.compareTo(a.date));

        print('✅ Successfully parsed ${records.length} meal records');

        if (records.isNotEmpty) {
          print('📋 Sample records:');
          for (int i = 0; i < records.length && i < 3; i++) {
            final meal = records[i];
            print('  ${i + 1}. ${meal.foodName} - ${meal.date}');
          }
        }

        return records;
      } catch (e) {
        print('❌ Error processing meal records: $e');
        return <MealModel>[];
      }
    }).handleError((error) {
      print('❌ Meal stream error: $error');
      return <MealModel>[];
    });
  }

  // Get today's meals stream for real-time updates
  Stream<List<MealModel>> getTodayMealsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('meals')
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MealModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Debug method to troubleshoot meal records issues
  Future<String> debugMealRecords() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('=== MEAL SERVICE DEBUG INFO ===');
      buffer.writeln('Current User ID: $currentUserId');
      buffer.writeln(
          'Authentication: ${_auth.currentUser != null ? "✅ Authenticated" : "❌ Not authenticated"}');

      if (currentUserId == null) {
        buffer.writeln('❌ No authenticated user found');
        return buffer.toString();
      }

      // Check total records count
      final allRecordsQuery = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: currentUserId)
          .get();

      buffer.writeln('Total Meal Records: ${allRecordsQuery.docs.length}');

      if (allRecordsQuery.docs.isEmpty) {
        buffer.writeln('❌ No meal records found for this user');
        buffer.writeln('💡 Try generating sample data first');
        return buffer.toString();
      }

      // Get recent records
      final recentRecords = await getMealRecords(limit: 5);
      buffer.writeln('Recent Records Retrieved: ${recentRecords.length}');

      if (recentRecords.isNotEmpty) {
        buffer.writeln('\n--- SAMPLE RECORDS ---');
        for (int i = 0; i < recentRecords.length && i < 3; i++) {
          final meal = recentRecords[i];
          buffer.writeln('${i + 1}. ${meal.foodName} - ${meal.date}');
          buffer.writeln('   Calories: ${meal.calories.toStringAsFixed(1)}');
          buffer.writeln('   User ID: ${meal.userId}');
        }
      }

      // Test today's meals
      final todayMeals = await getTodayMeals();
      buffer.writeln('\nToday\'s Meals Count: ${todayMeals.length}');

      // Check Firestore connection with simple query
      try {
        final testQuery = await _firestore
            .collection('meals')
            .where('userId', isEqualTo: currentUserId)
            .limit(1)
            .get();
        buffer.writeln('✅ Firestore connection working');
        buffer.writeln('Query returned: ${testQuery.docs.length} documents');
      } catch (e) {
        buffer.writeln('❌ Firestore query error: $e');
      }

      buffer.writeln('\n=== TROUBLESHOOTING TIPS ===');
      buffer.writeln('1. Check internet connection');
      buffer.writeln('2. Verify Firestore security rules allow read access');
      buffer
          .writeln('3. Ensure composite indexes are created for date queries');
      buffer.writeln('4. Try generating sample data if no records exist');

      return buffer.toString();
    } catch (e) {
      return 'Debug error: $e';
    }
  }

  // Check if user has any meal records
  Future<bool> hasAnyMealRecords() async {
    try {
      if (currentUserId == null) return false;

      final query = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking meal records: $e');
      return false;
    }
  }

  // Generate sample meal data for testing
  Future<void> generateSampleMealData() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if user already has data
    final hasData = await hasAnyMealRecords();
    if (hasData) {
      throw Exception(
          'User already has meal records. Clear existing data first if needed.');
    }

    final foods = [
      // Breakfast items
      {
        'name': 'Oatmeal with Berries',
        'category': 'Breakfast',
        'baseCalories': 250.0
      },
      {'name': 'Greek Yogurt', 'category': 'Breakfast', 'baseCalories': 100.0},
      {
        'name': 'Scrambled Eggs',
        'category': 'Breakfast',
        'baseCalories': 140.0
      },
      {
        'name': 'Whole Wheat Toast',
        'category': 'Breakfast',
        'baseCalories': 80.0
      },
      {'name': 'Banana', 'category': 'Breakfast', 'baseCalories': 105.0},

      // Lunch items
      {
        'name': 'Grilled Chicken Breast',
        'category': 'Lunch',
        'baseCalories': 165.0
      },
      {'name': 'Brown Rice', 'category': 'Lunch', 'baseCalories': 110.0},
      {'name': 'Mixed Vegetables', 'category': 'Lunch', 'baseCalories': 50.0},
      {'name': 'Caesar Salad', 'category': 'Lunch', 'baseCalories': 200.0},
      {'name': 'Quinoa Bowl', 'category': 'Lunch', 'baseCalories': 220.0},

      // Dinner items
      {'name': 'Grilled Salmon', 'category': 'Dinner', 'baseCalories': 206.0},
      {'name': 'Sweet Potato', 'category': 'Dinner', 'baseCalories': 112.0},
      {'name': 'Steamed Broccoli', 'category': 'Dinner', 'baseCalories': 55.0},
      {'name': 'Chicken Stir Fry', 'category': 'Dinner', 'baseCalories': 300.0},
      {
        'name': 'Pasta with Marinara',
        'category': 'Dinner',
        'baseCalories': 220.0
      },

      // Snacks
      {
        'name': 'Apple with Peanut Butter',
        'category': 'Snack',
        'baseCalories': 190.0
      },
      {'name': 'Mixed Nuts', 'category': 'Snack', 'baseCalories': 170.0},
      {'name': 'Protein Smoothie', 'category': 'Snack', 'baseCalories': 250.0},
    ];

    final now = DateTime.now();
    final meals = <MealModel>[];

    // Generate 14 days of realistic meal data
    for (int dayOffset = 0; dayOffset < 14; dayOffset++) {
      final date = now.subtract(Duration(days: dayOffset));

      // Breakfast (7-9 AM)
      final breakfastFood =
          foods.where((f) => f['category'] == 'Breakfast').toList();
      final breakfast = breakfastFood[dayOffset % breakfastFood.length];
      final breakfastTime = DateTime(date.year, date.month, date.day, 8, 0);

      meals.add(MealModel(
        userId: currentUserId!,
        date: breakfastTime,
        mealType: 'Breakfast',
        foodName: breakfast['name'] as String,
        weightGrams: (100 + (dayOffset * 5)).toDouble(), // Vary portions
        calories: (breakfast['baseCalories'] as double) *
            ((100 + (dayOffset * 5)) / 100),
        protein:
            (breakfast['baseCalories'] as double) * 0.2, // Estimated protein
        carbs: (breakfast['baseCalories'] as double) * 0.4, // Estimated carbs
        fat: (breakfast['baseCalories'] as double) * 0.15, // Estimated fat
        fiber: 5.0 + (dayOffset * 0.5),
        sugar: 10.0 + (dayOffset * 0.8),
        createdAt: breakfastTime,
        updatedAt: breakfastTime,
      ));

      // Lunch (12-2 PM)
      final lunchFood = foods.where((f) => f['category'] == 'Lunch').toList();
      final lunch = lunchFood[dayOffset % lunchFood.length];
      final lunchTime = DateTime(date.year, date.month, date.day, 13, 0);

      meals.add(MealModel(
        userId: currentUserId!,
        date: lunchTime,
        mealType: 'Lunch',
        foodName: lunch['name'] as String,
        weightGrams: (150 + (dayOffset * 8)).toDouble(),
        calories:
            (lunch['baseCalories'] as double) * ((150 + (dayOffset * 8)) / 100),
        protein: (lunch['baseCalories'] as double) * 0.25,
        carbs: (lunch['baseCalories'] as double) * 0.45,
        fat: (lunch['baseCalories'] as double) * 0.2,
        fiber: 8.0 + (dayOffset * 0.7),
        sugar: 6.0 + (dayOffset * 0.3),
        createdAt: lunchTime,
        updatedAt: lunchTime,
      ));

      // Dinner (6-8 PM)
      final dinnerFood = foods.where((f) => f['category'] == 'Dinner').toList();
      final dinner = dinnerFood[dayOffset % dinnerFood.length];
      final dinnerTime = DateTime(date.year, date.month, date.day, 19, 0);

      meals.add(MealModel(
        userId: currentUserId!,
        date: dinnerTime,
        mealType: 'Dinner',
        foodName: dinner['name'] as String,
        weightGrams: (200 + (dayOffset * 10)).toDouble(),
        calories: (dinner['baseCalories'] as double) *
            ((200 + (dayOffset * 10)) / 100),
        protein: (dinner['baseCalories'] as double) * 0.3,
        carbs: (dinner['baseCalories'] as double) * 0.35,
        fat: (dinner['baseCalories'] as double) * 0.25,
        fiber: 10.0 + (dayOffset * 1.0),
        sugar: 4.0 + (dayOffset * 0.2),
        createdAt: dinnerTime,
        updatedAt: dinnerTime,
      ));

      // Occasional snack (every other day)
      if (dayOffset % 2 == 0) {
        final snackFood = foods.where((f) => f['category'] == 'Snack').toList();
        final snack = snackFood[dayOffset % snackFood.length];
        final snackTime = DateTime(date.year, date.month, date.day, 15, 30);

        meals.add(MealModel(
          userId: currentUserId!,
          date: snackTime,
          mealType: 'Snack',
          foodName: snack['name'] as String,
          weightGrams: (50 + (dayOffset * 3)).toDouble(),
          calories: (snack['baseCalories'] as double) *
              ((50 + (dayOffset * 3)) / 100),
          protein: (snack['baseCalories'] as double) * 0.15,
          carbs: (snack['baseCalories'] as double) * 0.5,
          fat: (snack['baseCalories'] as double) * 0.3,
          fiber: 3.0 + (dayOffset * 0.3),
          sugar: 15.0 + (dayOffset * 1.0),
          createdAt: snackTime,
          updatedAt: snackTime,
        ));
      }
    }

    // Save all meals
    for (final meal in meals) {
      await createMeal(meal);
    }

    print('✅ Generated ${meals.length} sample meal records');
  }

  String _generateSampleNotes(String mealType) {
    final notes = {
      'breakfast': [
        'Great start to the day!',
        'Feeling energized',
        'Perfect portion size',
        'Added some extra fruits',
        'Quick breakfast before work',
      ],
      'lunch': [
        'Satisfying and nutritious',
        'Had this at the office',
        'Shared with colleagues',
        'Perfectly balanced meal',
        'Took time to enjoy it',
      ],
      'dinner': [
        'Cooked at home',
        'Family dinner time',
        'Tried a new recipe',
        'Restaurant quality!',
        'Comfort food evening',
      ],
      'snack': [
        'Perfect afternoon boost',
        'Healthy choice',
        'Between meetings',
        'Post-workout fuel',
        'Craving satisfied',
      ],
    };

    final mealNotes = notes[mealType] ?? ['Enjoyed this meal'];
    return mealNotes[DateTime.now().millisecond % mealNotes.length];
  }

  // ===========================================
  // CUSTOM FOODS MANAGEMENT
  // ===========================================

  // Create a new custom food
  Future<String> createCustomFood(CustomFoodItem customFood) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if food name already exists
      if (ExtendedFoodDatabase.foodExists(customFood.name)) {
        throw Exception('A food with this name already exists');
      }

      // Create custom food with proper userId
      final customFoodWithUserId = CustomFoodItem(
        id: customFood.id,
        userId: currentUserId!,
        name: customFood.name,
        brand: customFood.brand,
        description: customFood.description,
        category: customFood.category,
        caloriesPer100g: customFood.caloriesPer100g,
        proteinPer100g: customFood.proteinPer100g,
        carbsPer100g: customFood.carbsPer100g,
        fatPer100g: customFood.fatPer100g,
        fiberPer100g: customFood.fiberPer100g,
        sugarPer100g: customFood.sugarPer100g,
        createdAt: customFood.createdAt,
        updatedAt: customFood.updatedAt,
      );

      final docRef = await _firestore
          .collection('custom_foods')
          .add(customFoodWithUserId.toMap());
      print('✅ Custom food created: ${customFood.name}');

      // Refresh custom foods cache
      await _loadCustomFoods();

      return docRef.id;
    } catch (e) {
      print('❌ Error creating custom food: $e');
      rethrow;
    }
  }

  // Get all custom foods for current user
  Future<List<CustomFoodItem>> getCustomFoods() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('custom_foods')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('name')
          .get();

      final customFoods = querySnapshot.docs
          .map((doc) => CustomFoodItem.fromMap(doc.data(), doc.id))
          .toList();

      // Update the extended database cache
      ExtendedFoodDatabase.updateCustomFoods(customFoods);

      return customFoods;
    } catch (e) {
      print('❌ Error getting custom foods: $e');
      return [];
    }
  }

  // Load custom foods into ExtendedFoodDatabase cache
  Future<void> _loadCustomFoods() async {
    final customFoods = await getCustomFoods();
    print('📊 Loaded ${customFoods.length} custom foods');
    for (final food in customFoods) {
      print('  - ${food.name} (${food.category})');
    }
    ExtendedFoodDatabase.updateCustomFoods(customFoods);
  }

  // Update an existing custom food
  Future<void> updateCustomFood(CustomFoodItem customFood) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (customFood.id == null) {
        throw Exception('Custom food ID is required for update');
      }

      final updatedFood = customFood.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('custom_foods')
          .doc(customFood.id)
          .update(updatedFood.toMap());

      print('✅ Custom food updated: ${customFood.name}');

      // Refresh custom foods cache
      await _loadCustomFoods();
    } catch (e) {
      print('❌ Error updating custom food: $e');
      rethrow;
    }
  }

  // Delete a custom food
  Future<void> deleteCustomFood(String customFoodId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('custom_foods').doc(customFoodId).delete();
      print('✅ Custom food deleted');

      // Refresh custom foods cache
      await _loadCustomFoods();
    } catch (e) {
      print('❌ Error deleting custom food: $e');
      rethrow;
    }
  }

  // Search custom foods
  Future<List<CustomFoodItem>> searchCustomFoods(String query) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final allCustomFoods = await getCustomFoods();

      return allCustomFoods
          .where((food) =>
              food.name.toLowerCase().contains(query.toLowerCase()) ||
              (food.brand?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (food.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
    } catch (e) {
      print('❌ Error searching custom foods: $e');
      return [];
    }
  }

  // Get custom foods by category
  Future<List<CustomFoodItem>> getCustomFoodsByCategory(String category) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('custom_foods')
          .where('userId', isEqualTo: currentUserId)
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => CustomFoodItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error getting custom foods by category: $e');
      return [];
    }
  }

  // Initialize custom foods (call this when service starts)
  Future<void> initializeCustomFoods() async {
    await _loadCustomFoods();
  }

  // Get custom food by ID
  Future<CustomFoodItem?> getCustomFoodById(String id) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('custom_foods').doc(id).get();

      if (doc.exists && doc.data() != null) {
        final customFood = CustomFoodItem.fromMap(doc.data()!, doc.id);
        // Verify this food belongs to current user
        if (customFood.userId == currentUserId) {
          return customFood;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting custom food by ID: $e');
      return null;
    }
  }

  // Check if a custom food name is available
  Future<bool> isCustomFoodNameAvailable(String name,
      {String? excludeId}) async {
    try {
      if (currentUserId == null) return false;

      // Check against default foods
      if (FoodDatabase.findByName(name) != null) {
        return false;
      }

      // Check against existing custom foods
      final querySnapshot = await _firestore
          .collection('custom_foods')
          .where('userId', isEqualTo: currentUserId)
          .where('name', isEqualTo: name)
          .get();

      if (excludeId != null) {
        // When updating, exclude the current food from the check
        return querySnapshot.docs.isEmpty ||
            (querySnapshot.docs.length == 1 &&
                querySnapshot.docs.first.id == excludeId);
      }

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('❌ Error checking food name availability: $e');
      return false;
    }
  }

  // Generate sample custom foods for testing
  Future<void> generateSampleCustomFoods() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final sampleFoods = [
      CustomFoodItem(
        userId: currentUserId!,
        name: 'Homemade Protein Smoothie',
        category: FoodCategories.beverages,
        caloriesPer100g: 120.0,
        proteinPer100g: 15.0,
        carbsPer100g: 8.0,
        fatPer100g: 3.5,
        fiberPer100g: 2.0,
        sugarPer100g: 6.0,
        description: 'Whey protein, banana, almond milk blend',
        brand: 'Homemade',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CustomFoodItem(
        userId: currentUserId!,
        name: 'Grandmother\'s Chicken Curry',
        category: FoodCategories.custom,
        caloriesPer100g: 180.0,
        proteinPer100g: 22.0,
        carbsPer100g: 8.0,
        fatPer100g: 7.0,
        fiberPer100g: 2.5,
        sugarPer100g: 4.0,
        description: 'Traditional family recipe with coconut milk',
        brand: 'Family Recipe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CustomFoodItem(
        userId: currentUserId!,
        name: 'Local Bakery Whole Grain Bread',
        category: FoodCategories.grains,
        caloriesPer100g: 250.0,
        proteinPer100g: 9.0,
        carbsPer100g: 45.0,
        fatPer100g: 4.0,
        fiberPer100g: 8.0,
        sugarPer100g: 3.0,
        description: 'Artisan whole grain bread with seeds',
        brand: 'Local Bakery',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final food in sampleFoods) {
      try {
        await createCustomFood(food);
      } catch (e) {
        print('⚠️ Sample food already exists: ${food.name}');
      }
    }

    print('✅ Generated ${sampleFoods.length} sample custom foods');
  }
}
