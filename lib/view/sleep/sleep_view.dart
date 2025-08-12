import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/sleep_model.dart';
import '../../services/sleep_service.dart';
import 'sleep_input_view.dart';
import 'sleep_detail_view.dart';

class SleepView extends StatefulWidget {
  const SleepView({super.key});

  @override
  State<SleepView> createState() => _SleepViewState();
}

class _SleepViewState extends State<SleepView> with TickerProviderStateMixin {
  late TabController _tabController;
  final SleepService _sleepService = SleepService();
  bool _isLoading = true;

  // Today's data
  SleepModel? _lastNightSleep;
  double _sleepDebt = 0.0;
  int _sleepStreak = 0;

  // Chart data
  List<SleepChartData> _weeklyData = [];
  List<SleepChartData> _monthlyData = [];
  bool _showWeeklyChart = true;

  // Summary data
  SleepSummary? _weeklySummary;
  SleepSummary? _monthlySummary;
  Map<String, String> _insights = {};

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
      // Load last night's sleep and today's metrics
      final lastNightSleep = await _sleepService.getLastNightSleep();
      final sleepDebt = await _sleepService.getSleepDebt(days: 7);
      final sleepStreak = await _sleepService.getSleepStreak();

      // Load chart data
      final weeklyData = await _sleepService.getWeeklyChartData();
      final monthlyData = await _sleepService.getMonthlyChartData();

      // Load summary data
      final endDate = DateTime.now();
      final weekStartDate = endDate.subtract(const Duration(days: 6));
      final monthStartDate = endDate.subtract(const Duration(days: 29));

      final weeklySummary = await _sleepService.getSleepSummary(
        startDate: weekStartDate,
        endDate: endDate,
      );

      final monthlySummary = await _sleepService.getSleepSummary(
        startDate: monthStartDate,
        endDate: endDate,
      );

      // Load insights
      final insights = await _sleepService.getSleepInsights();

