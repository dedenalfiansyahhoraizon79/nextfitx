import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../common/colo_extension.dart';
import '../../services/workout_service.dart';
import '../../services/sleep_service.dart';
import '../../services/water_intake_service.dart';
import '../../services/meal_service.dart';
import '../../services/intermittent_fasting_service.dart';
import '../../models/sleep_model.dart';
import '../../models/intermittent_fasting_model.dart';
import '../../models/workout_model.dart';
import '../../models/water_intake_model.dart';

class DailyProgressView extends StatefulWidget {
  const DailyProgressView({super.key});

  @override
  State<DailyProgressView> createState() => _DailyProgressViewState();
}

class _DailyProgressViewState extends State<DailyProgressView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final WorkoutService _workoutService = WorkoutService();
  final SleepService _sleepService = SleepService();
  final WaterIntakeService _waterService = WaterIntakeService();
  final MealService _mealService = MealService();
  final IntermittentFastingService _fastingService =
      IntermittentFastingService();

  bool _isLoading = true;

  // Data variables
  List<WorkoutChartData> _workoutData = [];
  List<SleepModel> _sleepData = [];
  Map<DateTime, WaterSummary> _waterData = {};
  Map<DateTime, double> _nutritionData = {};
  List<FastingModel> _fastingData = [];

  int _selectedDays = 7; // Default to 7 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDailyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyData() async {
    setState(() => _isLoading = true);

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: _selectedDays - 1));

      // Load workout data
      final workoutData = await _workoutService.getAggregatedChartData(
        'calories',
        startDate: startDate,
        endDate: endDate,
      );

      // Load sleep data
      final sleepData =
          await _sleepService.getSleepForDateRange(startDate, endDate);

      // Load water data
      final waterData = await _waterService.getMonthlyWaterSummary();

      // Filter water data for selected period
      final filteredWaterData = <DateTime, WaterSummary>{};
      for (int i = 0; i < _selectedDays; i++) {
        final date = startDate.add(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        if (waterData.containsKey(dateKey)) {
          filteredWaterData[dateKey] = waterData[dateKey]!;
        }
      }

      // Load nutrition data
      final nutritionData = <DateTime, double>{};
      for (int i = 0; i < _selectedDays; i++) {
        final date = startDate.add(Duration(days: i));
        final dayNutrition =
            await _mealService.getNutritionSummaryForDate(date);
        nutritionData[date] = dayNutrition['calories'] ?? 0.0;
      }

      // Load fasting data
      final fastingData =
          await _fastingService.getFastingForDateRange(startDate, endDate);

      if (mounted) {
        setState(() {
          _workoutData = workoutData;
          _sleepData = sleepData;
          _waterData = filteredWaterData;
          _nutritionData = nutritionData;
          _fastingData = fastingData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading daily data: $e');
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
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Daily Progress",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.calendar_today, color: TColor.black),
            onSelected: (days) {
              setState(() {
                _selectedDays = days;
              });
              _loadDailyData();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 14, child: Text('Last 14 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: TColor.primaryColor1,
          unselectedLabelColor: TColor.gray,
          indicatorColor: TColor.primaryColor1,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: "Workout"),
            Tab(icon: Icon(Icons.bedtime), text: "Sleep"),
            Tab(icon: Icon(Icons.water_drop), text: "Water"),
            Tab(icon: Icon(Icons.restaurant), text: "Nutrition"),
            Tab(icon: Icon(Icons.schedule), text: "Fasting"),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWorkoutTab(),
                _buildSleepTab(),
                _buildWaterTab(),
                _buildNutritionTab(),
                _buildFastingTab(),
              ],
            ),
    );
  }

  Widget _buildWorkoutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Calories Burned (Last $_selectedDays days)"),
          const SizedBox(height: 20),

          // Chart
          Container(
            height: 250,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _workoutData.isEmpty
                ? Center(
                    child: Text('No workout data available',
                        style: TextStyle(color: TColor.gray)))
                : LineChart(_buildWorkoutLineChart()),
          ),

          const SizedBox(height: 20),
          _buildWorkoutStats(),
        ],
      ),
    );
  }

  Widget _buildSleepTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Sleep Duration (Last $_selectedDays days)"),
          const SizedBox(height: 20),

          // Chart
          Container(
            height: 250,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _sleepData.isEmpty
                ? Center(
                    child: Text('No sleep data available',
                        style: TextStyle(color: TColor.gray)))
                : LineChart(_buildSleepLineChart()),
          ),

          const SizedBox(height: 20),
          _buildSleepStats(),
        ],
      ),
    );
  }

  Widget _buildWaterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Water Intake (Last $_selectedDays days)"),
          const SizedBox(height: 20),

          // Chart
          Container(
            height: 250,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _waterData.isEmpty
                ? Center(
                    child: Text('No water data available',
                        style: TextStyle(color: TColor.gray)))
                : BarChart(_buildWaterBarChart()),
          ),

          const SizedBox(height: 20),
          _buildWaterStats(),
        ],
      ),
    );
  }

  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Calories Consumed (Last $_selectedDays days)"),
          const SizedBox(height: 20),

          // Chart
          Container(
            height: 250,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _nutritionData.isEmpty
                ? Center(
                    child: Text('No nutrition data available',
                        style: TextStyle(color: TColor.gray)))
                : LineChart(_buildNutritionLineChart()),
          ),

          const SizedBox(height: 20),
          _buildNutritionStats(),
        ],
      ),
    );
  }

  Widget _buildFastingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Fasting Sessions (Last $_selectedDays days)"),
          const SizedBox(height: 20),
          if (_fastingData.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                child: Text(
                  'No fasting data available',
                  style: TextStyle(color: TColor.gray, fontSize: 16),
                ),
              ),
            )
          else
            ..._fastingData
                .map((fasting) => _buildFastingCard(fasting))
                ,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: TColor.black,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  LineChartData _buildWorkoutLineChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _workoutData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _workoutData[i].value));
    }

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 50),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < _workoutData.length) {
                final date = _workoutData[value.toInt()].date;
                return Text('${date.day}/${date.month}',
                    style: TextStyle(fontSize: 10));
              }
              return Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: TColor.primaryColor1,
          barWidth: 3,
          dotData: FlDotData(show: true),
        ),
      ],
    );
  }

  LineChartData _buildSleepLineChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _sleepData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _sleepData[i].durationHours));
    }

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 50),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < _sleepData.length) {
                final date = _sleepData[value.toInt()].date;
                return Text('${date.day}/${date.month}',
                    style: TextStyle(fontSize: 10));
              }
              return Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF9C27B0),
          barWidth: 3,
          dotData: FlDotData(show: true),
        ),
      ],
    );
  }

  BarChartData _buildWaterBarChart() {
    final barGroups = <BarChartGroupData>[];
    final entries = _waterData.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entries[i].value.effectiveHydrationMl.toDouble(),
              color: const Color(0xFF00BCD4),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      barGroups: barGroups,
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 50),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < entries.length) {
                final date = entries[value.toInt()].key;
                return Text('${date.day}/${date.month}',
                    style: TextStyle(fontSize: 10));
              }
              return Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
    );
  }

  LineChartData _buildNutritionLineChart() {
    final spots = <FlSpot>[];
    final entries = _nutritionData.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value));
    }

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 50),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < entries.length) {
                final date = entries[value.toInt()].key;
                return Text('${date.day}/${date.month}',
                    style: TextStyle(fontSize: 10));
              }
              return Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF4CAF50),
          barWidth: 3,
          dotData: FlDotData(show: true),
        ),
      ],
    );
  }

  Widget _buildWorkoutStats() {
    if (_workoutData.isEmpty) return SizedBox();

    final totalCalories =
        _workoutData.fold(0.0, (sum, data) => sum + data.value);
    final avgCalories = totalCalories / _workoutData.length;
    final maxCalories =
        _workoutData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return _buildStatsContainer([
      _buildStatItem("Total Burned", "${totalCalories.toStringAsFixed(0)} kcal",
          Colors.orange),
      _buildStatItem("Average/Day", "${avgCalories.toStringAsFixed(0)} kcal",
          TColor.primaryColor1),
      _buildStatItem(
          "Best Day", "${maxCalories.toStringAsFixed(0)} kcal", Colors.green),
    ]);
  }

  Widget _buildSleepStats() {
    if (_sleepData.isEmpty) return SizedBox();

    final totalHours =
        _sleepData.fold(0.0, (sum, sleep) => sum + sleep.durationHours);
    final avgHours = totalHours / _sleepData.length;
    final maxHours =
        _sleepData.map((e) => e.durationHours).reduce((a, b) => a > b ? a : b);

    return _buildStatsContainer([
      _buildStatItem("Total Sleep", "${totalHours.toStringAsFixed(1)}h",
          const Color(0xFF9C27B0)),
      _buildStatItem("Average/Night", "${avgHours.toStringAsFixed(1)}h",
          const Color(0xFF673AB7)),
      _buildStatItem(
          "Best Night", "${maxHours.toStringAsFixed(1)}h", Colors.indigo),
    ]);
  }

  Widget _buildWaterStats() {
    if (_waterData.isEmpty) return SizedBox();

    final totalMl = _waterData.values
        .fold(0, (sum, water) => sum + water.effectiveHydrationMl);
    final avgMl = totalMl / _waterData.length;
    final goalDays = _waterData.values
        .where((water) => water.progressPercentage >= 100)
        .length;

    return _buildStatsContainer([
      _buildStatItem("Total Water", "${(totalMl / 1000).toStringAsFixed(1)}L",
          const Color(0xFF00BCD4)),
      _buildStatItem("Average/Day", "${(avgMl / 1000).toStringAsFixed(1)}L",
          const Color(0xFF0097A7)),
      _buildStatItem("Goal Reached", "$goalDays days", Colors.cyan),
    ]);
  }

  Widget _buildNutritionStats() {
    if (_nutritionData.isEmpty) return SizedBox();

    final totalCalories =
        _nutritionData.values.fold(0.0, (sum, calories) => sum + calories);
    final avgCalories = totalCalories / _nutritionData.length;
    final maxCalories = _nutritionData.values.reduce((a, b) => a > b ? a : b);

    return _buildStatsContainer([
      _buildStatItem("Total Consumed",
          "${totalCalories.toStringAsFixed(0)} kcal", const Color(0xFF4CAF50)),
      _buildStatItem("Average/Day", "${avgCalories.toStringAsFixed(0)} kcal",
          const Color(0xFF2E7D32)),
      _buildStatItem("Highest Day", "${maxCalories.toStringAsFixed(0)} kcal",
          Colors.lightGreen),
    ]);
  }

  Widget _buildStatsContainer(List<Widget> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFastingCard(FastingModel fasting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${fasting.date.day}/${fasting.date.month}/${fasting.date.year}',
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: fasting.status == FastingStatus.completed
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  fasting.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: fasting.status == FastingStatus.completed
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Duration: ${fasting.targetDurationHours}h',
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
            ),
          ),
          if (fasting.status == FastingStatus.completed)
            Text(
              'Completed successfully!',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
