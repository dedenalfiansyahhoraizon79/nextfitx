import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../services/photo_service.dart';

class ResultView extends StatefulWidget {
  final DateTime date1;
  final DateTime date2;
  final Map<String, List<Map<String, dynamic>>> month1Photos;
  final Map<String, List<Map<String, dynamic>>> month2Photos;

  const ResultView({
    super.key,
    required this.date1,
    required this.date2,
    required this.month1Photos,
    required this.month2Photos,
  });

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  final PhotoService _photoService = PhotoService();
  int selectButton = 0;
  final photoTypes = ['front', 'back', 'left', 'right'];
  final photoTypeLabels = {
    'front': 'Front View',
    'back': 'Back View',
    'left': 'Left Side',
    'right': 'Right Side',
  };
  late final Map<String, List<Map<String, dynamic>>> _statistics;
  late final List<List<FlSpot>> _chartData;

  @override
  void initState() {
    super.initState();
    _statistics = _photoService.calculateStatistics(
        widget.month1Photos, widget.month2Photos);
    _chartData = _photoService.getChartData(widget.date1);
  }

  Widget _buildPhotoComparison(String type) {
    final month1TypePhotos = widget.month1Photos[type] ?? [];
    final month2TypePhotos = widget.month2Photos[type] ?? [];

    print('Building comparison for type: $type');
    print('Month 1 photos: ${month1TypePhotos.length}');
    print('Month 2 photos: ${month2TypePhotos.length}');

    if (month1TypePhotos.isNotEmpty) {
      print('Month 1 first photo: ${month1TypePhotos.first}');
    }
    if (month2TypePhotos.isNotEmpty) {
      print('Month 2 first photo: ${month2TypePhotos.first}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 15),
        Text(
          photoTypeLabels[type] ?? type,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: month1TypePhotos.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            month1TypePhotos.first['url'],
                            width: double.maxFinite,
                            height: double.maxFinite,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading month 1 photo: $error');
                              print('Stack trace: $stackTrace');
                              return Container(
                                color: TColor.lightGray,
                                child: const Icon(Icons.error_outline),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            'No photo',
                            style: TextStyle(
                              color: TColor.gray,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: month2TypePhotos.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            month2TypePhotos.first['url'],
                            width: double.maxFinite,
                            height: double.maxFinite,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading month 2 photo: $error');
                              print('Stack trace: $stackTrace');
                              return Container(
                                color: TColor.lightGray,
                                child: const Icon(Icons.error_outline),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            'No photo',
                            style: TextStyle(
                              color: TColor.gray,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            children: [
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      alignment: selectButton == 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: (media.width * 0.5) - 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: TColor.primaryG),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectButton = 0;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                "Photo",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selectButton == 0
                                      ? TColor.white
                                      : TColor.gray,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectButton = 1;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                "Statistic",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selectButton == 1
                                      ? TColor.white
                                      : TColor.gray,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (selectButton == 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(widget.date1),
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(widget.date2),
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    ...photoTypes.map((type) => _buildPhotoComparison(type)),
                    const SizedBox(height: 20),
                    RoundButton(
                      title: "Back to Home",
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              if (selectButton == 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 10),
                      height: media.width * 0.5,
                      width: double.maxFinite,
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            enabled: true,
                            handleBuiltInTouches: false,
                            touchCallback: (
                              FlTouchEvent event,
                              LineTouchResponse? response,
                            ) {
                              if (response == null ||
                                  response.lineBarSpots == null) {
                                return;
                              }
                              // if (event is FlTapUpEvent) {
                              //   final spotIndex =
                              //       response.lineBarSpots!.first.spotIndex;
                              //   showingTooltipOnSpots.clear();
                              //   setState(() {
                              //     showingTooltipOnSpots.add(spotIndex);
                              //   });
                              // }
                            },
                            mouseCursorResolver: (
                              FlTouchEvent event,
                              LineTouchResponse? response,
                            ) {
                              if (response == null ||
                                  response.lineBarSpots == null) {
                                return SystemMouseCursors.basic;
                              }
                              return SystemMouseCursors.click;
                            },
                            getTouchedSpotIndicator: (
                              LineChartBarData barData,
                              List<int> spotIndexes,
                            ) {
                              return spotIndexes.map((index) {
                                return TouchedSpotIndicatorData(
                                  const FlLine(color: Colors.transparent),
                                  FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                      radius: 3,
                                      color: Colors.white,
                                      strokeWidth: 3,
                                      strokeColor: TColor.secondaryColor1,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems:
                                  (List<LineBarSpot> lineBarsSpot) {
                                return lineBarsSpot.map((lineBarSpot) {
                                  return LineTooltipItem(
                                    "${lineBarSpot.x.toInt()} mins ago",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: lineBarsData1,
                          minY: -0.5,
                          maxY: 110,
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: const AxisTitles(),
                            topTitles: const AxisTitles(),
                            bottomTitles: AxisTitles(sideTitles: bottomTitles),
                            rightTitles: AxisTitles(sideTitles: rightTitles),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                            horizontalInterval: 25,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: TColor.lightGray,
                                strokeWidth: 2,
                              );
                            },
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(widget.date1),
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(widget.date2),
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    _buildStatisticsList(),
                    const SizedBox(height: 20),
                    RoundButton(
                      title: "Back to Home",
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) {
            return Colors.blueGrey.withValues(alpha: 0.8);
          },
        ),
      );

  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1,
        lineChartBarData1_2,
      ];

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        isCurved: true,
        gradient: LinearGradient(colors: TColor.primaryG),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: _chartData[0],
      );

  LineChartBarData get lineChartBarData1_2 => LineChartBarData(
        isCurved: true,
        gradient: LinearGradient(
          colors: [
            TColor.secondaryColor2.withValues(alpha: 0.5),
            TColor.secondaryColor1.withValues(alpha: 0.5),
          ],
        ),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: _chartData[1],
      );

  SideTitles get rightTitles => SideTitles(
        getTitlesWidget: rightTitleWidgets,
        showTitles: true,
        interval: 20,
        reservedSize: 40,
      );

  Widget rightTitleWidgets(double value, TitleMeta meta) {
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0%';
        break;
      case 20:
        text = '20%';
        break;
      case 40:
        text = '40%';
        break;
      case 60:
        text = '60%';
        break;
      case 80:
        text = '80%';
        break;
      case 100:
        text = '100%';
        break;
      default:
        return Container();
    }

    return Text(
      text,
      style: TextStyle(color: TColor.gray, fontSize: 12),
      textAlign: TextAlign.center,
    );
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    var style = TextStyle(color: TColor.gray, fontSize: 12);
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = Text('Jan', style: style);
        break;
      case 2:
        text = Text('Feb', style: style);
        break;
      case 3:
        text = Text('Mar', style: style);
        break;
      case 4:
        text = Text('Apr', style: style);
        break;
      case 5:
        text = Text('May', style: style);
        break;
      case 6:
        text = Text('Jun', style: style);
        break;
      case 7:
        text = Text('Jul', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: text,
    );
  }

  Widget _buildStatisticsList() {
    return Column(
      children: photoTypes.map((type) {
        final typeStats = _statistics[type] ?? [];
        if (typeStats.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                photoTypeLabels[type] ?? type,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...typeStats
                .map((stat) => Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 15),
                        Text(
                          stat["title"].toString(),
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 35,
                              child: Text(
                                "${stat["month_1_per"]}%",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: TColor.gray,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: TColor.lightGray,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    Container(
                                      height: 10,
                                      width: (stat["improved"] as bool)
                                          ? double.infinity
                                          : (double.tryParse(stat["diff_per"]
                                                      .toString()) ??
                                                  0) /
                                              100 *
                                              MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.6,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: (stat["improved"] as bool)
                                              ? [
                                                  TColor.primaryColor2,
                                                  TColor.primaryColor1
                                                ]
                                              : [
                                                  TColor.secondaryColor2,
                                                  TColor.secondaryColor1
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 35,
                              child: Text(
                                "${stat["month_2_per"]}%",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: TColor.gray,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ))
                ,
          ],
        );
      }).toList(),
    );
  }
}
