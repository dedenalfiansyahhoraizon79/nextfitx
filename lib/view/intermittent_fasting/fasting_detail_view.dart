import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/intermittent_fasting_model.dart';
import '../../services/intermittent_fasting_service.dart';
import 'fasting_input_view.dart';

class FastingDetailView extends StatefulWidget {
  final FastingModel fasting;

  const FastingDetailView({super.key, required this.fasting});

  @override
  State<FastingDetailView> createState() => _FastingDetailViewState();
}

class _FastingDetailViewState extends State<FastingDetailView> {
  final IntermittentFastingService _fastingService =
      IntermittentFastingService();
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
          "Fasting Details",
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
            // Main Fasting Card
            Container(
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
                        child: Text(
                          widget.fasting.fastingType.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM d, yyyy')
                                  .format(widget.fasting.date),
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
                                  widget.fasting.status.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.fasting.status.displayName,
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
                  const SizedBox(height: 25),

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
                          widget.fasting.currentDurationFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Total Fasting Duration",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Progress Bar
                        LinearProgressIndicator(
                          value: widget.fasting.progressPercentage / 100,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Progress: ${widget.fasting.progressPercentage.toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
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

            // Fasting Protocol Section
            Text(
              "Fasting Protocol",
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _getFastingTypeColor(widget.fasting.fastingType)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.fasting.fastingType.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fasting.fastingType.displayName,
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.fasting.fastingType.description,
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(
                                  widget.fasting.fastingType.difficulty)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.fasting.fastingType.difficulty,
                          style: TextStyle(
                            color: _getDifficultyColor(
                                widget.fasting.fastingType.difficulty),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildProtocolRow("Target Duration",
                      "${widget.fasting.targetDurationHours} hours"),
                  const SizedBox(height: 10),
                  _buildProtocolRow("Actual Duration",
                      widget.fasting.currentDurationFormatted),
                  const SizedBox(height: 10),
                  _buildProtocolRow("Completion",
                      "${widget.fasting.progressPercentage.toStringAsFixed(1)}%"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Timing Information
            Text(
              "Timing Details",
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
                    "Start Time",
                    DateFormat('h:mm a').format(widget.fasting.startTime),
                    DateFormat('MMM d').format(widget.fasting.startTime),
                    Icons.play_arrow,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTimeCard(
                    widget.fasting.endTime != null
                        ? "End Time"
                        : "Est. End Time",
                    DateFormat('h:mm a')
                        .format(widget.fasting.actualOrEstimatedEndTime),
                    DateFormat('MMM d')
                        .format(widget.fasting.actualOrEstimatedEndTime),
                    widget.fasting.endTime != null
                        ? Icons.stop
                        : Icons.schedule,
                    widget.fasting.endTime != null
                        ? const Color(0xFFF44336)
                        : const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Status Information
            Text(
              "Status Information",
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.fasting.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.fasting.status.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fasting.status.displayName,
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.fasting.status.description,
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
                  const SizedBox(height: 15),
                  _buildStatusRow(
                      "Created",
                      DateFormat('MMM d, yyyy h:mm a')
                          .format(widget.fasting.createdAt)),
                  const SizedBox(height: 10),
                  _buildStatusRow(
                      "Last Updated",
                      DateFormat('MMM d, yyyy h:mm a')
                          .format(widget.fasting.updatedAt)),
                  if (widget.fasting.isCompleted) ...[
                    const SizedBox(height: 10),
                    _buildStatusRow(
                        "Goal Achievement",
                        widget.fasting.progressPercentage >= 100
                            ? "✅ Completed"
                            : "⚠️ Partial"),
                  ],
                ],
              ),
            ),

            if (widget.fasting.notes != null &&
                widget.fasting.notes!.isNotEmpty) ...[
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
                  widget.fasting.notes!,
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
            if (widget.fasting.status != FastingStatus.active) ...[
              Column(
                children: [
                  RoundButton(
                    title: "Edit Fasting Record",
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FastingInputView(existingFasting: widget.fasting),
                        ),
                      );
                      if (result == true && mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  RoundButton(
                    title:
                        _isDeleting ? "Deleting..." : "Delete Fasting Record",
                    type: RoundButtonType.textGradient,
                    onPressed: _isDeleting ? () {} : () => _showDeleteDialog(),
                  ),
                ],
              ),
            ] else ...[
              // Active fasting actions
              Column(
                children: [
                  RoundButton(
                    title: "End Fasting Now",
                    onPressed: () => _showEndFastingDialog(),
                  ),
                  const SizedBox(height: 15),
                  RoundButton(
                    title: widget.fasting.status == FastingStatus.paused
                        ? "Resume Fasting"
                        : "Pause Fasting",
                    type: RoundButtonType.textGradient,
                    onPressed: () => _togglePauseFasting(),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(
      String title, String time, String date, IconData icon, Color color) {
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
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

  Widget _buildProtocolRow(String label, String value) {
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

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            color: TColor.gray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      case 'Expert':
        return Colors.purple;
      case 'Custom':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editFasting();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  Future<void> _editFasting() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FastingInputView(existingFasting: widget.fasting),
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
        title: const Text('Delete Fasting Record'),
        content: Text(
          'Are you sure you want to delete this fasting record for "${DateFormat('MMM d, yyyy').format(widget.fasting.date)}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFasting();
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

  void _showEndFastingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Fasting'),
        content: const Text('How would you like to end this fasting session?'),
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
        fastingId: widget.fasting.id!,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Fasting ${status.displayName.toLowerCase()} successfully!'),
            backgroundColor: status == FastingStatus.completed
                ? Colors.green
                : Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending fasting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePauseFasting() async {
    try {
      if (widget.fasting.status == FastingStatus.paused) {
        await _fastingService.resumeFasting(widget.fasting.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fasting resumed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _fastingService.pauseFasting(widget.fasting.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fasting paused successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFasting() async {
    setState(() => _isDeleting = true);

    try {
      await _fastingService.deleteFasting(widget.fasting.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fasting record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting fasting record: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isDeleting = false);
      }
    }
  }
}
