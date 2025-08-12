import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';
import 'workout_input_view.dart';

class WorkoutDetailView extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutDetailView({super.key, required this.workout});

  @override
  State<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<WorkoutDetailView> {
  final WorkoutService _workoutService = WorkoutService();
  late WorkoutModel _workout;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
  }

  Future<void> _deleteWorkout() async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed && _workout.id != null) {
      try {
        await _workoutService.deleteWorkout(_workout.id!);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting workout: $e')),
          );
        }
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Workout'),
              content: const Text(
                  'Are you sure you want to delete this workout? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _getIntensityLevel(double metValue) {
    if (metValue < 3.0) return "Light";
    if (metValue < 6.0) return "Moderate";
    if (metValue < 9.0) return "Vigorous";
    return "Very Vigorous";
  }

  Color _getIntensityColor(double metValue) {
    if (metValue < 3.0) return Colors.green;
    if (metValue < 6.0) return Colors.blue;
    if (metValue < 9.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final workoutType = WorkoutTypes.findByName(_workout.workoutType);
    final intensityLevel = workoutType != null
        ? _getIntensityLevel(workoutType.metValue)
        : "Unknown";
    final intensityColor = workoutType != null
        ? _getIntensityColor(workoutType.metValue)
        : Colors.grey;

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
          "Workout Details",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WorkoutInputView(existingWorkout: _workout),
                  ),
                ).then((result) {
                  if (result != null) {
                    Navigator.pop(context, result);
                  }
                });
              } else if (value == 'delete') {
                _deleteWorkout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with workout icon and basic info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: TColor.primaryG),
              ),
              child: Column(
                children: [
                  // Workout Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Text(
                        workoutType?.icon ?? '🏃‍♂️',
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Workout Name
                  Text(
                    _workout.workoutType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Date
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(_workout.date),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Category
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workoutType?.category ?? 'Other',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          "Duration",
                          "${_workout.durationMinutes} min",
                          Icons.timer,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildMetricCard(
                          "Calories",
                          "${_workout.caloriesBurned.toStringAsFixed(0)} kcal",
                          Icons.local_fire_department,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          "Intensity",
                          intensityLevel,
                          Icons.flash_on,
                          intensityColor,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildMetricCard(
                          "Calories/Min",
                          (_workout.caloriesBurned / _workout.durationMinutes).toStringAsFixed(1),
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Workout Information Section
                  Text(
                    "Workout Information",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: TColor.lightGray,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow("Workout Type", _workout.workoutType),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                            "Category", workoutType?.category ?? 'Other'),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                            "Description",
                            workoutType?.description ??
                                'No description available'),
                        const SizedBox(height: 15),
                        _buildInfoRow("MET Value",
                            workoutType?.metValue.toString() ?? 'Unknown'),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                            "Date Recorded",
                            DateFormat('MMM dd, yyyy at HH:mm')
                                .format(_workout.createdAt)),
                        if (_workout.updatedAt != _workout.createdAt) ...[
                          const SizedBox(height: 15),
                          _buildInfoRow(
                              "Last Updated",
                              DateFormat('MMM dd, yyyy at HH:mm')
                                  .format(_workout.updatedAt)),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Performance Insights
                  Text(
                    "Performance Insights",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: TColor.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 2)
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInsightItem(
                          "Calorie Burn Rate",
                          "${(_workout.caloriesBurned / _workout.durationMinutes).toStringAsFixed(1)} kcal/min",
                          "This workout burned calories at a ${intensityLevel.toLowerCase()} intensity level",
                          Icons.local_fire_department,
                          Colors.red,
                        ),
                        const SizedBox(height: 20),
                        _buildInsightItem(
                          "Workout Efficiency",
                          "${((_workout.caloriesBurned / _workout.durationMinutes) * 10).toStringAsFixed(0)}%",
                          "Based on duration and calorie burn compared to average",
                          Icons.trending_up,
                          Colors.green,
                        ),
                        const SizedBox(height: 20),
                        _buildInsightItem(
                          "Health Impact",
                          intensityLevel,
                          workoutType != null && workoutType.metValue >= 6.0
                              ? "Great for cardiovascular health and weight management"
                              : "Good for general fitness and active recovery",
                          Icons.favorite,
                          intensityColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TColor.white,
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 2, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _deleteWorkout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: RoundButton(
                title: "Edit",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WorkoutInputView(existingWorkout: _workout),
                    ),
                  ).then((result) {
                    if (result != null) {
                      Navigator.pop(context, result);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: TColor.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(String title, String value, String description,
      IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
