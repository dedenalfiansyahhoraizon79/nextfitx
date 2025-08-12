import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/meal_model.dart';
import '../../services/meal_service.dart';
import 'meal_input_view.dart';
import 'meal_detail_view.dart';
import 'custom_food_input_view.dart';

class MealView extends StatefulWidget {
  const MealView({super.key});

  @override
  State<MealView> createState() => _MealViewState();
}

class _MealViewState extends State<MealView> with TickerProviderStateMixin {
  late TabController _tabController;
  final MealService _mealService = MealService();
  bool _isLoading = true;
  // Today's data
  List<MealModel> _todayMeals = [];
  Map<String, double> _todayNutrition = {};

  // Chart data
  List<MealChartData> _weeklyData = [];
  List<MealChartData> _monthlyData = [];
  bool _showWeeklyChart = true;

  // Summary data
  MealSummary? _weeklySummary;
  MealSummary? _monthlySummary;

  // Date filter variables
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isDateFilterActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load today's meals and nutrition
      final todayMeals = await _mealService.getTodayMeals();
      final todayNutrition = await _mealService.getTodayNutritionSummary();

      // Load chart data
      final weeklyData = await _mealService.getWeeklyChartData();
      final monthlyData = await _mealService.getMonthlyChartData();

      // Load summary data
      final endDate = DateTime.now();
      final weekStartDate = endDate.subtract(const Duration(days: 6));
      final monthStartDate = endDate.subtract(const Duration(days: 29));

      final weeklySummary = await _mealService.getMealSummary(
        startDate: weekStartDate,
        endDate: endDate,
      );

