import 'package:cloud_firestore/cloud_firestore.dart';

class MealModel {
  final String? id;
  final String userId;
  final DateTime date;
  final String mealType; // breakfast, lunch, dinner, snack
  final String foodName;
  final double weightGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealModel({
    this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.foodName,
    required this.weightGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'mealType': mealType,
      'foodName': foodName,
      'weightGrams': weightGrams,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map, String id) {
    return MealModel(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      mealType: map['mealType'] ?? '',
      foodName: map['foodName'] ?? '',
      weightGrams: (map['weightGrams'] ?? 0).toDouble(),
      calories: (map['calories'] ?? 0).toDouble(),
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      fiber: (map['fiber'] ?? 0).toDouble(),
      sugar: (map['sugar'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  MealModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? mealType,
    String? foodName,
    double? weightGrams,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      weightGrams: weightGrams ?? this.weightGrams,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Food item class with nutritional information per 100g
class FoodItem {
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final double sugarPer100g;

  const FoodItem({
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
    required this.sugarPer100g,
  });
}

// Meal types
class MealTypes {
  static const String breakfast = 'Breakfast';
  static const String lunch = 'Lunch';
  static const String dinner = 'Dinner';
  static const String snack = 'Snack';

  static const List<String> all = [breakfast, lunch, dinner, snack];
}

// Food database with comprehensive nutritional information
class FoodDatabase {
  static const List<FoodItem> foods = [
    // Grains & Cereals
    FoodItem(
      name: 'Rice (White, Cooked)',
      category: 'Grains',
      caloriesPer100g: 130,
      proteinPer100g: 2.7,
      carbsPer100g: 28.2,
      fatPer100g: 0.3,
      fiberPer100g: 0.4,
      sugarPer100g: 0.1,
    ),
    FoodItem(
      name: 'Rice (Brown, Cooked)',
      category: 'Grains',
      caloriesPer100g: 112,
      proteinPer100g: 2.6,
      carbsPer100g: 22.9,
      fatPer100g: 0.9,
      fiberPer100g: 1.8,
      sugarPer100g: 0.4,
    ),
    FoodItem(
      name: 'Bread (White)',
      category: 'Grains',
      caloriesPer100g: 265,
      proteinPer100g: 9.0,
      carbsPer100g: 49.0,
      fatPer100g: 3.2,
      fiberPer100g: 2.7,
      sugarPer100g: 5.0,
    ),
    FoodItem(
      name: 'Pasta (Cooked)',
      category: 'Grains',
      caloriesPer100g: 131,
      proteinPer100g: 5.0,
      carbsPer100g: 25.0,
      fatPer100g: 1.1,
      fiberPer100g: 1.8,
      sugarPer100g: 0.6,
    ),
    FoodItem(
      name: 'Oatmeal (Cooked)',
      category: 'Grains',
      caloriesPer100g: 68,
      proteinPer100g: 2.4,
      carbsPer100g: 12.0,
      fatPer100g: 1.4,
      fiberPer100g: 1.7,
      sugarPer100g: 0.3,
    ),

    // Proteins
    FoodItem(
      name: 'Chicken Breast (Cooked)',
      category: 'Protein',
      caloriesPer100g: 165,
      proteinPer100g: 31.0,
      carbsPer100g: 0.0,
      fatPer100g: 3.6,
      fiberPer100g: 0.0,
      sugarPer100g: 0.0,
    ),
    FoodItem(
      name: 'Beef (Lean, Cooked)',
      category: 'Protein',
      caloriesPer100g: 250,
      proteinPer100g: 26.0,
      carbsPer100g: 0.0,
      fatPer100g: 15.0,
      fiberPer100g: 0.0,
      sugarPer100g: 0.0,
    ),
    FoodItem(
      name: 'Fish (Salmon, Cooked)',
      category: 'Protein',
      caloriesPer100g: 206,
      proteinPer100g: 22.0,
      carbsPer100g: 0.0,
      fatPer100g: 12.0,
      fiberPer100g: 0.0,
      sugarPer100g: 0.0,
    ),
    FoodItem(
      name: 'Eggs (Cooked)',
      category: 'Protein',
      caloriesPer100g: 155,
      proteinPer100g: 13.0,
      carbsPer100g: 1.1,
      fatPer100g: 11.0,
      fiberPer100g: 0.0,
      sugarPer100g: 1.1,
    ),
    FoodItem(
      name: 'Tofu',
      category: 'Protein',
      caloriesPer100g: 76,
      proteinPer100g: 8.0,
      carbsPer100g: 1.9,
      fatPer100g: 4.8,
      fiberPer100g: 0.3,
      sugarPer100g: 0.6,
    ),

    // Vegetables
    FoodItem(
      name: 'Broccoli (Cooked)',
      category: 'Vegetables',
      caloriesPer100g: 35,
      proteinPer100g: 2.4,
      carbsPer100g: 7.0,
      fatPer100g: 0.4,
      fiberPer100g: 3.3,
      sugarPer100g: 1.3,
    ),
    FoodItem(
      name: 'Spinach (Cooked)',
      category: 'Vegetables',
      caloriesPer100g: 23,
      proteinPer100g: 2.9,
      carbsPer100g: 3.6,
      fatPer100g: 0.3,
      fiberPer100g: 2.2,
      sugarPer100g: 0.4,
    ),
    FoodItem(
      name: 'Carrot (Cooked)',
      category: 'Vegetables',
      caloriesPer100g: 35,
      proteinPer100g: 0.8,
      carbsPer100g: 8.2,
      fatPer100g: 0.2,
      fiberPer100g: 3.0,
      sugarPer100g: 3.4,
    ),
    FoodItem(
      name: 'Potato (Boiled)',
      category: 'Vegetables',
      caloriesPer100g: 87,
      proteinPer100g: 1.9,
      carbsPer100g: 20.1,
      fatPer100g: 0.1,
      fiberPer100g: 1.8,
      sugarPer100g: 0.9,
    ),

    // Fruits
    FoodItem(
      name: 'Apple',
      category: 'Fruits',
      caloriesPer100g: 52,
      proteinPer100g: 0.3,
      carbsPer100g: 14.0,
      fatPer100g: 0.2,
      fiberPer100g: 2.4,
      sugarPer100g: 10.4,
    ),
    FoodItem(
      name: 'Banana',
      category: 'Fruits',
      caloriesPer100g: 89,
      proteinPer100g: 1.1,
      carbsPer100g: 23.0,
      fatPer100g: 0.3,
      fiberPer100g: 2.6,
      sugarPer100g: 12.2,
    ),
    FoodItem(
      name: 'Orange',
      category: 'Fruits',
      caloriesPer100g: 47,
      proteinPer100g: 0.9,
      carbsPer100g: 12.0,
      fatPer100g: 0.1,
      fiberPer100g: 2.4,
      sugarPer100g: 9.4,
    ),
    FoodItem(
      name: 'Strawberries',
      category: 'Fruits',
      caloriesPer100g: 32,
      proteinPer100g: 0.7,
      carbsPer100g: 7.7,
      fatPer100g: 0.3,
      fiberPer100g: 2.0,
      sugarPer100g: 4.9,
    ),

    // Dairy
    FoodItem(
      name: 'Milk (Whole)',
      category: 'Dairy',
      caloriesPer100g: 61,
      proteinPer100g: 3.2,
      carbsPer100g: 4.8,
      fatPer100g: 3.3,
      fiberPer100g: 0.0,
      sugarPer100g: 5.1,
    ),
    FoodItem(
      name: 'Yogurt (Plain)',
      category: 'Dairy',
      caloriesPer100g: 59,
      proteinPer100g: 10.0,
      carbsPer100g: 3.6,
      fatPer100g: 0.4,
      fiberPer100g: 0.0,
      sugarPer100g: 3.2,
    ),
    FoodItem(
      name: 'Cheese (Cheddar)',
      category: 'Dairy',
      caloriesPer100g: 402,
      proteinPer100g: 25.0,
      carbsPer100g: 1.3,
      fatPer100g: 33.0,
      fiberPer100g: 0.0,
      sugarPer100g: 0.5,
    ),

    // Nuts & Seeds
    FoodItem(
      name: 'Almonds',
      category: 'Nuts',
      caloriesPer100g: 579,
      proteinPer100g: 21.0,
      carbsPer100g: 22.0,
      fatPer100g: 50.0,
      fiberPer100g: 12.0,
      sugarPer100g: 4.4,
    ),
    FoodItem(
      name: 'Peanuts',
      category: 'Nuts',
      caloriesPer100g: 567,
      proteinPer100g: 26.0,
      carbsPer100g: 16.0,
      fatPer100g: 49.0,
      fiberPer100g: 8.5,
      sugarPer100g: 4.7,
    ),

    // Legumes
    FoodItem(
      name: 'Black Beans (Cooked)',
      category: 'Legumes',
      caloriesPer100g: 132,
      proteinPer100g: 8.9,
      carbsPer100g: 23.0,
      fatPer100g: 0.5,
      fiberPer100g: 8.7,
      sugarPer100g: 0.3,
    ),
    FoodItem(
      name: 'Chickpeas (Cooked)',
      category: 'Legumes',
      caloriesPer100g: 164,
      proteinPer100g: 8.9,
      carbsPer100g: 27.0,
      fatPer100g: 2.6,
      fiberPer100g: 7.6,
      sugarPer100g: 4.8,
    ),

    // ===========================================
    // MAKANAN INDONESIA
    // ===========================================

    // Nasi & Karbohidrat Indonesia
    FoodItem(
      name: 'Nasi Uduk',
      category: 'Indonesian Food',
      caloriesPer100g: 180,
      proteinPer100g: 3.2,
      carbsPer100g: 32.0,
      fatPer100g: 4.5,
      fiberPer100g: 0.5,
      sugarPer100g: 0.2,
    ),
    FoodItem(
      name: 'Nasi Gudeg',
      category: 'Indonesian Food',
      caloriesPer100g: 165,
      proteinPer100g: 3.0,
      carbsPer100g: 30.0,
      fatPer100g: 3.8,
      fiberPer100g: 0.6,
      sugarPer100g: 2.5,
    ),
    FoodItem(
      name: 'Ketupat',
      category: 'Indonesian Food',
      caloriesPer100g: 142,
      proteinPer100g: 2.5,
      carbsPer100g: 30.5,
      fatPer100g: 0.8,
      fiberPer100g: 0.4,
      sugarPer100g: 0.1,
    ),
    FoodItem(
      name: 'Lontong',
      category: 'Indonesian Food',
      caloriesPer100g: 138,
      proteinPer100g: 2.4,
      carbsPer100g: 29.8,
      fatPer100g: 0.7,
      fiberPer100g: 0.3,
      sugarPer100g: 0.1,
    ),
    FoodItem(
      name: 'Bubur Ayam',
      category: 'Indonesian Food',
      caloriesPer100g: 88,
      proteinPer100g: 4.2,
      carbsPer100g: 14.5,
      fatPer100g: 1.8,
      fiberPer100g: 0.5,
      sugarPer100g: 0.3,
    ),

    // Lauk Pauk Indonesia
    FoodItem(
      name: 'Rendang Daging',
      category: 'Indonesian Food',
      caloriesPer100g: 285,
      proteinPer100g: 24.5,
      carbsPer100g: 8.2,
      fatPer100g: 18.0,
      fiberPer100g: 2.1,
      sugarPer100g: 3.5,
    ),
    FoodItem(
      name: 'Ayam Goreng Kremes',
      category: 'Indonesian Food',
      caloriesPer100g: 220,
      proteinPer100g: 28.0,
      carbsPer100g: 5.0,
      fatPer100g: 9.5,
      fiberPer100g: 0.8,
      sugarPer100g: 1.2,
    ),
    FoodItem(
      name: 'Ikan Bakar Kecap',
      category: 'Indonesian Food',
      caloriesPer100g: 185,
      proteinPer100g: 26.5,
      carbsPer100g: 4.2,
      fatPer100g: 6.8,
      fiberPer100g: 0.3,
      sugarPer100g: 2.8,
    ),
    FoodItem(
      name: 'Tempe Goreng',
      category: 'Indonesian Food',
      caloriesPer100g: 165,
      proteinPer100g: 14.0,
      carbsPer100g: 8.5,
      fatPer100g: 8.2,
      fiberPer100g: 3.2,
      sugarPer100g: 1.0,
    ),
    FoodItem(
      name: 'Tahu Goreng',
      category: 'Indonesian Food',
      caloriesPer100g: 145,
      proteinPer100g: 12.5,
      carbsPer100g: 6.2,
      fatPer100g: 7.8,
      fiberPer100g: 2.1,
      sugarPer100g: 0.8,
    ),
    FoodItem(
      name: 'Sate Ayam (5 tusuk)',
      category: 'Indonesian Food',
      caloriesPer100g: 195,
      proteinPer100g: 22.0,
      carbsPer100g: 6.5,
      fatPer100g: 8.5,
      fiberPer100g: 0.5,
      sugarPer100g: 4.2,
    ),
    FoodItem(
      name: 'Pecel Lele',
      category: 'Indonesian Food',
      caloriesPer100g: 168,
      proteinPer100g: 18.5,
      carbsPer100g: 3.2,
      fatPer100g: 8.8,
      fiberPer100g: 0.4,
      sugarPer100g: 0.8,
    ),

    // Sayuran Indonesia
    FoodItem(
      name: 'Sayur Asem',
      category: 'Indonesian Food',
      caloriesPer100g: 45,
      proteinPer100g: 2.8,
      carbsPer100g: 8.5,
      fatPer100g: 0.8,
      fiberPer100g: 3.2,
      sugarPer100g: 3.5,
    ),
    FoodItem(
      name: 'Gado-gado',
      category: 'Indonesian Food',
      caloriesPer100g: 125,
      proteinPer100g: 5.5,
      carbsPer100g: 12.0,
      fatPer100g: 6.8,
      fiberPer100g: 4.2,
      sugarPer100g: 5.0,
    ),
    FoodItem(
      name: 'Karedok',
      category: 'Indonesian Food',
      caloriesPer100g: 85,
      proteinPer100g: 3.8,
      carbsPer100g: 10.5,
      fatPer100g: 3.2,
      fiberPer100g: 4.8,
      sugarPer100g: 4.2,
    ),
    FoodItem(
      name: 'Pecel',
      category: 'Indonesian Food',
      caloriesPer100g: 95,
      proteinPer100g: 4.2,
      carbsPer100g: 8.8,
      fatPer100g: 5.5,
      fiberPer100g: 3.8,
      sugarPer100g: 3.2,
    ),
    FoodItem(
      name: 'Gudeg',
      category: 'Indonesian Food',
      caloriesPer100g: 118,
      proteinPer100g: 2.5,
      carbsPer100g: 18.5,
      fatPer100g: 4.2,
      fiberPer100g: 5.2,
      sugarPer100g: 12.0,
    ),

    // Buah-buahan Tropik Indonesia
    FoodItem(
      name: 'Pisang Raja',
      category: 'Fruits',
      caloriesPer100g: 92,
      proteinPer100g: 1.2,
      carbsPer100g: 23.5,
      fatPer100g: 0.2,
      fiberPer100g: 2.8,
      sugarPer100g: 15.8,
    ),
    FoodItem(
      name: 'Mangga Harum Manis',
      category: 'Fruits',
      caloriesPer100g: 65,
      proteinPer100g: 0.8,
      carbsPer100g: 16.8,
      fatPer100g: 0.2,
      fiberPer100g: 1.8,
      sugarPer100g: 14.2,
    ),
    FoodItem(
      name: 'Pepaya',
      category: 'Fruits',
      caloriesPer100g: 43,
      proteinPer100g: 0.5,
      carbsPer100g: 11.0,
      fatPer100g: 0.3,
      fiberPer100g: 1.7,
      sugarPer100g: 7.8,
    ),
    FoodItem(
      name: 'Durian',
      category: 'Fruits',
      caloriesPer100g: 147,
      proteinPer100g: 1.5,
      carbsPer100g: 27.1,
      fatPer100g: 5.3,
      fiberPer100g: 3.8,
      sugarPer100g: 20.5,
    ),
    FoodItem(
      name: 'Rambutan',
      category: 'Fruits',
      caloriesPer100g: 68,
      proteinPer100g: 0.9,
      carbsPer100g: 16.5,
      fatPer100g: 0.2,
      fiberPer100g: 2.8,
      sugarPer100g: 13.2,
    ),
    FoodItem(
      name: 'Manggis',
      category: 'Fruits',
      caloriesPer100g: 73,
      proteinPer100g: 0.4,
      carbsPer100g: 18.0,
      fatPer100g: 0.6,
      fiberPer100g: 5.1,
      sugarPer100g: 15.6,
    ),
    FoodItem(
      name: 'Salak',
      category: 'Fruits',
      caloriesPer100g: 77,
      proteinPer100g: 0.8,
      carbsPer100g: 20.9,
      fatPer100g: 0.4,
      fiberPer100g: 4.2,
      sugarPer100g: 12.1,
    ),
    FoodItem(
      name: 'Jambu Air',
      category: 'Fruits',
      caloriesPer100g: 25,
      proteinPer100g: 0.6,
      carbsPer100g: 5.7,
      fatPer100g: 0.3,
      fiberPer100g: 5.4,
      sugarPer100g: 3.4,
    ),

    // Minuman Indonesia
    FoodItem(
      name: 'Es Teh Manis',
      category: 'Indonesian Beverages',
      caloriesPer100g: 35,
      proteinPer100g: 0.0,
      carbsPer100g: 9.0,
      fatPer100g: 0.0,
      fiberPer100g: 0.0,
      sugarPer100g: 8.8,
    ),
    FoodItem(
      name: 'Es Jeruk',
      category: 'Indonesian Beverages',
      caloriesPer100g: 42,
      proteinPer100g: 0.3,
      carbsPer100g: 10.5,
      fatPer100g: 0.1,
      fiberPer100g: 0.2,
      sugarPer100g: 9.8,
    ),
    FoodItem(
      name: 'Es Cendol',
      category: 'Indonesian Beverages',
      caloriesPer100g: 68,
      proteinPer100g: 1.2,
      carbsPer100g: 15.5,
      fatPer100g: 1.8,
      fiberPer100g: 0.8,
      sugarPer100g: 12.0,
    ),
    FoodItem(
      name: 'Es Dawet',
      category: 'Indonesian Beverages',
      caloriesPer100g: 72,
      proteinPer100g: 0.8,
      carbsPer100g: 16.8,
      fatPer100g: 1.5,
      fiberPer100g: 0.5,
      sugarPer100g: 13.2,
    ),
    FoodItem(
      name: 'Wedang Jahe',
      category: 'Indonesian Beverages',
      caloriesPer100g: 28,
      proteinPer100g: 0.1,
      carbsPer100g: 7.2,
      fatPer100g: 0.0,
      fiberPer100g: 0.1,
      sugarPer100g: 6.8,
    ),
    FoodItem(
      name: 'Bajigur',
      category: 'Indonesian Beverages',
      caloriesPer100g: 85,
      proteinPer100g: 2.8,
      carbsPer100g: 12.5,
      fatPer100g: 2.8,
      fiberPer100g: 0.3,
      sugarPer100g: 8.5,
    ),
    FoodItem(
      name: 'Bandrek',
      category: 'Indonesian Beverages',
      caloriesPer100g: 32,
      proteinPer100g: 0.2,
      carbsPer100g: 8.0,
      fatPer100g: 0.1,
      fiberPer100g: 0.2,
      sugarPer100g: 7.5,
    ),
    FoodItem(
      name: 'Jamu Beras Kencur',
      category: 'Indonesian Beverages',
      caloriesPer100g: 25,
      proteinPer100g: 0.3,
      carbsPer100g: 6.2,
      fatPer100g: 0.1,
      fiberPer100g: 0.1,
      sugarPer100g: 5.5,
    ),

    // Cemilan Indonesia
    FoodItem(
      name: 'Kerupuk Udang',
      category: 'Indonesian Snacks',
      caloriesPer100g: 448,
      proteinPer100g: 8.5,
      carbsPer100g: 68.0,
      fatPer100g: 16.2,
      fiberPer100g: 2.1,
      sugarPer100g: 1.8,
    ),
    FoodItem(
      name: 'Emping Melinjo',
      category: 'Indonesian Snacks',
      caloriesPer100g: 465,
      proteinPer100g: 14.8,
      carbsPer100g: 55.2,
      fatPer100g: 20.8,
      fiberPer100g: 8.5,
      sugarPer100g: 2.2,
    ),
    FoodItem(
      name: 'Kacang Tanah Sangrai',
      category: 'Indonesian Snacks',
      caloriesPer100g: 585,
      proteinPer100g: 24.5,
      carbsPer100g: 18.2,
      fatPer100g: 48.8,
      fiberPer100g: 8.2,
      sugarPer100g: 3.8,
    ),
    FoodItem(
      name: 'Rempeyek',
      category: 'Indonesian Snacks',
      caloriesPer100g: 425,
      proteinPer100g: 12.5,
      carbsPer100g: 42.0,
      fatPer100g: 22.8,
      fiberPer100g: 4.2,
      sugarPer100g: 2.5,
    ),
    FoodItem(
      name: 'Pisang Goreng',
      category: 'Indonesian Snacks',
      caloriesPer100g: 188,
      proteinPer100g: 2.8,
      carbsPer100g: 32.5,
      fatPer100g: 6.2,
      fiberPer100g: 2.8,
      sugarPer100g: 18.5,
    ),
    FoodItem(
      name: 'Klepon',
      category: 'Indonesian Snacks',
      caloriesPer100g: 165,
      proteinPer100g: 2.2,
      carbsPer100g: 28.5,
      fatPer100g: 5.8,
      fiberPer100g: 1.8,
      sugarPer100g: 15.2,
    ),
    FoodItem(
      name: 'Onde-onde',
      category: 'Indonesian Snacks',
      caloriesPer100g: 172,
      proteinPer100g: 3.5,
      carbsPer100g: 26.8,
      fatPer100g: 6.2,
      fiberPer100g: 2.1,
      sugarPer100g: 12.5,
    ),

    // Masakan Berkuah Indonesia
    FoodItem(
      name: 'Soto Ayam',
      category: 'Indonesian Food',
      caloriesPer100g: 65,
      proteinPer100g: 8.5,
      carbsPer100g: 4.2,
      fatPer100g: 2.8,
      fiberPer100g: 0.8,
      sugarPer100g: 1.5,
    ),
    FoodItem(
      name: 'Rawon',
      category: 'Indonesian Food',
      caloriesPer100g: 88,
      proteinPer100g: 9.8,
      carbsPer100g: 5.5,
      fatPer100g: 3.8,
      fiberPer100g: 1.2,
      sugarPer100g: 2.1,
    ),
    FoodItem(
      name: 'Gule Kambing',
      category: 'Indonesian Food',
      caloriesPer100g: 155,
      proteinPer100g: 18.5,
      carbsPer100g: 6.8,
      fatPer100g: 6.5,
      fiberPer100g: 1.5,
      sugarPer100g: 3.2,
    ),
    FoodItem(
      name: 'Sayur Lodeh',
      category: 'Indonesian Food',
      caloriesPer100g: 55,
      proteinPer100g: 2.8,
      carbsPer100g: 7.5,
      fatPer100g: 2.2,
      fiberPer100g: 2.8,
      sugarPer100g: 3.5,
    ),

    // Nasi Campur & Hidangan Lengkap
    FoodItem(
      name: 'Nasi Padang',
      category: 'Indonesian Food',
      caloriesPer100g: 195,
      proteinPer100g: 8.5,
      carbsPer100g: 28.0,
      fatPer100g: 6.8,
      fiberPer100g: 1.8,
      sugarPer100g: 2.5,
    ),
    FoodItem(
      name: 'Nasi Rames',
      category: 'Indonesian Food',
      caloriesPer100g: 175,
      proteinPer100g: 6.8,
      carbsPer100g: 26.5,
      fatPer100g: 5.2,
      fiberPer100g: 2.2,
      sugarPer100g: 2.8,
    ),
    FoodItem(
      name: 'Nasi Liwet',
      category: 'Indonesian Food',
      caloriesPer100g: 168,
      proteinPer100g: 3.8,
      carbsPer100g: 32.0,
      fatPer100g: 3.2,
      fiberPer100g: 0.8,
      sugarPer100g: 1.5,
    ),

    // Makanan Penutup Indonesia
    FoodItem(
      name: 'Es Campur',
      category: 'Indonesian Desserts',
      caloriesPer100g: 95,
      proteinPer100g: 2.2,
      carbsPer100g: 20.5,
      fatPer100g: 1.8,
      fiberPer100g: 2.1,
      sugarPer100g: 16.5,
    ),
    FoodItem(
      name: 'Kolak Pisang',
      category: 'Indonesian Desserts',
      caloriesPer100g: 125,
      proteinPer100g: 2.5,
      carbsPer100g: 25.8,
      fatPer100g: 2.8,
      fiberPer100g: 2.2,
      sugarPer100g: 18.5,
    ),
    FoodItem(
      name: 'Bubur Sumsum',
      category: 'Indonesian Desserts',
      caloriesPer100g: 88,
      proteinPer100g: 1.8,
      carbsPer100g: 18.5,
      fatPer100g: 1.5,
      fiberPer100g: 0.5,
      sugarPer100g: 12.0,
    ),
    FoodItem(
      name: 'Kue Lapis',
      category: 'Indonesian Desserts',
      caloriesPer100g: 185,
      proteinPer100g: 4.2,
      carbsPer100g: 32.5,
      fatPer100g: 4.8,
      fiberPer100g: 1.2,
      sugarPer100g: 18.8,
    ),
  ];

  static List<FoodItem> getFoodsByCategory(String category) {
    return foods.where((food) => food.category == category).toList();
  }

  static List<String> getCategories() {
    return foods.map((food) => food.category).toSet().toList()..sort();
  }

  static FoodItem? findByName(String name) {
    try {
      return foods.firstWhere((food) => food.name == name);
    } catch (e) {
      return null;
    }
  }

  static List<FoodItem> searchFoods(String query) {
    return foods
        .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

// Local AI Nutrition Calculator
class NutritionCalculator {
  /// Calculate nutrition values based on food item and weight
  static Map<String, double> calculateNutrition({
    required String foodName,
    required double weightGrams,
  }) {
    final food = FoodDatabase.findByName(foodName);
    if (food == null) {
      // Fallback values for unknown foods
      return {
        'calories': weightGrams * 2.0, // 200 kcal per 100g fallback
        'protein': weightGrams * 0.1, // 10g protein per 100g fallback
        'carbs': weightGrams * 0.3, // 30g carbs per 100g fallback
        'fat': weightGrams * 0.05, // 5g fat per 100g fallback
        'fiber': weightGrams * 0.02, // 2g fiber per 100g fallback
        'sugar': weightGrams * 0.1, // 10g sugar per 100g fallback
      };
    }

    // Calculate based on weight ratio (per 100g to actual grams)
    final ratio = weightGrams / 100.0;

    return {
      'calories':
          double.parse((food.caloriesPer100g * ratio).toStringAsFixed(1)),
      'protein': double.parse((food.proteinPer100g * ratio).toStringAsFixed(1)),
      'carbs': double.parse((food.carbsPer100g * ratio).toStringAsFixed(1)),
      'fat': double.parse((food.fatPer100g * ratio).toStringAsFixed(1)),
      'fiber': double.parse((food.fiberPer100g * ratio).toStringAsFixed(1)),
      'sugar': double.parse((food.sugarPer100g * ratio).toStringAsFixed(1)),
    };
  }

  /// Get recommended portion size for a food item
  static double getRecommendedPortion(String foodName) {
    final food = FoodDatabase.findByName(foodName);
    if (food == null) return 100.0;

    // Recommended portions based on food category
    switch (food.category) {
      case 'Grains':
        return 150.0; // 150g cooked grains
      case 'Protein':
        return 100.0; // 100g protein
      case 'Vegetables':
        return 200.0; // 200g vegetables
      case 'Fruits':
        return 150.0; // 150g fruits
      case 'Dairy':
        return 200.0; // 200ml dairy
      case 'Nuts':
        return 30.0; // 30g nuts
      case 'Legumes':
        return 150.0; // 150g cooked legumes
      default:
        return 100.0;
    }
  }

  /// Calculate daily nutrition summary from meals
  static Map<String, double> calculateDailySummary(List<MealModel> meals) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;

    for (final meal in meals) {
      totalCalories += meal.calories;
      totalProtein += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
      totalFiber += meal.fiber;
      totalSugar += meal.sugar;
    }

    return {
      'calories': double.parse(totalCalories.toStringAsFixed(1)),
      'protein': double.parse(totalProtein.toStringAsFixed(1)),
      'carbs': double.parse(totalCarbs.toStringAsFixed(1)),
      'fat': double.parse(totalFat.toStringAsFixed(1)),
      'fiber': double.parse(totalFiber.toStringAsFixed(1)),
      'sugar': double.parse(totalSugar.toStringAsFixed(1)),
    };
  }
}

// Chart data for meal analytics
class MealChartData {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  MealChartData({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

// Summary data for meal analytics
class MealSummary {
  final int totalMeals;
  final double totalCalories;
  final double averageCaloriesPerMeal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double totalSugar;
  final Map<String, int> mealTypeCount;
  final Map<String, double> categoryCalories;

  MealSummary({
    required this.totalMeals,
    required this.totalCalories,
    required this.averageCaloriesPerMeal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSugar,
    required this.mealTypeCount,
    required this.categoryCalories,
  });
}

// Custom food item that can be saved to Firestore
class CustomFoodItem {
  final String? id;
  final String userId;
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final double sugarPer100g;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? brand;

  CustomFoodItem({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
    required this.sugarPer100g,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.brand,
  });

  // Convert to FoodItem for unified usage
  FoodItem toFoodItem() {
    return FoodItem(
      name: name,
      category: category,
      caloriesPer100g: caloriesPer100g,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      fiberPer100g: fiberPer100g,
      sugarPer100g: sugarPer100g,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'carbsPer100g': carbsPer100g,
      'fatPer100g': fatPer100g,
      'fiberPer100g': fiberPer100g,
      'sugarPer100g': sugarPer100g,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
      'brand': brand,
    };
  }

  static CustomFoodItem fromMap(Map<String, dynamic> map, String id) {
    return CustomFoodItem(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      caloriesPer100g: (map['caloriesPer100g'] ?? 0).toDouble(),
      proteinPer100g: (map['proteinPer100g'] ?? 0).toDouble(),
      carbsPer100g: (map['carbsPer100g'] ?? 0).toDouble(),
      fatPer100g: (map['fatPer100g'] ?? 0).toDouble(),
      fiberPer100g: (map['fiberPer100g'] ?? 0).toDouble(),
      sugarPer100g: (map['sugarPer100g'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      description: map['description'],
      brand: map['brand'],
    );
  }

  CustomFoodItem copyWith({
    String? name,
    String? category,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? fiberPer100g,
    double? sugarPer100g,
    DateTime? updatedAt,
    String? description,
    String? brand,
  }) {
    return CustomFoodItem(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      sugarPer100g: sugarPer100g ?? this.sugarPer100g,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      brand: brand ?? this.brand,
    );
  }
}

// Extended food database that includes custom foods
class ExtendedFoodDatabase {
  static List<CustomFoodItem> customFoods = [];

  // Get all foods (default + custom) by category
  static List<FoodItem> getAllFoodsByCategory(String category) {
    final defaultFoods = FoodDatabase.getFoodsByCategory(category);
    final customFoodsInCategory = customFoods
        .where((cf) => cf.category == category)
        .map((cf) => cf.toFoodItem())
        .toList();

    return [...defaultFoods, ...customFoodsInCategory];
  }

  // Get all categories (including custom food categories)
  static List<String> getAllCategories() {
    final defaultCategories = FoodDatabase.getCategories();
    final customCategories =
        customFoods.map((cf) => cf.category).toSet().toList();

    return {...defaultCategories, ...customCategories}.toList()..sort();
  }

  // Search foods (default + custom)
  static List<FoodItem> searchAllFoods(String query) {
    final defaultResults = FoodDatabase.searchFoods(query);
    final customResults = customFoods
        .where((cf) => cf.name.toLowerCase().contains(query.toLowerCase()))
        .map((cf) => cf.toFoodItem())
        .toList();

    return [...defaultResults, ...customResults];
  }

  // Find food by name (default + custom)
  static FoodItem? findByName(String name) {
    // Try default foods first
    final defaultFood = FoodDatabase.findByName(name);
    if (defaultFood != null) return defaultFood;

    // Try custom foods
    final customFood = customFoods
        .where((cf) => cf.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;

    return customFood?.toFoodItem();
  }

  // Check if a food name already exists
  static bool foodExists(String name) {
    return findByName(name) != null;
  }

  // Update custom foods list (called from service)
  static void updateCustomFoods(List<CustomFoodItem> foods) {
    customFoods = foods;
    print('🔄 ExtendedFoodDatabase updated with ${foods.length} custom foods');
  }
}

// Food categories for custom foods
class FoodCategories {
  static const String grains = 'Grains & Cereals';
  static const String proteins = 'Proteins';
  static const String dairy = 'Dairy & Eggs';
  static const String fruits = 'Fruits';
  static const String vegetables = 'Vegetables';
  static const String nuts = 'Nuts & Seeds';
  static const String beverages = 'Beverages';
  static const String sweets = 'Sweets & Desserts';
  static const String fastFood = 'Fast Food';
  static const String snacks = 'Snacks';
  static const String custom = 'Custom Foods';

  static const List<String> all = [
    grains,
    proteins,
    dairy,
    fruits,
    vegetables,
    nuts,
    beverages,
    sweets,
    fastFood,
    snacks,
    custom,
  ];
}
