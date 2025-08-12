import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/sleep_model.dart';
import '../../services/sleep_service.dart';

class SleepInputView extends StatefulWidget {
  final SleepModel? existingSleep;

  const SleepInputView({super.key, this.existingSleep});

  @override
  State<SleepInputView> createState() => _SleepInputViewState();
}

class _SleepInputViewState extends State<SleepInputView> {
  final _formKey = GlobalKey<FormState>();
  final SleepService _sleepService = SleepService();
  final _notesController = TextEditingController();

  // Form data
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _quality = 3;

  // Calculated values
  int _calculatedDuration = 0;
  String _durationText = "";

  // UI state
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingSleep != null) {
      _isEditing = true;
      _populateExistingSleep();
    }

    _calculateDuration();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _populateExistingSleep() {
    final sleep = widget.existingSleep!;
    setState(() {
      _selectedDate = sleep.date;
      _bedtime = TimeOfDay.fromDateTime(sleep.bedtime);
      _wakeTime = TimeOfDay.fromDateTime(sleep.wakeTime);
      _quality = sleep.quality;
      _notesController.text = sleep.notes ?? '';
      _calculatedDuration = sleep.durationMinutes;
      _updateDurationText();
    });
  }

  void _calculateDuration() {
    // Create DateTime objects for calculation
    final bedtimeDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _bedtime.hour,
      _bedtime.minute,
    );

    DateTime wakeDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _wakeTime.hour,
      _wakeTime.minute,
    );

    // If wake time is before bedtime, it's next day
    if (wakeDateTime.isBefore(bedtimeDateTime)) {
      wakeDateTime = wakeDateTime.add(const Duration(days: 1));
    }

    final duration = SleepCalculator.calculateDuration(
      bedtime: bedtimeDateTime,
      wakeTime: wakeDateTime,
    );

    setState(() {
      _calculatedDuration = duration;
      _updateDurationText();
    });
  }

  void _updateDurationText() {
    final hours = _calculatedDuration ~/ 60;
    final minutes = _calculatedDuration % 60;
    _durationText = '${hours}h ${minutes}m';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primaryColor1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _calculateDuration();
      });
    }
  }

  Future<void> _selectBedtime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primaryColor1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _bedtime = time;
        _calculateDuration();
      });
    }
  }

  Future<void> _selectWakeTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primaryColor1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _wakeTime = time;
        _calculateDuration();
      });
    }
  }

  Future<void> _saveSleep() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create DateTime objects
      final bedtimeDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _bedtime.hour,
        _bedtime.minute,
      );

      DateTime wakeDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _wakeTime.hour,
        _wakeTime.minute,
      );

      // If wake time is before bedtime, it's next day
      if (wakeDateTime.isBefore(bedtimeDateTime)) {
        wakeDateTime = wakeDateTime.add(const Duration(days: 1));
      }

      if (_isEditing) {
        // Update existing sleep record
        final updatedSleep = widget.existingSleep!.copyWith(
          date: _selectedDate,
          bedtime: bedtimeDateTime,
          wakeTime: wakeDateTime,
          durationMinutes: _calculatedDuration,
          quality: _quality,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          updatedAt: DateTime.now(),
        );

        await _sleepService.updateSleep(updatedSleep);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sleep record updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new sleep record
        await _sleepService.createSleepWithCalculation(
          date: _selectedDate,
          bedtime: bedtimeDateTime,
          wakeTime: wakeDateTime,
          quality: _quality,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sleep record saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving sleep record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
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
          _isEditing ? "Edit Sleep Record" : "Add Sleep Record",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Selection
              Text(
                "Sleep Date",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: TColor.gray.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: TColor.gray,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Sleep Times Section
              Row(
                children: [
                  // Bedtime
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.brightness_2,
                              color: TColor.primaryColor1,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Bedtime",
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectBedtime,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            decoration: BoxDecoration(
                              color: TColor.lightGray,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color: TColor.gray.withOpacity(0.2)),
                            ),
                            child: Text(
                              _bedtime.format(context),
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Wake Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color: TColor.primaryColor1,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Wake Time",
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectWakeTime,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            decoration: BoxDecoration(
                              color: TColor.lightGray,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color: TColor.gray.withOpacity(0.2)),
                            ),
                            child: Text(
                              _wakeTime.format(context),
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Duration Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9C27B0),
                      const Color(0xFF673AB7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Total Sleep Duration",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _durationText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getHealthyMessage(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Sleep Quality
              Text(
                "Sleep Quality",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),

              // Quality selector
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
                        Text(
                          "${SleepQuality.getEmoji(_quality)} ${SleepQuality.getText(_quality)}",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getQualityColor(_quality).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$_quality/5",
                            style: TextStyle(
                              color: _getQualityColor(_quality),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: SleepQuality.all.map((quality) {
                        return GestureDetector(
                          onTap: () => setState(() => _quality = quality),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _quality == quality
                                  ? _getQualityColor(quality)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _quality == quality
                                    ? _getQualityColor(quality)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              SleepQuality.getEmoji(quality),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Notes (Optional)
              Text(
                "Notes (Optional)",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: TColor.lightGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: TColor.primaryColor1),
                  ),
                  filled: true,
                  fillColor: TColor.lightGray,
                  hintText: "How was your sleep? Any factors that affected it?",
                  hintStyle: TextStyle(color: TColor.gray, fontSize: 12),
                ),
              ),

              const SizedBox(height: 30),

              // Save Button
              RoundButton(
                title: _isLoading
                    ? "Saving..."
                    : (_isEditing
                        ? "Update Sleep Record"
                        : "Save Sleep Record"),
                onPressed: _isLoading ? () {} : _saveSleep,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getHealthyMessage() {
    if (SleepCalculator.isHealthyDuration(_calculatedDuration)) {
      return "Healthy sleep duration! 👍";
    } else if (_calculatedDuration < 6.5 * 60) {
      return "Consider sleeping a bit longer";
    } else {
      return "That's quite a long sleep!";
    }
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
}