      final monthlySummary = await _mealService.getMealSummary(
        startDate: monthStartDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _todayMeals = todayMeals;
          _todayNutrition = todayNutrition;
          _weeklyData = weeklyData;
          _monthlyData = monthlyData;
          _weeklySummary = weeklySummary;
          _monthlySummary = monthlySummary;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading meal data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDebugDialog() async {
    try {
      final debugInfo = await _mealService.debugMealRecords();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Text("🐛 Meal Debug Info"),
              Spacer(),
              Icon(Icons.bug_report, color: Colors.orange),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Text(
                debugInfo,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            if (!debugInfo.contains('No meal records found'))
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _generateSampleData();
                },
                child: const Text("Generate Sample Data"),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateSampleData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating sample meal data..."),
            ],
          ),
        ),
      );

      await _mealService.generateSampleMealData();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Refresh data
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sample meal data generated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating sample data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _loadChartDataWithFilter() async {
    try {
      List<MealChartData> filteredData = [];
      MealSummary? filteredSummary;

      if (_isDateFilterActive &&
          _filterStartDate != null &&
          _filterEndDate != null) {
        // Get meals for the specified date range
        final meals = await _mealService.getMealsForDateRange(
            _filterStartDate!, _filterEndDate!);

        // Convert to chart data by grouping by date
        final groupedMeals = <DateTime, List<MealModel>>{};
        for (final meal in meals) {
          final dateKey =
              DateTime(meal.date.year, meal.date.month, meal.date.day);
          if (!groupedMeals.containsKey(dateKey)) {
            groupedMeals[dateKey] = [];
          }
          groupedMeals[dateKey]!.add(meal);
        }

        // Create chart data points
        filteredData = groupedMeals.entries.map((entry) {
          final dailyCalories =
              entry.value.fold<double>(0, (sum, meal) => sum + meal.calories);
          return MealChartData(
            date: entry.key,
            calories: dailyCalories,
            protein:
                entry.value.fold<double>(0, (sum, meal) => sum + meal.protein),
            carbs: entry.value.fold<double>(0, (sum, meal) => sum + meal.carbs),
            fat: entry.value.fold<double>(0, (sum, meal) => sum + meal.fat),
          );
        }).toList();

        // Sort by date
        filteredData.sort((a, b) => a.date.compareTo(b.date));

        // Get summary for the filtered period
        filteredSummary = await _mealService.getMealSummary(
          startDate: _filterStartDate!,
          endDate: _filterEndDate!,
        );
      } else {
        // Load default data (weekly/monthly)
        if (_showWeeklyChart) {
          filteredData = await _mealService.getWeeklyChartData();
          final endDate = DateTime.now();
          final weekStartDate = endDate.subtract(const Duration(days: 6));
          filteredSummary = await _mealService.getMealSummary(
            startDate: weekStartDate,
            endDate: endDate,
          );
        } else {
          filteredData = await _mealService.getMonthlyChartData();
          final endDate = DateTime.now();
          final monthStartDate = endDate.subtract(const Duration(days: 29));
          filteredSummary = await _mealService.getMealSummary(
            startDate: monthStartDate,
            endDate: endDate,
          );
        }
      }

      if (mounted) {
        setState(() {
          if (_showWeeklyChart || _isDateFilterActive) {
            _weeklyData = filteredData;
            _weeklySummary = filteredSummary;
          } else {
            _monthlyData = filteredData;
            _monthlySummary = filteredSummary;
          }
        });
      }
    } catch (e) {
      print('Error loading filtered chart data: $e');
    }
  }

  void _resetDateFilter() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
      _isDateFilterActive = false;
    });
    _loadChartDataWithFilter();
  }

  void _applyDateFilter() {
    if (_filterStartDate != null && _filterEndDate != null) {
      setState(() {
        _isDateFilterActive = true;
      });
      _loadChartDataWithFilter();
    }
  }

  Widget _buildDateFilterSection() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TColor.primaryColor1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.date_range,
                  color: TColor.primaryColor1,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Date Filter",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_isDateFilterActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Active",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),

          // Date Selection Row
          Row(
            children: [
              // Start Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Start Date",
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectStartDate(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColor.lightGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _filterStartDate != null
                                ? TColor.primaryColor1.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: _filterStartDate != null
                                  ? TColor.primaryColor1
                                  : TColor.gray,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _filterStartDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(_filterStartDate!)
                                    : "Select start date",
                                style: TextStyle(
                                  color: _filterStartDate != null
                                      ? TColor.black
                                      : TColor.gray,
                                  fontSize: 14,
                                  fontWeight: _filterStartDate != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 15),

              // End Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "End Date",
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectEndDate(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColor.lightGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _filterEndDate != null
                                ? TColor.primaryColor1.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: _filterEndDate != null
                                  ? TColor.primaryColor1
                                  : TColor.gray,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _filterEndDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(_filterEndDate!)
                                    : "Select end date",
                                style: TextStyle(
                                  color: _filterEndDate != null
                                      ? TColor.black
                                      : TColor.gray,
                                  fontSize: 14,
                                  fontWeight: _filterEndDate != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Action Buttons
          Row(
            children: [
              // Quick Filter Buttons
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickFilterButton("7D", 7),
                    _buildQuickFilterButton("30D", 30),
                    _buildQuickFilterButton("90D", 90),
                  ],
                ),
              ),
              const SizedBox(width: 15),

              // Apply/Reset Buttons
              if (_filterStartDate != null && _filterEndDate != null) ...[
                if (!_isDateFilterActive)
                  ElevatedButton(
                    onPressed: _applyDateFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primaryColor1,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text("Apply"),
                  ),
                if (_isDateFilterActive) ...[
                  ElevatedButton(
                    onPressed: _resetDateFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text("Reset"),
                  ),
                ],
              ],
            ],
          ),

          // Filter Info
          if (_isDateFilterActive &&
              _filterStartDate != null &&
              _filterEndDate != null) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Showing data from ${DateFormat('dd MMM yyyy').format(_filterStartDate!)} to ${DateFormat('dd MMM yyyy').format(_filterEndDate!)}",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFilterButton(String label, int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final isActive = _isDateFilterActive &&
        _filterStartDate != null &&
        _filterEndDate != null &&
        _filterStartDate!.difference(startDate).inDays.abs() <= 1 &&
        _filterEndDate!.difference(endDate).inDays.abs() <= 1;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStartDate = startDate;
          _filterEndDate = endDate;
        });
        _applyDateFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? TColor.primaryColor1 : TColor.lightGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? TColor.primaryColor1 : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : TColor.gray,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _filterStartDate ?? firstDate,
      firstDate: firstDate,
      lastDate: _filterEndDate ?? now,
    );

    if (selectedDate != null) {
      setState(() {
        _filterStartDate = selectedDate;
        if (_isDateFilterActive) {
          _isDateFilterActive =
              false; // Reset active state to show apply button
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();
    final firstDate =
        _filterStartDate ?? now.subtract(const Duration(days: 365));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _filterEndDate ?? now,
      firstDate: firstDate,
      lastDate: now,
    );

    if (selectedDate != null) {
      setState(() {
        _filterEndDate = selectedDate;
        if (_isDateFilterActive) {
          _isDateFilterActive =
              false; // Reset active state to show apply button
        }
      });
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
          "Meal Tracker",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Add Meal Button
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealInputView(),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TColor.primaryColor1,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          // Debug Button
          InkWell(
            onTap: () => _showDebugDialog(),
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                "🐛",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TColor.primaryColor1,
          labelColor: TColor.primaryColor1,
          unselectedLabelColor: TColor.gray,
          labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Charts"),
            Tab(text: "Records"),
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
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildRecordsTab(),
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
          // Today's Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: TColor.primaryG),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: TColor.primaryG.first.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Nutrition",
                  style: TextStyle(
                    color: TColor.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNutritionItem(
                      "Calories",
                      "${_todayNutrition['calories']?.toStringAsFixed(0) ?? '0'} kcal",
                      Icons.local_fire_department,
                    ),
                    _buildNutritionItem(
                      "Protein",
                      "${_todayNutrition['protein']?.toStringAsFixed(1) ?? '0'} g",
                      Icons.fitness_center,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNutritionItem(
                      "Carbs",
                      "${_todayNutrition['carbs']?.toStringAsFixed(1) ?? '0'} g",
                      Icons.grain,
                    ),
                    _buildNutritionItem(
                      "Fat",
                      "${_todayNutrition['fat']?.toStringAsFixed(1) ?? '0'} g",
                      Icons.water_drop,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Weekly Summary
          if (_weeklySummary != null) ...[
            Text(
              "This Week Summary",
              style: TextStyle(
                color: TColor.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                        "Total Meals",
                        _weeklySummary!.totalMeals.toString(),
                        Colors.blue,
                      ),
                      _buildSummaryItem(
                        "Avg Calories",
                        "${(_weeklySummary!.totalCalories / 7).toStringAsFixed(0)}/day",
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                        "Total Protein",
                        "${_weeklySummary!.totalProtein.toStringAsFixed(0)}g",
                        Colors.green,
                      ),
                      _buildSummaryItem(
                        "Most Eaten",
                        _getMostEatenMealType(_weeklySummary!.mealTypeCount),
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 25),

          // Today's Meals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Meals (${_todayMeals.length})",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_todayMeals.isNotEmpty)
                TextButton(
                  onPressed: () => _tabController.animateTo(2),
                  child: Text(
                    "View All",
                    style: TextStyle(
                      color: TColor.primaryColor1,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_todayMeals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "No meals recorded today",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Tap the + button to add your first meal",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_todayMeals.take(3).map((meal) => _buildMealItem(meal))),

          const SizedBox(height: 20),
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
          // Date Filter Section
          _buildDateFilterSection(),
          const SizedBox(height: 25),

          // Chart Type Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showWeeklyChart = true);
                      _loadChartDataWithFilter();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showWeeklyChart
                            ? TColor.primaryColor1
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Weekly",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _showWeeklyChart ? Colors.white : TColor.gray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showWeeklyChart = false);
                      _loadChartDataWithFilter();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showWeeklyChart
                            ? TColor.primaryColor1
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Monthly",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_showWeeklyChart ? Colors.white : TColor.gray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Calories Chart
          Text(
            "Daily Calories",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _buildCaloriesChart(),
          ),

          const SizedBox(height: 25),

          // Macros Distribution
          Text(
            "Macronutrients Distribution",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _buildMacrosChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    return StreamBuilder<List<MealModel>>(
      stream: _mealService.getMealRecordsStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
            ),
          );
        }

        final meals = snapshot.data ?? [];

        if (meals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  "No meals recorded yet",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Start tracking your meals to see them here",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
                RoundButton(
                  title: "Add First Meal",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MealInputView(),
                      ),
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
                ),
                const SizedBox(height: 15),
                RoundButton(
                  title: "Generate Sample Data",
                  type: RoundButtonType.bgGradient,
                  onPressed: () => _generateSampleData(),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomFoodInputView(),
                      ),
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text("Create Custom Food"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TColor.primaryColor1,
                    side: BorderSide(color: TColor.primaryColor1),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Group meals by date
        final groupedMeals = <String, List<MealModel>>{};
        for (final meal in meals) {
          final dateKey = DateFormat('yyyy-MM-dd').format(meal.date);
          if (!groupedMeals.containsKey(dateKey)) {
            groupedMeals[dateKey] = [];
          }
          groupedMeals[dateKey]!.add(meal);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groupedMeals.length,
          itemBuilder: (context, index) {
            final dateKey = groupedMeals.keys.elementAt(index);
            final dayMeals = groupedMeals[dateKey]!;
            final date = DateTime.parse(dateKey);

            return _buildDayMealsSection(date, dayMeals);
          },
        );
      },
    );
  }

  Widget _buildNutritionItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 20),
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
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
        ),
      ],
    );
  }

  Widget _buildMealItem(MealModel meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: TColor.primaryG),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getMealIcon(meal.mealType),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${meal.mealType} • ${meal.weightGrams.toStringAsFixed(0)}g",
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
                "${meal.calories.toStringAsFixed(0)} kcal",
                style: TextStyle(
                  color: TColor.primaryColor1,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(meal.date),
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayMealsSection(DateTime date, List<MealModel> meals) {
    final dayNutrition = NutritionCalculator.calculateDailySummary(meals);
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isToday
                  ? TColor.primaryColor1.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday
                      ? "Today, ${DateFormat('MMM d').format(date)}"
                      : DateFormat('EEEE, MMM d').format(date),
                  style: TextStyle(
                    color: isToday ? TColor.primaryColor1 : TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${dayNutrition['calories']?.toStringAsFixed(0)} kcal",
                  style: TextStyle(
                    color: isToday ? TColor.primaryColor1 : TColor.gray,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Meals for this day
          ...meals.map((meal) => GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MealDetailView(meal: meal),
                    ),
                  );
                  _loadData();
                },
                child: _buildMealItem(meal),
              )),
        ],
      ),
    );
  }

  Widget _buildCaloriesChart() {
    final data = _showWeeklyChart ? _weeklyData : _monthlyData;

    if (data.isEmpty) {
      return Center(
        child: Text(
          "No data available",
          style: TextStyle(color: TColor.gray),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final date = data[value.toInt()].date;
                  return Text(
                    DateFormat('M/d').format(date),
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.calories))
                .toList(),
            isCurved: true,
            color: TColor.primaryColor1,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: TColor.primaryColor1.withOpacity(0.1),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: TColor.primaryColor1,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosChart() {
    final summary = _showWeeklyChart ? _weeklySummary : _monthlySummary;

    if (summary == null) {
      return Center(
        child: Text(
          "No data available",
          style: TextStyle(color: TColor.gray),
        ),
      );
    }

    final total = summary.totalProtein + summary.totalCarbs + summary.totalFat;
    if (total == 0) {
      return Center(
        child: Text(
          "No macronutrient data",
          style: TextStyle(color: TColor.gray),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: summary.totalProtein,
                  title:
                      '${((summary.totalProtein / total) * 100).toStringAsFixed(0)}%',
                  color: Colors.blue,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: summary.totalCarbs,
                  title:
                      '${((summary.totalCarbs / total) * 100).toStringAsFixed(0)}%',
                  color: Colors.green,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: summary.totalFat,
                  title:
                      '${((summary.totalFat / total) * 100).toStringAsFixed(0)}%',
                  color: Colors.orange,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMacroLegend("Protein",
                  "${summary.totalProtein.toStringAsFixed(0)}g", Colors.blue),
              const SizedBox(height: 10),
              _buildMacroLegend("Carbs",
                  "${summary.totalCarbs.toStringAsFixed(0)}g", Colors.green),
              const SizedBox(height: 10),
              _buildMacroLegend("Fat",
                  "${summary.totalFat.toStringAsFixed(0)}g", Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroLegend(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  String _getMostEatenMealType(Map<String, int> mealTypeCount) {
    if (mealTypeCount.isEmpty) return "None";

    String mostEaten = mealTypeCount.keys.first;
    int maxCount = mealTypeCount.values.first;

    for (final entry in mealTypeCount.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostEaten = entry.key;
      }
    }

    return mostEaten;
  }
}
