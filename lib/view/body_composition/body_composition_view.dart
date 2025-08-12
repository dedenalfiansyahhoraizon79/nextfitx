import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/body_composition_model.dart';
import '../../services/body_composition_service.dart';
import 'body_composition_input_view.dart';
import 'body_composition_detail_view.dart';

class BodyCompositionView extends StatefulWidget {
  const BodyCompositionView({super.key});

  @override
  State<BodyCompositionView> createState() => _BodyCompositionViewState();
}

class _BodyCompositionViewState extends State<BodyCompositionView>
    with TickerProviderStateMixin {
  final BodyCompositionService _bodyCompositionService =
      BodyCompositionService();
  late TabController _tabController;

  bool _isLoading = true;
  String _errorMessage = '';
  List<BodyCompositionModel> _records = [];
  BodyCompositionSummary? _summary;
  String _selectedMetric = 'weight';
  List<BodyCompositionChartData> _chartData = [];

  // Date filter variables
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isDateFilterActive = false;

  final List<Map<String, dynamic>> _metrics = [
    // Body Parameters
    {
      'key': 'weight',
      'title': 'Weight',
      'unit': 'kg',
      'color': Colors.blue,
      'category': 'Body Parameters'
    },
    {
      'key': 'percentBodyFat',
      'title': 'Percent Body Fat',
      'unit': '%',
      'color': Colors.red,
      'category': 'Body Parameters'
    },
    {
      'key': 'visceralFatIndex',
      'title': 'Visceral Fat Index',
      'unit': 'level',
      'color': Colors.pink,
      'category': 'Body Parameters'
    },
    {
      'key': 'basalMetabolicRate',
      'title': 'Basal Metabolic Rate',
      'unit': 'kcal',
      'color': Colors.amber,
      'category': 'Body Parameters'
    },
    {
      'key': 'totalEnergyExpenditure',
      'title': 'Total Energy Expenditure',
      'unit': 'kcal',
      'color': Colors.orange,
      'category': 'Body Parameters'
    },
    {
      'key': 'physicalAge',
      'title': 'Physical Age',
      'unit': 'years',
      'color': Colors.deepOrange,
      'category': 'Body Parameters'
    },
    {
      'key': 'fatFreeMassIndex',
      'title': 'Fat Free Mass Index',
      'unit': 'kg/m²',
      'color': Colors.green,
      'category': 'Body Parameters'
    },
    {
      'key': 'skeletalMuscleMass',
      'title': 'Skeletal Muscle Mass',
      'unit': 'kg',
      'color': Colors.purple,
      'category': 'Body Parameters'
    },

    // Body Composition
    {
      'key': 'bmi',
      'title': 'BMI',
      'unit': '',
      'color': Colors.teal,
      'category': 'Body Composition'
    },
    {
      'key': 'bodyFatMass',
      'title': 'Body Fat Mass',
      'unit': 'kg',
      'color': Colors.red,
      'category': 'Body Composition'
    },
    {
      'key': 'fatFreeWeight',
      'title': 'Fat-Free Weight',
      'unit': 'kg',
      'color': Colors.green,
      'category': 'Body Composition'
    },
    {
      'key': 'skeletalMuscleMass',
      'title': 'Skeletal Muscle Mass',
      'unit': 'kg',
      'color': Colors.purple,
      'category': 'Body Composition'
    },
    {
      'key': 'protein',
      'title': 'Protein',
      'unit': 'kg',
      'color': Colors.brown,
      'category': 'Body Composition'
    },
    {
      'key': 'mineral',
      'title': 'Mineral',
      'unit': 'kg',
      'color': Colors.grey,
      'category': 'Body Composition'
    },
    {
      'key': 'totalBodyWater',
      'title': 'Total Body Water',
      'unit': 'kg',
      'color': Colors.cyan,
      'category': 'Body Composition'
    },
    {
      'key': 'softLeanMass',
      'title': 'Soft Lean Mass',
      'unit': 'kg',
      'color': Colors.indigo,
      'category': 'Body Composition'
    },

    // Segmental Analysis
    {
      'key': 'trunkFatMass',
      'title': 'Trunk Fat Mass',
      'unit': 'kg',
      'color': Colors.red,
      'category': 'Segmental'
    },
    {
      'key': 'leftArmFatMass',
      'title': 'Left Arm Fat Mass',
      'unit': 'kg',
      'color': Colors.pink,
      'category': 'Segmental'
    },
    {
      'key': 'rightArmFatMass',
      'title': 'Right Arm Fat Mass',
      'unit': 'kg',
      'color': Colors.pink,
      'category': 'Segmental'
    },
    {
      'key': 'leftLegFatMass',
      'title': 'Left Leg Fat Mass',
      'unit': 'kg',
      'color': Colors.redAccent,
      'category': 'Segmental'
    },
    {
      'key': 'rightLegFatMass',
      'title': 'Right Leg Fat Mass',
      'unit': 'kg',
      'color': Colors.redAccent,
      'category': 'Segmental'
    },
  ];

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
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final records =
          await _bodyCompositionService.getBodyCompositionRecords(limit: 30);
      final summary = await _bodyCompositionService.getBodyCompositionSummary();
      final chartData =
          await _bodyCompositionService.getChartData(_selectedMetric);

      setState(() {
        _records = records;
        _summary = summary;
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
      List<BodyCompositionChartData> chartData;

      if (_isDateFilterActive &&
          _filterStartDate != null &&
          _filterEndDate != null) {
        // Get filtered data
        final filteredRecords =
            await _bodyCompositionService.getBodyCompositionRecords(
          startDate: _filterStartDate,
          endDate: _filterEndDate,
        );

        // Convert to chart data
        chartData = filteredRecords.map((record) {
          double value;
          switch (metric) {
            case 'weight':
              value = record.bodyParameters.weight;
              break;
            case 'bmi':
              value = record.bodyComposition.bmi;
              break;
            case 'bodyfat':
              value = record.bodyParameters.percentBodyFat;
              break;
            case 'muscle_mass':
              value = record.bodyComposition.skeletalMuscleMass;
              break;
            case 'muscle_percentage':
              value = record.bodyComposition.skeletalMusclePercentage;
              break;
            case 'visceral_fat':
              value = record.bodyComposition.visceralFatLevel;
              break;
            case 'bmr':
              value = record.bodyParameters.basalMetabolicRate;
              break;
            case 'fitness_age':
              value = record.advancedMetrics.fitnessAge;
              break;
            default:
              value = record.bodyParameters.weight;
          }

          return BodyCompositionChartData(
            date: record.date,
            value: value,
            type: metric,
            label: value.toStringAsFixed(1),
          );
        }).toList();

        // Sort by date
        chartData.sort((a, b) => a.date.compareTo(b.date));
      } else {
        // Get all data
        chartData = await _bodyCompositionService.getChartData(metric);
      }

      setState(() {
        _selectedMetric = metric;
        _chartData = chartData;
      });
    } catch (e) {
      print('Error loading chart data: $e');
    }
  }

  void _resetDateFilter() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
      _isDateFilterActive = false;
    });
    _loadChartData(_selectedMetric);
  }

  void _applyDateFilter() {
    if (_filterStartDate != null && _filterEndDate != null) {
      setState(() {
        _isDateFilterActive = true;
      });
      _loadChartData(_selectedMetric);
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
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Body Composition",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Settings/More options button
          InkWell(
            onTap: () => _showMoreOptionsDialog(),
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
                "assets/img/more_btn.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
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
                        Tab(text: "Trends"),
                        Tab(text: "Analysis"),
                      ],
                    ),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildTrendsTab(),
                          _buildAnalysisTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BodyCompositionInputView(),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: TColor.primaryColor1,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_records.isEmpty) {
      return const Center(
        child:
            Text("No data available. Add your first body composition record!"),
      );
    }

    // Get the latest record
    final latestRecord = _records.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Latest Data Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Weight",
                  "${latestRecord.bodyParameters.weight.toStringAsFixed(1)} kg",
                  _summary?.weightChange ?? 0.0,
                  "kg",
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSummaryCard(
                  "BMI",
                  latestRecord.bodyComposition.bmi.toStringAsFixed(1),
                  0.0, // BMI change calculation would need improvement
                  "",
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
                  "Body Fat",
                  "${latestRecord.bodyParameters.percentBodyFat.toStringAsFixed(1)}%",
                  _summary?.bodyFatChange ?? 0.0,
                  "%",
                  Colors.red,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSummaryCard(
                  "Muscle Mass",
                  "${latestRecord.bodyComposition.skeletalMuscleMass.toStringAsFixed(1)} kg",
                  _summary?.muscleMassChange ?? 0.0,
                  "kg",
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Recent Records
          Text(
            "Recent Records",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),

          ..._records.take(5).map((record) => _buildRecentRecordCard(record)),

          if (_records.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Icon(Icons.analytics_outlined,
                      size: 50, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    "No records yet",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Add your first body composition measurement",
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
          // Date Filter Section
          _buildDateFilterSection(),
          const SizedBox(height: 25),

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

          const SizedBox(height: 30),

          // Chart
          if (_chartData.isNotEmpty) ...[
            Text(
              "Trend Chart",
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
                            final date = _chartData.reversed
                                .toList()[value.toInt()]
                                .date;
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
                      spots: _chartData.reversed
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
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
                      "No chart data available",
                      style: TextStyle(color: TColor.gray),
                    ),
                  ],
                ),
              ),
            ),
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
            const Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              "No Records Yet",
              style: TextStyle(
                color: TColor.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Add your first body composition measurement",
              style: TextStyle(color: TColor.gray),
            ),
            const SizedBox(height: 30),
            RoundButton(
              title: "Add Record",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BodyCompositionInputView(),
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
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String value, double change, String unit, Color color) {
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
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (change != 0.0) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  change > 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: change > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  "${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}$unit",
                  style: TextStyle(
                    color: change > 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentRecordCard(BodyCompositionModel record) {
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
              builder: (context) => BodyCompositionDetailView(record: record),
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
              child: Icon(
                Icons.analytics,
                color: TColor.primaryColor1,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(record.date),
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Weight: ${record.bodyParameters.weight.toStringAsFixed(1)} kg • Body Fat: ${record.bodyComposition.bodyFatPercentage.toStringAsFixed(1)}%",
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

  Widget _buildRecordCard(BodyCompositionModel record) {
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
              Text(
                DateFormat('EEEE, MMM dd, yyyy').format(record.date),
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BodyCompositionInputView(recordToEdit: record),
                      ),
                    ).then((_) => _loadData());
                  } else if (value == 'delete') {
                    final confirmed = await _showDeleteConfirmation();
                    if (confirmed && record.id != null) {
                      try {
                        await _bodyCompositionService
                            .deleteBodyComposition(record.id!);
                        _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Record deleted successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error deleting record: $e')),
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

          // Basic metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricItem("Weight",
                    "${record.bodyParameters.weight.toStringAsFixed(1)} kg"),
              ),
              Expanded(
                child: _buildMetricItem(
                    "BMI", record.bodyComposition.bmi.toStringAsFixed(1)),
              ),
              Expanded(
                child: _buildMetricItem("Body Fat",
                    "${record.bodyParameters.percentBodyFat.toStringAsFixed(1)}%"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem("Muscle Mass",
                    "${record.bodyComposition.skeletalMuscleMass.toStringAsFixed(1)} kg"),
              ),
              Expanded(
                child: _buildMetricItem("Total Body Water",
                    "${record.bodyComposition.totalBodyWater.toStringAsFixed(1)} kg"),
              ),
              Expanded(
                child: _buildMetricItem("Visceral Fat",
                    record.bodyComposition.visceralFatLevel.toStringAsFixed(0)),
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
                    builder: (context) =>
                        BodyCompositionDetailView(record: record),
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

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Record'),
              content: const Text(
                  'Are you sure you want to delete this body composition record? This action cannot be undone.'),
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

  Widget _buildErrorView() {
    return Center(
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
    );
  }

  Widget _buildTrendsTab() {
    return _buildChartsTab();
  }

  Widget _buildAnalysisTab() {
    if (_records.isEmpty) {
      return _buildEmptyState();
    }

    final latestRecord = _records.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Advanced Metrics Section
          _buildSectionHeader("Advanced Metrics", Icons.analytics),
          const SizedBox(height: 15),

          // Fitness Grade Card
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Fitness Grade",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        latestRecord.advancedMetrics.fitnessGrade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Fitness Age: ${latestRecord.advancedMetrics.fitnessAge.toInt()} years",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Body Balance Analysis
          _buildSectionHeader("Body Balance Analysis", Icons.balance),
          const SizedBox(height: 15),

          Container(
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
                Text(
                  "Balance Assessment: ${latestRecord.segmentalAnalysis.bodyBalance.balanceAssessment}",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                _buildBalanceMetric(
                  "Total Body Fat Mass",
                  latestRecord.segmentalAnalysis.bodyBalance.totalBodyFatMass,
                  Colors.red,
                ),
                _buildBalanceMetric(
                  "Average Body Fat %",
                  latestRecord
                      .segmentalAnalysis.bodyBalance.averageBodyFatPercentage,
                  Colors.orange,
                ),
                _buildBalanceMetric(
                  "Balance Assessment",
                  85.0, // Default value since we don't have this field anymore
                  Colors.green,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Health Risk Assessment
          if (latestRecord.advancedMetrics.healthRisks.isNotEmpty) ...[
            _buildSectionHeader("Health Risk Assessment", Icons.warning),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        "Risk Score: ${latestRecord.advancedMetrics.healthRiskScore.toInt()}/100",
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ...latestRecord.advancedMetrics.healthRisks.map(
                    (risk) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              risk,
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: 14,
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

          const SizedBox(height: 25),

          // Recommendations
          if (latestRecord.advancedMetrics.recommendations.isNotEmpty) ...[
            _buildSectionHeader(
                "Personalized Recommendations", Icons.lightbulb),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.green, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        "Recommendations",
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ...latestRecord.advancedMetrics.recommendations.map(
                    (recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: 14,
                                height: 1.4,
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

          const SizedBox(height: 25),

          // Summary
          _buildSectionHeader("Summary", Icons.analytics),
          const SizedBox(height: 15),
          Container(
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
              children: [
                _buildSummaryItem("Fitness Age",
                    "${latestRecord.advancedMetrics.fitnessAge.toStringAsFixed(0)} years"),
                _buildSummaryItem(
                    "Fitness Grade", latestRecord.advancedMetrics.fitnessGrade),
                _buildSummaryItem("Health Risk Score",
                    "${latestRecord.advancedMetrics.healthRiskScore.toStringAsFixed(0)}/100"),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            "No Records Yet",
            style: TextStyle(
              color: TColor.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Add your first body composition measurement",
            style: TextStyle(color: TColor.gray),
          ),
          const SizedBox(height: 30),
          RoundButton(
            title: "Add Record",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BodyCompositionInputView(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TColor.primaryColor1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: TColor.primaryColor1,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: TColor.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceMetric(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                color: TColor.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: TColor.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${value.toInt()}%",
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  double _getCurrentValue(String key, BodyCompositionModel record) {
    switch (key) {
      case 'weight':
        return record.bodyParameters.weight;
      case 'bodyFat':
        return record.bodyComposition.bodyFatPercentage;
      case 'muscleMass':
        return record.bodyComposition.skeletalMuscleMass;
      case 'visceralFat':
        return record.bodyComposition.visceralFatLevel;
      default:
        return 0.0;
    }
  }

  String _getTargetDisplayName(String key) {
    switch (key) {
      case 'weight':
        return 'Weight';
      case 'bodyFat':
        return 'Body Fat %';
      case 'muscleMass':
        return 'Muscle Mass';
      case 'visceralFat':
        return 'Visceral Fat';
      default:
        return key;
    }
  }

  void _showMoreOptionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Body Composition Options",
              style: TextStyle(
                color: TColor.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.file_download, color: Colors.blue),
              ),
              title: const Text("Export Data"),
              subtitle: const Text("Export all data to CSV/PDF"),
              onTap: () {
                Navigator.pop(context);
                _showExportDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.backup, color: Colors.green),
              ),
              title: const Text("Backup Data"),
              subtitle: const Text("Create backup to cloud storage"),
              onTap: () {
                Navigator.pop(context);
                _showBackupDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics, color: Colors.orange),
              ),
              title: const Text("Advanced Analytics"),
              subtitle: const Text("View detailed analysis reports"),
              onTap: () {
                Navigator.pop(context);
                _showAdvancedAnalytics();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings, color: Colors.purple),
              ),
              title: const Text("Settings"),
              subtitle: const Text("Configure measurement units & preferences"),
              onTap: () {
                Navigator.pop(context);
                _showSettingsDialog();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showBackupDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('☁️ Backup feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAdvancedAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Advanced analytics coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showSettingsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚙️ Settings feature coming soon!'),
        backgroundColor: Colors.purple,
      ),
    );
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
    final firstDate = _records.isNotEmpty
        ? _records.last.date
        : now.subtract(const Duration(days: 365));

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
    final firstDate = _filterStartDate ??
        (_records.isNotEmpty
            ? _records.last.date
            : now.subtract(const Duration(days: 365)));

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
}
