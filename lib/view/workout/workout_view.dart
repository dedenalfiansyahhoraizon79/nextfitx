import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';
import 'workout_input_view.dart';
import 'workout_detail_view.dart';

class WorkoutView extends StatefulWidget {
  const WorkoutView({super.key});

  @override
  State<WorkoutView> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends State<WorkoutView>
    with TickerProviderStateMixin {
  final WorkoutService _workoutService = WorkoutService();
  late TabController _tabController;

  bool _isLoading = true;
  String _errorMessage = '';
  List<WorkoutModel> _records = [];
  WorkoutSummary? _summary;
  Map<String, dynamic> _weeklyProgress = {};
  String _selectedMetric = 'calories';
  List<WorkoutChartData> _chartData = [];

  // Date filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCustomDateRange = false;

  final List<Map<String, dynamic>> _metrics = [
    {
      'key': 'calories',
      'title': 'Calories',
      'unit': 'kcal',
      'color': Colors.red
    },
    {
      'key': 'duration',
      'title': 'Duration',
      'unit': 'min',
      'color': Colors.blue
    },
    {
      'key': 'workout_count',
      'title': 'Workouts',
      'unit': 'count',
      'color': Colors.green
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Set default to today only
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _isCustomDateRange = true;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final records = await _workoutService.getWorkoutRecords(limit: 30);
      final summary = await _workoutService.getWorkoutSummary();
      final weeklyProgress = await _workoutService.getWeeklyProgress();
      final chartData = await _workoutService.getAggregatedChartData(
        _selectedMetric,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _records = records;
        _summary = summary;
        _weeklyProgress = weeklyProgress;
        _chartData = chartData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChartData(String metric) async {
    try {
      // Default to last 7 days if no custom range is set
      final endDate = _endDate ?? DateTime.now();
      final startDate = _startDate ?? endDate.subtract(const Duration(days: 6));

      final chartData = await _workoutService.getAggregatedChartData(
        metric,
        startDate: startDate,
        endDate: endDate,
      );
      setState(() {
        _selectedMetric = metric;
        _chartData = chartData;
      });
    } catch (e) {
      // Handle error silently or show a snackbar
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 6)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primaryColor1,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isCustomDateRange = true;
      });
      await _loadChartData(_selectedMetric);
    }
  }

  void _resetDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isCustomDateRange = false;
    });
    _loadChartData(_selectedMetric);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _setPresetDateRange(int days) {
    final now = DateTime.now();
    setState(() {
      if (days == 1) {
        // For "Today" - show only today's data
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else {
        // For multiple days - show last N days including today
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        _startDate = DateTime(now.year, now.month, now.day - (days - 1));
      }
      _isCustomDateRange = true;
    });
    _loadChartData(_selectedMetric);
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
          onTap: () {
            Navigator.pop(context);
          },
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
          "Workout Record",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutInputView(),
                ),
              ).then((_) => _loadData());
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: TColor.primaryColor1,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      RoundButton(
                        title: "Retry",
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Tab Bar
                    Container(
                      color: TColor.white,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: TColor.primaryColor1,
                        labelColor: TColor.primaryColor1,
                        unselectedLabelColor: TColor.gray,
                        tabs: const [
                          Tab(text: "Overview"),
                          Tab(text: "Charts"),
                          Tab(text: "Records"),
                        ],
                      ),
                    ),
                    // Tab Bar View
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildChartsTab(),
                          _buildRecordsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    if (_summary == null) {
      return const Center(
        child: Text("No data available. Add your first workout!"),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Total Calories",
                  "${_summary!.totalCaloriesBurned.toStringAsFixed(0)} kcal",
                  Icons.local_fire_department,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSummaryCard(
                  "Total Workouts",
                  _summary!.totalWorkouts.toString(),
                  Icons.fitness_center,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Total Time",
                  "${(_summary!.totalMinutes / 60).toStringAsFixed(1)} hrs",
                  Icons.timer,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSummaryCard(
                  "Favorite Workout",
                  _summary!.mostFrequentWorkout,
                  Icons.favorite,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Weekly Progress
          if (_weeklyProgress.isNotEmpty) ...[
            Text(
              "This Week's Progress",
              style: TextStyle(
                color: TColor.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            _buildProgressCard(
              "Workout Days",
              _weeklyProgress['currentWorkoutDays'].toString(),
              _weeklyProgress['goalWorkoutDays'].toString(),
              _weeklyProgress['workoutDaysProgress'],
              Colors.purple,
              "days",
            ),
            const SizedBox(height: 10),
            _buildProgressCard(
              "Total Minutes",
              _weeklyProgress['currentMinutes'].toString(),
              _weeklyProgress['goalMinutes'].toString(),
              _weeklyProgress['minutesProgress'],
              Colors.blue,
              "min",
            ),
            const SizedBox(height: 10),
            _buildProgressCard(
              "Calories Burned",
              _weeklyProgress['currentCalories'].toStringAsFixed(0),
              _weeklyProgress['goalCalories'].toString(),
              _weeklyProgress['caloriesProgress'],
              Colors.red,
              "kcal",
            ),
            const SizedBox(height: 30),
          ],

          // Daily Overview Section
          Text(
            "Daily Progress",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),

          _buildDailyOverviewSection(),

          const SizedBox(height: 30),

          // Recent Workouts
          Text(
            "Recent Workouts",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),

          ..._records.take(5).map((record) => _buildRecentWorkoutCard(record)),

          if (_records.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Icon(Icons.fitness_center,
                      size: 50, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    "No workouts yet",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Add your first workout to get started",
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

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric Selector
          Text(
            "Select Metric",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _metrics.length,
              itemBuilder: (context, index) {
                final metric = _metrics[index];
                final isSelected = metric['key'] == _selectedMetric;

                return GestureDetector(
                  onTap: () => _loadChartData(metric['key']),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? TColor.primaryColor1 : TColor.lightGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      metric['title'],
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

          const SizedBox(height: 20),

          // Date Filter Section
          Text(
            "Date Filter",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),

          // Date filter options
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Preset buttons - focused on daily view
              _buildDateFilterChip(
                  "Today",
                  () => _setPresetDateRange(1),
                  _isCustomDateRange &&
                      _startDate != null &&
                      _isToday(_startDate!)),
              _buildDateFilterChip(
                  "3 Days",
                  () => _setPresetDateRange(3),
                  _isCustomDateRange &&
                      _startDate != null &&
                      _endDate!.difference(_startDate!).inDays == 2),
              _buildDateFilterChip(
                  "7 Days",
                  () => _setPresetDateRange(7),
                  _isCustomDateRange &&
                      _startDate != null &&
                      _endDate!.difference(_startDate!).inDays == 6),
              _buildDateFilterChip(
                  "14 Days",
                  () => _setPresetDateRange(14),
                  _isCustomDateRange &&
                      _startDate != null &&
                      _endDate!.difference(_startDate!).inDays == 13),

              // Custom date range button
              GestureDetector(
                onTap: _selectDateRange,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isCustomDateRange &&
                            !(_startDate != null &&
                                (_endDate!.difference(_startDate!).inDays ==
                                        0 ||
                                    _endDate!.difference(_startDate!).inDays ==
                                        2 ||
                                    _endDate!.difference(_startDate!).inDays ==
                                        6 ||
                                    _endDate!.difference(_startDate!).inDays ==
                                        13))
                        ? TColor.primaryColor1
                        : TColor.lightGray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: TColor.primaryColor1.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _isCustomDateRange &&
                                !(_startDate != null &&
                                    (_endDate!
                                                .difference(_startDate!)
                                                .inDays ==
                                            0 ||
                                        _endDate!
                                                .difference(_startDate!)
                                                .inDays ==
                                            2 ||
                                        _endDate!
                                                .difference(_startDate!)
                                                .inDays ==
                                            6 ||
                                        _endDate!
                                                .difference(_startDate!)
                                                .inDays ==
                                            13))
                            ? Colors.white
                            : TColor.gray,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Custom Range",
                        style: TextStyle(
                          color: _isCustomDateRange &&
                                  !(_startDate != null &&
                                      (_endDate!
                                                  .difference(_startDate!)
                                                  .inDays ==
                                              0 ||
                                          _endDate!
                                                  .difference(_startDate!)
                                                  .inDays ==
                                              2 ||
                                          _endDate!
                                                  .difference(_startDate!)
                                                  .inDays ==
                                              6 ||
                                          _endDate!
                                                  .difference(_startDate!)
                                                  .inDays ==
                                              13))
                              ? Colors.white
                              : TColor.gray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Reset button
              if (_isCustomDateRange)
                GestureDetector(
                  onTap: _resetDateFilter,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.clear,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Reset",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Show selected date range
          if (_isCustomDateRange && _startDate != null && _endDate != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TColor.primaryColor1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: TColor.primaryColor1.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 18,
                    color: TColor.primaryColor1,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Selected: ${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                    style: TextStyle(
                      color: TColor.primaryColor1,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),

          // Chart
          if (_chartData.isNotEmpty) ...[
            Text(
              "Daily ${_metrics.firstWhere((m) => m['key'] == _selectedMetric)['title']} Chart",
              style: TextStyle(
                color: TColor.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 300,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: TColor.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 2)
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _chartData.length) {
                            final date = _chartData[value.toInt()].date;
                            return Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value);
                      }).toList(),
                      isCurved: true,
                      color: _metrics.firstWhere(
                          (m) => m['key'] == _selectedMetric)['color'],
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _metrics
                            .firstWhere(
                                (m) => m['key'] == _selectedMetric)['color']
                            .withAlpha((0.3 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.show_chart, size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      "No daily data available",
                      style: TextStyle(color: TColor.gray),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Add workouts in selected date range",
                      style: TextStyle(color: TColor.gray, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Daily breakdown section
            _buildDailyBreakdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              "No Workouts Yet",
              style: TextStyle(
                color: TColor.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Add your first workout to get started",
              style: TextStyle(color: TColor.gray),
            ),
            const SizedBox(height: 30),
            RoundButton(
              title: "Add Workout",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutInputView(),
                  ),
                ).then((_) => _loadData());
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildWorkoutCard(record);
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, String current, String goal,
      double progress, Color color, String unit) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
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
                "$current / $goal $unit",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withAlpha((0.2 * 255).round()),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 5),
          Text(
            "${(progress * 100).toStringAsFixed(0)}% Complete",
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

  Widget _buildRecentWorkoutCard(WorkoutModel record) {
    final workoutType = WorkoutTypes.findByName(record.workoutType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutDetailView(workout: record),
            ),
          ).then((_) => _loadData());
        },
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: TColor.primaryColor1.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  workoutType?.icon ?? '🏃‍♂️',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.workoutType,
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${record.durationMinutes} min • ${record.caloriesBurned.toStringAsFixed(0)} kcal • ${DateFormat('MMM dd').format(record.date)}",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: TColor.gray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutModel record) {
    final workoutType = WorkoutTypes.findByName(record.workoutType);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    workoutType?.icon ?? '🏃‍♂️',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.workoutType,
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(record.date),
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkoutInputView(existingWorkout: record),
                      ),
                    ).then((_) => _loadData());
                  } else if (value == 'delete') {
                    final confirmed = await _showDeleteConfirmation();
                    if (confirmed && record.id != null) {
                      try {
                        await _workoutService.deleteWorkout(record.id!);
                        _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Workout deleted successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error deleting workout: $e')),
                          );
                        }
                      }
                    }
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
          const SizedBox(height: 15),

          // Workout metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                    "Duration", "${record.durationMinutes} min"),
              ),
              Expanded(
                child: _buildMetricItem("Calories",
                    "${record.caloriesBurned.toStringAsFixed(0)} kcal"),
              ),
              Expanded(
                child: _buildMetricItem(
                    "Category", workoutType?.category ?? 'Other'),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // View Details Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailView(workout: record),
                  ),
                ).then((_) => _loadData());
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: TColor.primaryColor1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                "View Details",
                style: TextStyle(color: TColor.primaryColor1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: TColor.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyOverviewSection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    // Get today's workouts
    final todayWorkouts = _records.where((record) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      return recordDate.isAtSameMomentAs(today);
    }).toList();

    // Get yesterday's workouts
    final yesterdayWorkouts = _records.where((record) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      return recordDate.isAtSameMomentAs(yesterday);
    }).toList();

    // Get two days ago workouts
    final twoDaysAgoWorkouts = _records.where((record) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      return recordDate.isAtSameMomentAs(twoDaysAgo);
    }).toList();

    // Calculate daily statistics
    final todayCalories = todayWorkouts.fold<double>(
        0.0, (sum, workout) => sum + workout.caloriesBurned);
    final yesterdayCalories = yesterdayWorkouts.fold<double>(
        0.0, (sum, workout) => sum + workout.caloriesBurned);
    final twoDaysAgoCalories = twoDaysAgoWorkouts.fold<double>(
        0.0, (sum, workout) => sum + workout.caloriesBurned);

    final todayMinutes = todayWorkouts.fold<int>(
        0, (sum, workout) => sum + workout.durationMinutes);
    final yesterdayMinutes = yesterdayWorkouts.fold<int>(
        0, (sum, workout) => sum + workout.durationMinutes);

    // Calculate changes from yesterday
    final calorieChange = yesterdayCalories > 0
        ? ((todayCalories - yesterdayCalories) / yesterdayCalories * 100)
        : 0.0;
    final workoutChange = yesterdayWorkouts.isNotEmpty
        ? ((todayWorkouts.length - yesterdayWorkouts.length) /
            yesterdayWorkouts.length *
            100)
        : 0.0;

    return Column(
      children: [
        // Today's stats summary cards
        Row(
          children: [
            Expanded(
              child: _buildDailyStatCard(
                "Today",
                "${todayWorkouts.length} workout${todayWorkouts.length != 1 ? 's' : ''}",
                Icons.today,
                todayWorkouts.isNotEmpty ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildDailyStatCard(
                "Calories Today",
                "${todayCalories.toStringAsFixed(0)} kcal",
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
              child: _buildDailyStatCard(
                "Duration Today",
                "$todayMinutes min",
                Icons.timer,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildDailyStatCard(
                "vs Yesterday",
                calorieChange >= 0
                    ? "+${calorieChange.toStringAsFixed(0)}%"
                    : "${calorieChange.toStringAsFixed(0)}%",
                calorieChange >= 0 ? Icons.trending_up : Icons.trending_down,
                calorieChange >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Daily comparison chart
        Container(
          height: 200,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daily Comparison (Last 3 Days)",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: [todayCalories, yesterdayCalories, twoDaysAgoCalories]
                            .isNotEmpty
                        ? [todayCalories, yesterdayCalories, twoDaysAgoCalories]
                                .reduce((a, b) => a > b ? a : b) *
                            1.2
                        : 1000,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return Text('2 days ago',
                                    style: TextStyle(
                                        color: TColor.gray, fontSize: 10));
                              case 1:
                                return Text('Yesterday',
                                    style: TextStyle(
                                        color: TColor.gray, fontSize: 10));
                              case 2:
                                return Text('Today',
                                    style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600));
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: twoDaysAgoCalories,
                            color: Colors.grey.withOpacity(0.6),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: yesterdayCalories,
                            color: Colors.orange.withOpacity(0.7),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: todayCalories,
                            color: TColor.primaryColor1.withOpacity(0.8),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // Daily breakdown list
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: TColor.lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "3-Day Comparison",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              // Today
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                decoration: BoxDecoration(
                  color: TColor.primaryColor1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: TColor.primaryColor1.withOpacity(0.3), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: TColor.primaryColor1,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.today,
                              size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Today",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "${todayWorkouts.length} workout${todayWorkouts.length != 1 ? 's' : ''}",
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "${todayCalories.toStringAsFixed(0)} kcal",
                          style: TextStyle(
                            color: TColor.primaryColor1,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Yesterday
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Yesterday",
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "${yesterdayWorkouts.length} workout${yesterdayWorkouts.length != 1 ? 's' : ''}",
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "${yesterdayCalories.toStringAsFixed(0)} kcal",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Two days ago
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEE, MMM dd').format(twoDaysAgo),
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "${twoDaysAgoWorkouts.length} workout${twoDaysAgoWorkouts.length != 1 ? 's' : ''}",
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "${twoDaysAgoCalories.toStringAsFixed(0)} kcal",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyStatCard(
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
            offset: const Offset(0, 3),
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
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    if (_chartData.isEmpty) return const SizedBox();

    final currentMetric =
        _metrics.firstWhere((m) => m['key'] == _selectedMetric);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily ${currentMetric['title']} Breakdown",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "${_chartData.length} days",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Calculate daily stats
          Builder(
            builder: (context) {
              final totalValue =
                  _chartData.fold<double>(0.0, (sum, data) => sum + data.value);
              final avgValue =
                  _chartData.isNotEmpty ? totalValue / _chartData.length : 0.0;
              final maxValue = _chartData.isNotEmpty
                  ? _chartData
                      .map((e) => e.value)
                      .reduce((a, b) => a > b ? a : b)
                  : 0.0;
              final minValue = _chartData.isNotEmpty
                  ? _chartData
                      .map((e) => e.value)
                      .reduce((a, b) => a < b ? a : b)
                  : 0.0;

              return Column(
                children: [
                  // Summary stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Total",
                          "${totalValue.toStringAsFixed(currentMetric['key'] == 'duration' ? 0 : 0)} ${currentMetric['unit']}",
                          Icons.summarize,
                          currentMetric['color'],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          "Average",
                          "${avgValue.toStringAsFixed(currentMetric['key'] == 'duration' ? 0 : 0)} ${currentMetric['unit']}",
                          Icons.trending_up,
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
                          "Best Day",
                          "${maxValue.toStringAsFixed(currentMetric['key'] == 'duration' ? 0 : 0)} ${currentMetric['unit']}",
                          Icons.star,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          "Lowest Day",
                          "${minValue.toStringAsFixed(currentMetric['key'] == 'duration' ? 0 : 0)} ${currentMetric['unit']}",
                          Icons.minimize,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Daily list
                  Column(
                    children: _chartData.map((data) {
                      final isToday =
                          DateFormat('yyyy-MM-dd').format(data.date) ==
                              DateFormat('yyyy-MM-dd').format(DateTime.now());
                      final isMaxValue = data.value == maxValue && maxValue > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isToday
                              ? TColor.primaryColor1.withOpacity(0.1)
                              : isMaxValue
                                  ? Colors.green.withOpacity(0.1)
                                  : TColor.lightGray.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? Border.all(
                                  color: TColor.primaryColor1.withOpacity(0.3))
                              : isMaxValue
                                  ? Border.all(
                                      color: Colors.green.withOpacity(0.3))
                                  : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? TColor.primaryColor1
                                        : isMaxValue
                                            ? Colors.green
                                            : currentMetric['color'],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    isToday
                                        ? Icons.today
                                        : isMaxValue
                                            ? Icons.star
                                            : Icons.calendar_today,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isToday
                                          ? "Today"
                                          : DateFormat('EEE, MMM dd')
                                              .format(data.date),
                                      style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 13,
                                        fontWeight: isToday
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (isMaxValue && !isToday)
                                      Text(
                                        "Best performance",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              "${data.value.toStringAsFixed(currentMetric['key'] == 'duration' ? 0 : 0)} ${currentMetric['unit']}",
                              style: TextStyle(
                                color: isToday
                                    ? TColor.primaryColor1
                                    : isMaxValue
                                        ? Colors.green
                                        : TColor.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(
      String label, VoidCallback onTap, bool isSelected) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TColor.primaryColor1 : TColor.lightGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? TColor.primaryColor1
                : TColor.primaryColor1.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : TColor.gray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
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
}
