import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/meal_model.dart';
import '../../services/meal_service.dart';

class CustomFoodInputView extends StatefulWidget {
  final CustomFoodItem? existingFood;

  const CustomFoodInputView({super.key, this.existingFood});

  @override
  State<CustomFoodInputView> createState() => _CustomFoodInputViewState();
}

class _CustomFoodInputViewState extends State<CustomFoodInputView> {
  final _formKey = GlobalKey<FormState>();
  final MealService _mealService = MealService();

  // Form controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sugarController = TextEditingController();

  // Form data
  String _selectedCategory = FoodCategories.custom;

  // UI state
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingFood != null) {
      _isEditing = true;
      _populateExistingFood();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    super.dispose();
  }

  void _populateExistingFood() {
    final food = widget.existingFood!;
    setState(() {
      _nameController.text = food.name;
      _brandController.text = food.brand ?? '';
      _descriptionController.text = food.description ?? '';
      _selectedCategory = food.category;
      _caloriesController.text = food.caloriesPer100g.toStringAsFixed(1);
      _proteinController.text = food.proteinPer100g.toStringAsFixed(1);
      _carbsController.text = food.carbsPer100g.toStringAsFixed(1);
      _fatController.text = food.fatPer100g.toStringAsFixed(1);
      _fiberController.text = food.fiberPer100g.toStringAsFixed(1);
      _sugarController.text = food.sugarPer100g.toStringAsFixed(1);
    });
  }

  Future<void> _saveCustomFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check if name is available (for new foods or changed names)
      if (!_isEditing ||
          _nameController.text.trim() != widget.existingFood!.name) {
        final isAvailable = await _mealService.isCustomFoodNameAvailable(
          _nameController.text.trim(),
          excludeId: widget.existingFood?.id,
        );

        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ A food with this name already exists'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final customFood = CustomFoodItem(
        id: widget.existingFood?.id,
        userId: '', // Will be set by service
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        caloriesPer100g: double.parse(_caloriesController.text),
        proteinPer100g: double.parse(_proteinController.text),
        carbsPer100g: double.parse(_carbsController.text),
        fatPer100g: double.parse(_fatController.text),
        fiberPer100g: double.parse(_fiberController.text),
        sugarPer100g: double.parse(_sugarController.text),
        createdAt: widget.existingFood?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await _mealService.updateCustomFood(customFood);
      } else {
        await _mealService.createCustomFood(customFood);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '✅ Custom food updated successfully!'
                : '✅ Custom food created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: TColor.gray.withOpacity(0.5)),
            suffixText: suffix,
            suffixStyle: TextStyle(color: TColor.gray),
            filled: true,
            fillColor: TColor.lightGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: TColor.primaryColor1, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
      ],
    );
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
          _isEditing ? "Edit Custom Food" : "Add Custom Food",
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
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [TColor.primaryColor2, TColor.primaryColor1],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.add_circle,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? "Edit Custom Food"
                                : "Create Your Food",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _isEditing
                                ? "Update nutritional information"
                                : "Add foods not in our database",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Basic Information Section
              Text(
                "Basic Information",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _nameController,
                label: "Food Name*",
                hint: "e.g., Homemade Chocolate Cake",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Food name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Food name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Category dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Category*",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: TColor.lightGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            BorderSide(color: TColor.primaryColor1, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                    ),
                    items: FoodCategories.all.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildTextField(
                controller: _brandController,
                label: "Brand (Optional)",
                hint: "e.g., Nestle, Local Bakery",
              ),

              const SizedBox(height: 20),

              _buildTextField(
                controller: _descriptionController,
                label: "Description (Optional)",
                hint: "Brief description or ingredients",
                maxLines: 2,
              ),

              const SizedBox(height: 30),

              // Nutritional Information Section
              Text(
                "Nutritional Information (per 100g)",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter values for 100 grams of this food",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 15),

              // Nutrition fields grid
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _caloriesController,
                      label: "Calories*",
                      hint: "250",
                      suffix: "kcal",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final calories = double.tryParse(value);
                        if (calories == null ||
                            calories < 0 ||
                            calories > 900) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      controller: _proteinController,
                      label: "Protein*",
                      hint: "15",
                      suffix: "g",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final protein = double.tryParse(value);
                        if (protein == null || protein < 0 || protein > 100) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _carbsController,
                      label: "Carbs*",
                      hint: "30",
                      suffix: "g",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final carbs = double.tryParse(value);
                        if (carbs == null || carbs < 0 || carbs > 100) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      controller: _fatController,
                      label: "Fat*",
                      hint: "10",
                      suffix: "g",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final fat = double.tryParse(value);
                        if (fat == null || fat < 0 || fat > 100) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _fiberController,
                      label: "Fiber*",
                      hint: "5",
                      suffix: "g",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final fiber = double.tryParse(value);
                        if (fiber == null || fiber < 0 || fiber > 50) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      controller: _sugarController,
                      label: "Sugar*",
                      hint: "8",
                      suffix: "g",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final sugar = double.tryParse(value);
                        if (sugar == null || sugar < 0 || sugar > 100) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Tips
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates,
                            color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Tips for Accurate Entry",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• Check nutrition labels on packaging\n"
                      "• Use nutrition databases like USDA\n"
                      "• Round to nearest 0.1 for accuracy\n"
                      "• For recipes, calculate per 100g total",
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Save button
              RoundButton(
                title: _isEditing ? "Update Custom Food" : "Save Custom Food",
                onPressed: () {
                  if (!_isLoading) {
                    _saveCustomFood();
                  }
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
