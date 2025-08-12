import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';

class WorkoutInputView extends StatefulWidget {
  final WorkoutModel? existingWorkout;

  const WorkoutInputView({super.key, this.existingWorkout});

  @override
  State<WorkoutInputView> createState() => _WorkoutInputViewState();
}

class _WorkoutInputViewState extends State<WorkoutInputView> {
  final WorkoutService _workoutService = WorkoutService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _durationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedWorkoutType;
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isEditing = false;
  double _predictedCalories = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingWorkout != null) {
      _isEditing = true;
      _populateFields();
    }
    _durationController.addListener(_updateCaloriePreview);
  }

  void _populateFields() {
    final workout = widget.existingWorkout!;
    _selectedDate = workout.date;
    _selectedWorkoutType = workout.workoutType;
    _durationController.text = workout.durationMinutes.toString();

    // Find category for selected workout type
    final workoutType = WorkoutTypes.findByName(workout.workoutType);
    _selectedCategory = workoutType?.category;

    _updateCaloriePreview();
  }

  void _updateCaloriePreview() {
    if (_selectedWorkoutType != null && _durationController.text.isNotEmpty) {
      final duration = int.tryParse(_durationController.text) ?? 0;
      if (duration > 0) {
        _workoutService
            .predictCalorieBurn(
          workoutType: _selectedWorkoutType!,
          durationMinutes: duration,
        )
            .then((calories) {
          setState(() {
            _predictedCalories = calories;
          });
        });
      }
    } else {
      setState(() {
        _predictedCalories = 0.0;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedWorkoutType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a workout type')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final duration = int.parse(_durationController.text);

      final workout = WorkoutModel(
        id: widget.existingWorkout?.id,
        userId: '', // Will be set by service
        date: _selectedDate,
        workoutType: _selectedWorkoutType!,
        durationMinutes: duration,
        caloriesBurned: 0.0, // Will be calculated by service
        createdAt: widget.existingWorkout?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing && widget.existingWorkout?.id != null) {
        await _workoutService.updateWorkout(
            widget.existingWorkout!.id!, workout);
      } else {
        await _workoutService.createWorkout(workout);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Workout updated successfully'
                : 'Workout saved successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _durationController.removeListener(_updateCaloriePreview);
    _durationController.dispose();
    super.dispose();
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
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/img/ArrowLeft.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          _isEditing ? "Edit Workout" : "Add Workout",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
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
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                        style: TextStyle(color: TColor.black, fontSize: 14),
                      ),
                      Icon(Icons.calendar_today, color: TColor.gray, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Workout Category Selection
              Text(
                "Category",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),

              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: WorkoutTypes.categories.length,
                  itemBuilder: (context, index) {
                    final category = WorkoutTypes.categories[index];
                    final isSelected = category == _selectedCategory;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                          _selectedWorkoutType =
                              null; // Reset workout type when category changes
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TColor.primaryColor1
                              : TColor.lightGray,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : TColor.gray,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Workout Type Selection
              if (_selectedCategory != null) ...[
                Text(
                  "Workout Type",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: WorkoutTypes.getByCategory(_selectedCategory!)
                        .map((workoutType) {
                      final isSelected =
                          workoutType.name == _selectedWorkoutType;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWorkoutType = workoutType.name;
                          });
                          _updateCaloriePreview();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? TColor.primaryColor1
                                    .withAlpha((0.2 * 255).round())
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: TColor.primaryColor1)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Text(
                                workoutType.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workoutType.name,
                                      style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      workoutType.description,
                                      style: TextStyle(
                                        color: TColor.gray,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: TColor.primaryColor1,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Duration Input
              Text(
                "Duration (minutes) *",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter workout duration';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Please enter a valid duration';
                  }
                  if (duration > 300) {
                    return 'Duration should be less than 300 minutes';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
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
                  hintText: "Enter duration in minutes",
                  hintStyle: TextStyle(color: TColor.gray, fontSize: 12),
                ),
              ),

              const SizedBox(height: 30),

              // Calorie Preview
              if (_predictedCalories > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: TColor.primaryG),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Estimated Calories Burned",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_predictedCalories.toStringAsFixed(0)} kcal",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Based on average 70kg body weight",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Save Button
              RoundButton(
                title: _isLoading
                    ? "Saving..."
                    : (_isEditing ? "Update Workout" : "Save Workout"),
                onPressed: _isLoading ? () {} : _saveWorkout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
