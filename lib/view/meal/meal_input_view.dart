import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/meal_model.dart';
import '../../services/meal_service.dart';
import 'custom_food_input_view.dart';

class MealInputView extends StatefulWidget {
  final MealModel? existingMeal;

  const MealInputView({super.key, this.existingMeal});

  @override
  State<MealInputView> createState() => _MealInputViewState();
}

class _MealInputViewState extends State<MealInputView> {
  final _formKey = GlobalKey<FormState>();
  final MealService _mealService = MealService();

  // Form controllers
  final _weightController = TextEditingController();

  // Form data
  DateTime _selectedDate = DateTime.now();
  String _selectedMealType = MealTypes.breakfast;
  String? _selectedCategory;
  String? _selectedFood;

  // Calculated nutrition
  Map<String, double> _calculatedNutrition = {};

  // UI state
  bool _isLoading = false;
  bool _isEditing = false;

  // Food selection
  List<String> _categories = [];
  List<FoodItem> _categoryFoods = [];

  @override
  void initState() {
    super.initState();
    _initializeData();

    if (widget.existingMeal != null) {
      _isEditing = true;
      _populateExistingMeal();
    }

    _weightController.addListener(_updateNutritionPreview);
  }

  Future<void> _initializeData() async {
    // Initialize custom foods first
    await _mealService.initializeCustomFoods();
    _loadCategories();
    print(
        '🍽️ Meal input view initialized with ${_categories.length} categories');
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _loadCategories() {
    setState(() {
      _categories = ExtendedFoodDatabase.getAllCategories();
      print(
          '📋 Loaded ${_categories.length} categories: ${_categories.join(', ')}');
    });
  }

  void _populateExistingMeal() {
    final meal = widget.existingMeal!;
    setState(() {
      _selectedDate = meal.date;
      _selectedMealType = meal.mealType;
      _selectedFood = meal.foodName;
      _weightController.text = meal.weightGrams.toStringAsFixed(0);

      // Find category for the food
      final food = ExtendedFoodDatabase.findByName(meal.foodName);
      if (food != null) {
        _selectedCategory = food.category;
        _categoryFoods =
            ExtendedFoodDatabase.getAllFoodsByCategory(food.category);
      }

      _calculatedNutrition = {
        'calories': meal.calories,
        'protein': meal.protein,
        'carbs': meal.carbs,
        'fat': meal.fat,
        'fiber': meal.fiber,
        'sugar': meal.sugar,
      };
    });
  }

  void _updateNutritionPreview() {
    if (_selectedFood != null && _weightController.text.isNotEmpty) {
      final weight = double.tryParse(_weightController.text);
      if (weight != null && weight > 0) {
        final nutrition = NutritionCalculator.calculateNutrition(
          foodName: _selectedFood!,
          weightGrams: weight,
        );
        setState(() {
          _calculatedNutrition = nutrition;
        });
      }
    } else {
      setState(() {
        _calculatedNutrition = {};
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primaryColor1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a food item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final weight = double.parse(_weightController.text);

      if (_isEditing) {
        // Update existing meal
        final nutrition = NutritionCalculator.calculateNutrition(
          foodName: _selectedFood!,
          weightGrams: weight,
        );

        final updatedMeal = widget.existingMeal!.copyWith(
          date: _selectedDate,
          mealType: _selectedMealType,
          foodName: _selectedFood!,
          weightGrams: weight,
          calories: nutrition['calories']!,
          protein: nutrition['protein']!,
          carbs: nutrition['carbs']!,
          fat: nutrition['fat']!,
          fiber: nutrition['fiber']!,
          sugar: nutrition['sugar']!,
          updatedAt: DateTime.now(),
        );

        await _mealService.updateMeal(updatedMeal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Meal updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new meal
        await _mealService.createMealWithNutrition(
          date: _selectedDate,
          mealType: _selectedMealType,
          foodName: _selectedFood!,
          weightGrams: weight,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Meal recorded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/ArrowLeft.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          _isEditing ? "Edit Meal" : "Add Meal",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Selection
              Text(
                "Date",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: TColor.gray.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: TColor.gray,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Meal Type Selection
              Text(
                "Meal Type",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: TColor.gray.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMealType,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: TColor.gray),
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMealType = newValue;
                        });
                      }
                    },
                    items: MealTypes.all
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              _getMealIcon(value),
                              color: TColor.primaryColor1,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(value),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Food Category Selection
              Text(
                "Food Category",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: TColor.gray.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: TColor.gray),
                    hint: Text(
                      'Select category',
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 14,
                      ),
                    ),
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                          _selectedFood = null;
                          _categoryFoods =
                              ExtendedFoodDatabase.getAllFoodsByCategory(
                                  newValue);
                          print(
                              '🍎 Category "$newValue" has ${_categoryFoods.length} foods');
                          _calculatedNutrition = {};
                        });
                      }
                    },
                    items: _categories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (_selectedCategory != null) ...[
                const SizedBox(height: 25),

                // Food Selection
                Text(
                  "Food Item",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: TColor.gray.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFood,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: TColor.gray),
                      hint: Text(
                        'Select food',
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 14,
                        ),
                      ),
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedFood = newValue;
                            // Set recommended portion if weight is empty
                            if (_weightController.text.isEmpty) {
                              final recommendedWeight =
                                  NutritionCalculator.getRecommendedPortion(
                                      newValue);
                              _weightController.text =
                                  recommendedWeight.toStringAsFixed(0);
                            }
                            _updateNutritionPreview();
                          });
                        }
                      },
                      items: _categoryFoods
                          .map<DropdownMenuItem<String>>((FoodItem food) {
                        return DropdownMenuItem<String>(
                          value: food.name,
                          child: Text(food.name),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Create Custom Food Button
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _createCustomFood(),
                    icon: Icon(Icons.add_circle_outline, size: 18),
                    label: Text("Create Custom Food"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TColor.primaryColor1,
                      side: BorderSide(color: TColor.primaryColor1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],

              if (_selectedFood != null) ...[
                const SizedBox(height: 25),

                // Weight Input
                Text(
                  "Weight (grams) *",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,1}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Please enter a valid weight';
                    }
                    if (weight > 5000) {
                      return 'Weight seems too high';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: TColor.lightGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: TColor.primaryColor1),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: TColor.lightGray,
                    hintText: "Enter weight in grams",
                    hintStyle: TextStyle(color: TColor.gray, fontSize: 12),
                    suffixText: "g",
                    suffixStyle: TextStyle(color: TColor.gray, fontSize: 14),
                  ),
                ),

                if (_calculatedNutrition.isNotEmpty) ...[
                  const SizedBox(height: 25),

                  // Nutrition Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: TColor.primaryG),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.restaurant_menu,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Nutrition Preview",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNutritionPreview(
                              "Calories",
                              "${_calculatedNutrition['calories']?.toStringAsFixed(0)} kcal",
                              Icons.local_fire_department,
                            ),
                            _buildNutritionPreview(
                              "Protein",
                              "${_calculatedNutrition['protein']?.toStringAsFixed(1)} g",
                              Icons.fitness_center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNutritionPreview(
                              "Carbs",
                              "${_calculatedNutrition['carbs']?.toStringAsFixed(1)} g",
                              Icons.grain,
                            ),
                            _buildNutritionPreview(
                              "Fat",
                              "${_calculatedNutrition['fat']?.toStringAsFixed(1)} g",
                              Icons.water_drop,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 30),

              // Save Button
              RoundButton(
                title: _isLoading
                    ? "Saving..."
                    : (_isEditing ? "Update Meal" : "Save Meal"),
                onPressed: _isLoading ? () {} : _saveMeal,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionPreview(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _createCustomFood() async {
    print('➕ Creating custom food...');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomFoodInputView(),
      ),
    );

    if (result == true) {
      print('✅ Custom food created, refreshing data...');
      // Refresh custom foods and reload categories
      await _mealService.initializeCustomFoods();
      _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Custom food created! You can now select it from the list.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.local_cafe;
      default:
        return Icons.restaurant;
    }
  }
}
