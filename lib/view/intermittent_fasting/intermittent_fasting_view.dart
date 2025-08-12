import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/intermittent_fasting_model.dart';
import '../../services/intermittent_fasting_service.dart';
import 'fasting_input_view.dart';
import 'fasting_detail_view.dart';

class IntermittentFastingView extends StatefulWidget {
  const IntermittentFastingView({super.key});

  @override
  State<IntermittentFastingView> createState() =>
      _IntermittentFastingViewState();
}

class _IntermittentFastingViewState extends State<IntermittentFastingView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final IntermittentFastingService _fastingService =
      IntermittentFastingService();
  bool _isLoading = true;
  Timer? _timer;

  // Current active fasting
  FastingModel? _activeFasting;

  // Chart data
  List<FastingChartData> _weeklyData = [];
  List<FastingChartData> _monthlyData = [];
  bool _showWeeklyChart = true;

  // Summary data
  FastingSummary? _weeklySummary;
  FastingSummary? _monthlySummary;  
  Map<String, String> _insights = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeFasting != null && mounted) {
        setState(() {
          // Update the UI every second for live timer
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load active fasting
      final activeFasting = await _fastingService.getActiveFasting();

      // Load chart data
      final weeklyData = await _fastingService.getWeeklyChartData();
      final monthlyData = await _fastingService.getMonthlyChartData();

      // Load summary data
      final endDate = DateTime.now();
      final weekStartDate = endDate.subtract(const Duration(days: 6));
      final monthStartDate = endDate.subtract(const Duration(days: 29));

      final weeklySummary = await _fastingService.getFastingSummary(
        startDate: weekStartDate,
        endDate: endDate,
      );

      final monthlySummary = await _fastingService.getFastingSummary(
        startDate: monthStartDate,
        endDate: endDate,
      );

      // Load insights
      final insights = await _fastingService.getFastingInsights();

      if (mounted) {
        setState(() {
          _activeFasting = activeFasting;
          _weeklyData = weeklyData;
          _monthlyData = monthlyData;
          _weeklySummary = weeklySummary;
          _monthlySummary = monthlySummary;
          _insights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading fasting data: $e');
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
          "Intermittent Fasting",
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
              final debugInfo = await _fastingService.debugFastingRecords();
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
          // Add fasting button
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FastingInputView(),
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
            Tab(text: "Timer"),
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
                _buildTimerTab(),
                _buildChartsTab(),
                _buildRecordsTab(),
              ],
            ),
    );
  }

  Widget _buildTimerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Fasting Timer
          if (_activeFasting != null) ...[
            _buildActiveTimer(),
            const SizedBox(height: 30),
            _buildTimerActions(),
          ] else ...[
            _buildNoActiveFasting(),
          ],

          const SizedBox(height: 30),

          // Quick Stats
          if (_weeklySummary != null) ...[
            Text(
              "This Week",
              style: TextStyle(
                color: TColor.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            _buildQuickStats(),
          ],

          const SizedBox(height: 30),

          // Fasting Insights
          if (_insights.isNotEmpty) ...[
            Text(
              "Insights",
              style: TextStyle(
                color: TColor.black,
                fontSize: 18,
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

          // Fasting Duration Chart
          Text(
            "Fasting Duration Trend",
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
            child: _buildFastingDurationChart(),
          ),

          const SizedBox(height: 25),

          // Completion Rate Chart
          Text(
            "Fasting Type Distribution",
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
            child: _buildFastingTypeChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    return StreamBuilder<List<FastingModel>>(
      stream: _fastingService.getFastingRecordsStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
            ),
          );
        }

        final fastingRecords = snapshot.data ?? [];

        if (fastingRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  "No fasting records yet",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Start your first fast to see records here",
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
                      title: "Start First Fast",
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FastingInputView(),
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
                          await _fastingService.generateSampleFastingData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sample fasting data generated!'),
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

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: fastingRecords.length,
          itemBuilder: (context, index) {
            final fasting = fastingRecords[index];
            return _buildFastingRecordCard(fasting);
          },
        );
      },
    );
  }

  Widget _buildActiveTimer() {
    if (_activeFasting == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A5ACD),
            const Color(0xFF4169E1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A5ACD).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _activeFasting!.fastingType.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeFasting!.fastingType.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      FastingStatus.active.displayName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _activeFasting!.status.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Timer Display
          Text(
            _activeFasting!.currentDurationFormatted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          // Progress Bar
          Column(
            children: [
              LinearProgressIndicator(
                value: _activeFasting!.progressPercentage / 100,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Progress: ${_activeFasting!.progressPercentage.toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "Remaining: ${_activeFasting!.remainingTimeFormatted}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Target Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimerStat(
                      "Started",
                      DateFormat('h:mm a').format(_activeFasting!.startTime),
                      Icons.play_arrow,
                    ),
                    _buildTimerStat(
                      "Target",
                      "${_activeFasting!.targetDurationHours}h",
                      Icons.flag,
                    ),
                    _buildTimerStat(
                      "Ends At",
                      DateFormat('h:mm a')
                          .format(_activeFasting!.estimatedEndTime),
                      Icons.stop,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerActions() {
    if (_activeFasting == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: RoundButton(
            title: _activeFasting!.status == FastingStatus.paused
                ? "Resume"
                : "Pause",
            type: RoundButtonType.textGradient,
            onPressed: () async {
              try {
                if (_activeFasting!.status == FastingStatus.paused) {
                  await _fastingService.resumeFasting(_activeFasting!.id!);
                } else {
                  await _fastingService.pauseFasting(_activeFasting!.id!);
                }
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: RoundButton(
            title: "End Fast",
            onPressed: () async {
              _showEndFastDialog();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveFasting() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            "No Active Fast",
            style: TextStyle(
              color: TColor.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Start a new fasting session to track your progress",
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          RoundButton(
            title: "Start Fasting",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FastingInputView(),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Completed",
            "${_weeklySummary!.completedFasts}",
            "This week",
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            "Avg Duration",
            _weeklySummary!.averageDurationFormatted,
            "Per fast",
            Icons.timer,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            "Streak",
            "${_weeklySummary!.currentStreak}",
            "Days",
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
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
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

  Widget _buildFastingRecordCard(FastingModel fasting) {
    final isToday = DateFormat('yyyy-MM-dd').format(fasting.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FastingDetailView(fasting: fasting),
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
                Row(
                  children: [
                    Text(
                      fasting.fastingType.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? "Today, ${DateFormat('MMM d').format(fasting.date)}"
                              : DateFormat('EEEE, MMM d').format(fasting.date),
                          style: TextStyle(
                            color:
                                isToday ? TColor.primaryColor1 : TColor.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          fasting.fastingType.displayName,
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(fasting.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${fasting.status.icon} ${fasting.status.displayName}",
                    style: TextStyle(
                      color: _getStatusColor(fasting.status),
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
                    "Duration", fasting.currentDurationFormatted, Icons.timer),
                _buildRecordStat(
                    "Target", "${fasting.targetDurationHours}h", Icons.flag),
                _buildRecordStat(
                    "Progress",
                    "${fasting.progressPercentage.toStringAsFixed(0)}%",
                    Icons.trending_up),
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

  Widget _buildFastingDurationChart() {
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
            color: const Color(0xFF6A5ACD),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF6A5ACD).withOpacity(0.1),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF6A5ACD),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
        minY: 0,
        maxY: 36,
      ),
    );
  }

  Widget _buildFastingTypeChart() {
    final data = _showWeeklyChart ? _weeklyData : _monthlyData;

    if (data.isEmpty) {
      return Center(
        child: Text(
          "No data available",
          style: TextStyle(color: TColor.gray),
        ),
      );
    }

    // Calculate type distribution
    Map<FastingType, int> typeCount = {};
    for (final fasting in data) {
      typeCount[fasting.fastingType] =
          (typeCount[fasting.fastingType] ?? 0) + 1;
    }

    if (typeCount.isEmpty) {
      return Center(
        child: Text(
          "No type data",
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
              sections: typeCount.entries.map((entry) {
                final type = entry.key;
                final count = entry.value;
                return PieChartSectionData(
                  value: count.toDouble(),
                  title: type.icon,
                  color: _getFastingTypeColor(type),
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
            children: typeCount.entries.map((entry) {
              final type = entry.key;
              final count = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildTypeLegend(type.displayName, count.toString(),
                    _getFastingTypeColor(type)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeLegend(String label, String value, Color color) {
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
          ),
        ),
      ],
    );
  }

  void _showEndFastDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Fasting'),
        content:
            const Text('Are you sure you want to end this fasting session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endFasting(FastingStatus.completed);
            },
            child: const Text('Complete'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endFasting(FastingStatus.broken);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Break'),
          ),
        ],
      ),
    );
  }

  Future<void> _endFasting(FastingStatus status) async {
    try {
      await _fastingService.endFasting(
        fastingId: _activeFasting!.id!,
        status: status,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Fasting ${status.displayName.toLowerCase()} successfully!'),
          backgroundColor:
              status == FastingStatus.completed ? Colors.green : Colors.orange,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ending fasting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(FastingStatus status) {
    switch (status) {
      case FastingStatus.active:
        return Colors.green;
      case FastingStatus.completed:
        return Colors.blue;
      case FastingStatus.broken:
        return Colors.red;
      case FastingStatus.paused:
        return Colors.orange;
    }
  }

  Color _getFastingTypeColor(FastingType type) {
    switch (type) {
      case FastingType.sixteen_eight:
        return const Color(0xFF4CAF50);
      case FastingType.eighteen_six:
        return const Color(0xFFFF9800);
      case FastingType.twenty_four:
        return const Color(0xFFF44336);
      case FastingType.twenty_four_extended:
        return const Color(0xFF9C27B0);
      case FastingType.custom:
        return const Color(0xFF2196F3);
    }
  }

  String _getInsightTitle(String key) {
    switch (key) {
      case 'completion':
        return 'Completion Rate';
      case 'duration':
        return 'Fasting Duration';
      case 'streak':
        return 'Consistency';
      default:
        return 'Insight';
    }
  }

  IconData _getInsightIcon(String key) {
    switch (key) {
      case 'completion':
        return Icons.check_circle;
      case 'duration':
        return Icons.timer;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.info;
    }
  }
}
