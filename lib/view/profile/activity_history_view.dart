import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/colo_extension.dart';
import '../../services/workout_service.dart';
import '../../services/body_composition_service.dart';
import '../../services/meal_service.dart';
import '../../services/sleep_service.dart';
import '../../services/intermittent_fasting_service.dart';
import '../../services/water_intake_service.dart';

class ActivityHistoryView extends StatefulWidget {
  const ActivityHistoryView({super.key});

  @override
  State<ActivityHistoryView> createState() => _ActivityHistoryViewState();
}

class _ActivityHistoryViewState extends State<ActivityHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final WorkoutService _workoutService = WorkoutService();
  final BodyCompositionService _bodyService = BodyCompositionService();
  final MealService _mealService = MealService();
  final SleepService _sleepService = SleepService();
  final IntermittentFastingService _fastingService =
      IntermittentFastingService();
  final WaterIntakeService _waterService = WaterIntakeService();

  bool _isLoading = true;

  // Activity summary data
  Map<String, dynamic> _activitySummary = {};
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActivityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivityData() async {
    try {
      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Load activity summary for the last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get workout count
      final workouts =
          await _workoutService.getWorkoutsByDateRange(thirtyDaysAgo, now);

      // Get other activity counts (simplified for demo)
      final bodyRecords =
          await _bodyService.getRecordsByDateRange(thirtyDaysAgo, now);
      final sleepRecords =
          await _sleepService.getSleepRecordsByDateRange(thirtyDaysAgo, now);

      _activitySummary = {
        'workouts': workouts.length,
        'bodyRecords': bodyRecords.length,
        'sleepRecords': sleepRecords.length,
        'totalDays': 30,
        'activeDays': _calculateActiveDays(workouts, bodyRecords, sleepRecords),
      };

      // Generate recent activities
      _recentActivities =
          _generateRecentActivities(workouts, bodyRecords, sleepRecords);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading activity data: $e');
      setState(() => _isLoading = false);
    }
  }

  int _calculateActiveDays(
      dynamic workouts, dynamic bodyRecords, dynamic sleepRecords) {
    Set<String> activeDays = {};

    // Add workout days
    for (var workout in workouts) {
      activeDays.add(workout.date.toIso8601String().split('T')[0]);
    }

    // Add body record days
    for (var record in bodyRecords) {
      activeDays.add(record.date.toIso8601String().split('T')[0]);
    }

    // Add sleep record days
    for (var record in sleepRecords) {
      activeDays.add(record.date.toIso8601String().split('T')[0]);
    }

    return activeDays.length;
  }

  List<Map<String, dynamic>> _generateRecentActivities(
      dynamic workouts, dynamic bodyRecords, dynamic sleepRecords) {
    List<Map<String, dynamic>> activities = [];

    // Add workouts
    for (var workout in workouts.take(5)) {
      activities.add({
        'type': 'Workout',
        'title': workout.workoutType,
        'subtitle':
            '${workout.durationMinutes} min • ${workout.caloriesBurned.toInt()} cal',
        'date': workout.date,
        'icon': Icons.fitness_center,
        'color': TColor.primaryColor1,
      });
    }

    // Add body records
    for (var record in bodyRecords.take(3)) {
      activities.add({
        'type': 'Body Composition',
        'title': 'Body Check',
        'subtitle':
            '${record.weight.toStringAsFixed(1)} kg • ${record.bodyFatPercentage.toStringAsFixed(1)}% BF',
        'date': record.date,
        'icon': Icons.monitor_weight,
        'color': Colors.blue,
      });
    }

    // Add sleep records
    for (var record in sleepRecords.take(3)) {
      activities.add({
        'type': 'Sleep',
        'title': 'Sleep Tracking',
        'subtitle':
            '${(record.durationMinutes / 60).toStringAsFixed(1)}h • ${record.quality.displayName}',
        'date': record.date,
        'icon': Icons.bedtime,
        'color': Colors.purple,
      });
    }

    // Sort by date (most recent first)
    activities.sort((a, b) => b['date'].compareTo(a['date']));

    return activities.take(10).toList();
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
          "Activity History",
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
                    Tab(text: "Recent"),
                    Tab(text: "Charts"),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildRecentTab(),
                      _buildChartsTab(),
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
          // Summary Cards
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
                child: _buildSummaryCard(
                  "Workouts",
                  "${_activitySummary['workouts'] ?? 0}",
                  Icons.fitness_center,
                  TColor.primaryColor1,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSummaryCard(
                  "Active Days",
                  "${_activitySummary['activeDays'] ?? 0}",
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Body Checks",
                  "${_activitySummary['bodyRecords'] ?? 0}",
                  Icons.monitor_weight,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSummaryCard(
                  "Sleep Records",
                  "${_activitySummary['sleepRecords'] ?? 0}",
                  Icons.bedtime,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Activity Streak
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
                Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Activity Streak",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${_activitySummary['activeDays'] ?? 0} days this month",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${((_activitySummary['activeDays'] ?? 0) / 30 * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _recentActivities.length,
      itemBuilder: (context, index) {
        final activity = _recentActivities[index];
        return _buildActivityItem(activity);
      },
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Activity Trends",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Placeholder for activity chart
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 50,
                  color: TColor.gray,
                ),
                const SizedBox(height: 10),
                Text(
                  "Activity Charts Coming Soon",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Detailed analytics and trends will be available here",
                  textAlign: TextAlign.center,
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
    );
  }

  Widget _buildSummaryCard(
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
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
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
              color: activity['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity['icon'],
              color: activity['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['subtitle'],
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity['type'],
                style: TextStyle(
                  color: activity['color'],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(activity['date']),
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return "Today";
    } else if (difference == 1) {
      return "Yesterday";
    } else if (difference < 7) {
      return "${difference}d ago";
    } else {
      return "${date.day}/${date.month}";
    }
  }
}