      if (mounted) {
        setState(() {
          _lastNightSleep = lastNightSleep;
          _sleepDebt = sleepDebt;
          _sleepStreak = sleepStreak;
          _weeklyData = weeklyData;
          _monthlyData = monthlyData;
          _weeklySummary = weeklySummary;
          _monthlySummary = monthlySummary;
          _insights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sleep data: $e');
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
          "Sleep Tracker",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Debug button
          IconButton(
            onPressed: () async {
              final debugInfo = await _sleepService.debugSleepRecords();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Debug Info'),
                  content: SingleChildScrollView(
                    child: Text(debugInfo.toString()),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.bug_report, color: Colors.orange),
          ),
          // Add sleep button
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SleepInputView(),
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
          // Last Night's Sleep Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0),
                  const Color(0xFF673AB7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bedtime,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Last Night's Sleep",
                      style: TextStyle(
                        color: TColor.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (_lastNightSleep != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSleepStat(
                        "Duration",
                        _lastNightSleep!.durationFormatted,
                        Icons.timer,
                      ),
                      _buildSleepStat(
                        "Quality",
                        "${SleepQuality.getEmoji(_lastNightSleep!.quality)} ${_lastNightSleep!.qualityText}",
                        Icons.star,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSleepStat(
                        "Bedtime",
                        _lastNightSleep!.bedtimeFormatted,
                        Icons.brightness_2,
                      ),
                      _buildSleepStat(
                        "Wake Time",
                        _lastNightSleep!.wakeTimeFormatted,
                        Icons.wb_sunny,
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.bedtime_outlined,
                          color: Colors.white70,
                          size: 48,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No sleep recorded for last night",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Sleep Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Sleep Debt",
                  "${_sleepDebt.toStringAsFixed(1)}h",
                  "Last 7 days",
                  Icons.warning_amber,
                  _sleepDebt > 5
                      ? Colors.red
                      : _sleepDebt > 2
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildMetricCard(
                  "Sleep Streak",
                  "$_sleepStreak days",
                  "Healthy sleep",
                  Icons.local_fire_department,
                  _sleepStreak >= 7
                      ? Colors.green
                      : _sleepStreak >= 3
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
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
                        "Avg Duration",
                        _weeklySummary!.averageDurationFormatted,
                        Colors.blue,
                      ),
                      _buildSummaryItem(
                        "Avg Quality",
                        _weeklySummary!.averageQuality.toStringAsFixed(1),
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                        "Healthy Nights",
                        "${_weeklySummary!.daysWithHealthySleep}/${_weeklySummary!.totalNights}",
                        Colors.green,
                      ),
                      _buildSummaryItem(
                        "Consistency",
                        _weeklySummary!.consistencyRating,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 25),

          // Sleep Insights
          if (_insights.isNotEmpty) ...[
            Text(
              "Sleep Insights",
              style: TextStyle(
                color: TColor.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            ..._insights.entries.map((insight) => _buildInsightCard(
                  _getInsightTitle(insight.key),
                  insight.value,
                  _getInsightIcon(insight.key),
                )),
          ],

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
                    onTap: () => setState(() => _showWeeklyChart = true),
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
                    onTap: () => setState(() => _showWeeklyChart = false),
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

          // Sleep Duration Chart
          Text(
            "Sleep Duration Trend",
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
            child: _buildSleepDurationChart(),
          ),

          const SizedBox(height: 25),

          // Sleep Quality Chart
          Text(
            "Sleep Quality Distribution",
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
            child: _buildSleepQualityChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    return StreamBuilder<List<SleepModel>>(
      stream: _sleepService.getSleepRecordsStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
            ),
          );
        }

        final sleepRecords = snapshot.data ?? [];

        if (sleepRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bedtime,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  "No sleep records yet",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Start tracking your sleep to see records here",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundButton(
                      title: "Add First Record",
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SleepInputView(),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                    ),
                    const SizedBox(width: 15),
                    RoundButton(
                      title: "Generate Sample Data",
                      type: RoundButtonType.textGradient,
                      onPressed: () async {
                        try {
                          await _sleepService.generateSampleSleepData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sample sleep data generated!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadData();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Group sleep records by date
        final groupedSleep = <String, SleepModel>{};
        for (final sleep in sleepRecords) {
          final dateKey = DateFormat('yyyy-MM-dd').format(sleep.date);
          groupedSleep[dateKey] = sleep;
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groupedSleep.length,
          itemBuilder: (context, index) {
            final dateKey = groupedSleep.keys.elementAt(index);
            final sleep = groupedSleep[dateKey]!;

            return _buildSleepRecordCard(sleep);
          },
        );
      },
    );
  }

  Widget _buildSleepStat(String label, String value, IconData icon) {
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

  Widget _buildMetricCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
              fontSize: 14,
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

  Widget _buildInsightCard(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: TColor.primaryColor1.withOpacity(0.2)),
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
              icon,
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
                  title,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepRecordCard(SleepModel sleep) {
    final isToday = DateFormat('yyyy-MM-dd').format(sleep.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SleepDetailView(sleep: sleep),
          ),
        );
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: isToday
              ? Border.all(color: TColor.primaryColor1, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
                  isToday
                      ? "Today, ${DateFormat('MMM d').format(sleep.date)}"
                      : DateFormat('EEEE, MMM d').format(sleep.date),
                  style: TextStyle(
                    color: isToday ? TColor.primaryColor1 : TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getQualityColor(sleep.quality).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${SleepQuality.getEmoji(sleep.quality)} ${sleep.qualityText}",
                    style: TextStyle(
                      color: _getQualityColor(sleep.quality),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRecordStat(
                    "Duration", sleep.durationFormatted, Icons.timer),
                _buildRecordStat(
                    "Bedtime", sleep.bedtimeFormatted, Icons.brightness_2),
                _buildRecordStat(
                    "Wake Time", sleep.wakeTimeFormatted, Icons.wb_sunny),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: TColor.gray, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: TColor.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepDurationChart() {
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
                .map((e) => FlSpot(e.key.toDouble(), e.value.durationHours))
                .toList(),
            isCurved: true,
            color: const Color(0xFF9C27B0),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF9C27B0).withOpacity(0.1),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF9C27B0),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
        minY: 0,
        maxY: 12,
      ),
    );
  }

  Widget _buildSleepQualityChart() {
    final data = _showWeeklyChart ? _weeklyData : _monthlyData;

    if (data.isEmpty) {
      return Center(
        child: Text(
          "No data available",
          style: TextStyle(color: TColor.gray),
        ),
      );
    }

    // Calculate quality distribution
    Map<int, int> qualityCount = {};
    for (final sleep in data) {
      qualityCount[sleep.quality] = (qualityCount[sleep.quality] ?? 0) + 1;
    }

    if (qualityCount.isEmpty) {
      return Center(
        child: Text(
          "No quality data",
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
              sections: qualityCount.entries.map((entry) {
                final quality = entry.key;
                final count = entry.value;
                return PieChartSectionData(
                  value: count.toDouble(),
                  title: SleepQuality.getEmoji(quality),
                  color: _getQualityColor(quality),
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: SleepQuality.all.map((quality) {
              final count = qualityCount[quality] ?? 0;
              if (count == 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildQualityLegend(SleepQuality.getText(quality),
                    count.toString(), _getQualityColor(quality)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityLegend(String label, String value, Color color) {
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

  Color _getQualityColor(int quality) {
    switch (quality) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green.shade600;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getInsightTitle(String key) {
    switch (key) {
      case 'duration':
        return 'Sleep Duration';
      case 'quality':
        return 'Sleep Quality';
      case 'consistency':
        return 'Sleep Consistency';
      default:
        return 'Insight';
    }
  }

  IconData _getInsightIcon(String key) {
    switch (key) {
      case 'duration':
        return Icons.timer;
      case 'quality':
        return Icons.star;
      case 'consistency':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }
}
