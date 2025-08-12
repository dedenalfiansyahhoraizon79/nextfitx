import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/sleep_model.dart';
import '../../services/sleep_service.dart';
import 'sleep_input_view.dart';

class SleepDetailView extends StatefulWidget {
  final SleepModel sleep;

  const SleepDetailView({super.key, required this.sleep});

  @override
  State<SleepDetailView> createState() => _SleepDetailViewState();
}

class _SleepDetailViewState extends State<SleepDetailView> {
  final SleepService _sleepService = SleepService();
  bool _isDeleting = false;

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
          "Sleep Details",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: TColor.primaryColor1, size: 20),
                    const SizedBox(width: 10),
                    const Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    const Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Sleep Card
            Container(
              width: double.infinity,
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bedtime,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM d, yyyy')
                                  .format(widget.sleep.date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  SleepQuality.getEmoji(widget.sleep.quality),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.sleep.qualityText,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Duration Highlight
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.sleep.durationFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Total Sleep Duration",
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
              ),
            ),

            const SizedBox(height: 25),

            // Sleep Times Section
            Text(
              "Sleep Times",
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
                  child: _buildTimeCard(
                    "Bedtime",
                    widget.sleep.bedtimeFormatted,
                    Icons.brightness_2,
                    const Color(0xFF3F51B5),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTimeCard(
                    "Wake Time",
                    widget.sleep.wakeTimeFormatted,
                    Icons.wb_sunny,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Sleep Quality Section
            Text(
              "Sleep Quality",
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
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _getQualityColor(widget.sleep.quality)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          SleepQuality.getEmoji(widget.sleep.quality),
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.sleep.qualityText,
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "${widget.sleep.quality} out of 5",
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Quality stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < widget.sleep.quality
                            ? Icons.star
                            : Icons.star_border,
                        color: _getQualityColor(widget.sleep.quality),
                        size: 24,
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Sleep Analysis
            Text(
              "Sleep Analysis",
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
                  _buildAnalysisRow(
                    "Duration Status",
                    SleepCalculator.isHealthyDuration(
                            widget.sleep.durationMinutes)
                        ? "Healthy 😊"
                        : "Needs improvement 😴",
                    SleepCalculator.isHealthyDuration(
                            widget.sleep.durationMinutes)
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(height: 15),
                  _buildAnalysisRow(
                    "Time in Bed",
                    "${widget.sleep.durationHours.toStringAsFixed(1)} hours",
                    Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  _buildAnalysisRow(
                    "Sleep Efficiency",
                    "${(widget.sleep.durationMinutes / (widget.sleep.durationMinutes + 30) * 100).toStringAsFixed(0)}%",
                    Colors.purple,
                  ),
                  const SizedBox(height: 15),
                  _buildAnalysisRow(
                    "Recommended Range",
                    "7-9 hours",
                    Colors.grey,
                  ),
                ],
              ),
            ),

            if (widget.sleep.notes != null &&
                widget.sleep.notes!.isNotEmpty) ...[
              const SizedBox(height: 25),

              // Notes Section
              Text(
                "Notes",
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: TColor.lightGray),
                ),
                child: Text(
                  widget.sleep.notes!,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Action Buttons
            Column(
              children: [
                RoundButton(
                  title: "Edit Sleep Record",
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SleepInputView(existingSleep: widget.sleep),
                      ),
                    );
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                const SizedBox(height: 15),
                RoundButton(
                  title: _isDeleting ? "Deleting..." : "Delete Sleep Record",
                  type: RoundButtonType.textGradient,
                  onPressed: _isDeleting ? () {} : () => _showDeleteDialog(),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String title, String time, IconData icon, Color color) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            time,
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
              color: TColor.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editSleep();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  Future<void> _editSleep() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SleepInputView(existingSleep: widget.sleep),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sleep Record'),
        content: Text(
          'Are you sure you want to delete this sleep record for "${DateFormat('MMM d, yyyy').format(widget.sleep.date)}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSleep();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSleep() async {
    setState(() => _isDeleting = true);

    try {
      await _sleepService.deleteSleep(widget.sleep.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sleep record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting sleep record: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isDeleting = false);
      }
    }
  }
}
