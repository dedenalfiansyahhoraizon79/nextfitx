import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/colo_extension.dart';
import '../../services/workout_service.dart';
import '../../models/workout_model.dart';

class WorkoutProgressView extends StatefulWidget {
  const WorkoutProgressView({super.key});

  @override
  State<WorkoutProgressView> createState() => _WorkoutProgressViewState();
}

class _WorkoutProgressViewState extends State<WorkoutProgressView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkoutService _workoutService = WorkoutService();

  bool _isLoading = true;
  List<WorkoutModel> _workouts = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWorkoutProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutProgress() async {
    try {
      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Load recent workouts (last 30 days)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      _workouts =
          await _workoutService.getWorkoutsByDateRange(thirtyDaysAgo, now);
      print('Workouts loaded: ${_workouts.length}');

      // Calculate statistics
      _calculateStats();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading workout progress: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    if (_workouts.isEmpty) {
      _stats = {
        'totalWorkouts': 0,
        'totalDuration': 0,
        'totalCalories': 0,
        'averageDuration': 0,
        'averageCalories': 0,
        'mostFrequentType': 'None',
        'weeklyGoalProgress': 0,
      };
      return;
    }

    int totalDuration = 0;
    double totalCalories = 0;
    Map<String, int> workoutTypes = {};

    for (var workout in _workouts) {
      totalDuration += workout.durationMinutes;
      totalCalories += workout.caloriesBurned;

      workoutTypes[workout.workoutType] =
          (workoutTypes[workout.workoutType] ?? 0) + 1;
    }

    String mostFrequentType = 'None';
    if (workoutTypes.isNotEmpty) {
      mostFrequentType =
          workoutTypes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Calculate weekly goal progress (assuming goal of 3 workouts per week)
    final thisWeekWorkouts = _workouts.where((w) {
      final weekStart =
          DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      return w.date.isAfter(weekStart);
    }).length;

    _stats = {
      'totalWorkouts': _workouts.length,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
      'averageDuration':
          _workouts.isNotEmpty ? totalDuration / _workouts.length : 0,
      'averageCalories':
          _workouts.isNotEmpty ? totalCalories / _workouts.length : 0,
      'mostFrequentType': mostFrequentType,
      'weeklyGoalProgress': (thisWeekWorkouts / 3 * 100).clamp(0, 100),
    };
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
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Workout Progress",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
              ),
            )
          : Column(
              children: [
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: TColor.primaryColor1,
                  labelColor: TColor.primaryColor1,
                  unselectedLabelColor: TColor.gray,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: "Overview"),
                    Tab(text: "Statistics"),
                    Tab(text: "History"),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildStatisticsTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Goal Progress
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [TColor.primaryColor2, TColor.primaryColor1],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.track_changes, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      "Weekly Goal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  "${_stats['weeklyGoalProgress']?.toInt() ?? 0}% Complete",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (_stats['weeklyGoalProgress'] ?? 0) / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  "Goal: 3 workouts per week",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Quick Stats
          Text(
            "30-Day Summary",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Total Workouts",
                  "${_stats['totalWorkouts'] ?? 0}",
                  Icons.fitness_center,
                  TColor.primaryColor1,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  "Total Hours",
                  "${((_stats['totalDuration'] ?? 0) / 60).toStringAsFixed(1)}h",
                  Icons.timer,
                  Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Calories Burned",
                  "${(_stats['totalCalories'] ?? 0).toInt()}",
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  "Favorite Type",
                  _stats['mostFrequentType'] ?? 'None',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Recent Achievements
          if (_workouts.isNotEmpty) ...[
            Text(
              "Recent Achievements",
              style: TextStyle(
                color: TColor.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            _buildAchievementsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Detailed Statistics",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Average Stats
          _buildDetailedStatCard(
            "Average Workout Duration",
            "${(_stats['averageDuration'] ?? 0).toStringAsFixed(1)} minutes",
            Icons.timer,
            Colors.blue,
          ),

          const SizedBox(height: 15),

          _buildDetailedStatCard(
            "Average Calories per Session",
            "${(_stats['averageCalories'] ?? 0).toStringAsFixed(0)} kcal",
            Icons.local_fire_department,
            Colors.orange,
          ),

          const SizedBox(height: 15),

          _buildDetailedStatCard(
            "Most Active Day",
            _getMostActiveDay(),
            Icons.calendar_today,
            Colors.green,
          ),

          const SizedBox(height: 25),

          // Workout Type Distribution
          Text(
            "Workout Distribution",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),

          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildWorkoutTypeChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: TColor.gray,
            ),
            const SizedBox(height: 20),
            Text(
              "No Workout History",
              style: TextStyle(
                color: TColor.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Start working out to see your progress here",
              style: TextStyle(
                color: TColor.gray,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];
        return _buildWorkoutHistoryItem(workout);
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList() {
    List<Map<String, dynamic>> achievements = [];

    if ((_stats['totalWorkouts'] ?? 0) >= 10) {
      achievements.add({
        'title': 'Consistent Exerciser',
        'description': 'Completed 10+ workouts',
        'icon': Icons.emoji_events,
        'color': Colors.yellow,
      });
    }

    if ((_stats['totalCalories'] ?? 0) >= 1000) {
      achievements.add({
        'title': 'Calorie Burner',
        'description': 'Burned 1000+ calories',
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
      });
    }

    if (achievements.isEmpty) {
      achievements.add({
        'title': 'Getting Started',
        'description': 'Keep working out to unlock achievements',
        'icon': Icons.star_outline,
        'color': TColor.gray,
      });
    }

    return Column(
      children: achievements
          .map((achievement) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: achievement['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        achievement['icon'],
                        color: achievement['color'],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement['title'],
                            style: TextStyle(
                              color: TColor.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            achievement['description'],
                            style: TextStyle(
                              color: TColor.gray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildWorkoutTypeChart() {
    if (_workouts.isEmpty) {
      return Center(
        child: Text(
          "No data available",
          style: TextStyle(
            color: TColor.gray,
            fontSize: 14,
          ),
        ),
      );
    }

    Map<String, int> workoutTypes = {};
    for (var workout in _workouts) {
      workoutTypes[workout.workoutType] =
          (workoutTypes[workout.workoutType] ?? 0) + 1;
    }

    return Column(
      children: workoutTypes.entries.map((entry) {
        double percentage = entry.value / _workouts.length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: TColor.lightGray,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${(percentage * 100).toInt()}%",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutHistoryItem(WorkoutModel workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TColor.primaryColor1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.fitness_center,
              color: TColor.primaryColor1,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutType,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${workout.durationMinutes} min • ${workout.caloriesBurned.toInt()} cal",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${workout.date.day}/${workout.date.month}",
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getMostActiveDay() {
    if (_workouts.isEmpty) return "No data";

    Map<int, int> dayCount = {};
    for (var workout in _workouts) {
      int weekday = workout.date.weekday;
      dayCount[weekday] = (dayCount[weekday] ?? 0) + 1;
    }

    if (dayCount.isEmpty) return "No data";

    int mostActiveDay =
        dayCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[mostActiveDay - 1];
  }
}
