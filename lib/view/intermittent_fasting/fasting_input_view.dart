import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/intermittent_fasting_model.dart';
import '../../services/intermittent_fasting_service.dart';

class FastingInputView extends StatefulWidget {
  final FastingModel? existingFasting;

  const FastingInputView({super.key, this.existingFasting});

  @override
  State<FastingInputView> createState() => _FastingInputViewState();
}

class _FastingInputViewState extends State<FastingInputView> {
  final _formKey = GlobalKey<FormState>();
  final IntermittentFastingService _fastingService =
      IntermittentFastingService();
  final _notesController = TextEditingController();
  final _customHoursController = TextEditingController();

  // Form data
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  FastingType _selectedFastingType = FastingType.sixteen_eight;
  int? _customDurationHours;

  // UI state
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingFasting != null) {
      _isEditing = true;
      _populateExistingFasting();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customHoursController.dispose();
    super.dispose();
  }

  void _populateExistingFasting() {
    final fasting = widget.existingFasting!;
    setState(() {
      _selectedDate = fasting.date;
      _startTime = TimeOfDay.fromDateTime(fasting.startTime);
      _selectedFastingType = fasting.fastingType;
      _notesController.text = fasting.notes ?? '';

      if (_selectedFastingType == FastingType.custom) {
        _customDurationHours = fasting.targetDurationHours;
        _customHoursController.text = fasting.targetDurationHours.toString();
      }
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
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
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
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
        _startTime = time;
      });
    }
  }

  Future<void> _startFasting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create start DateTime
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      // Check if it's too far in the past
      final now = DateTime.now();
      if (startDateTime.isBefore(now.subtract(const Duration(hours: 1)))) {
        throw Exception('Start time cannot be more than 1 hour in the past');
      }

      if (_isEditing) {
        // Update existing fasting record
        final updatedFasting = widget.existingFasting!.copyWith(
          date: _selectedDate,
          fastingType: _selectedFastingType,
          startTime: startDateTime,
          targetDurationHours: _selectedFastingType == FastingType.custom
              ? _customDurationHours
              : _selectedFastingType.fastHours,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          updatedAt: DateTime.now(),
        );

        await _fastingService.updateFasting(updatedFasting);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fasting session updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Start new fasting session
        await _fastingService.startFasting(
          fastingType: _selectedFastingType,
          startTime: startDateTime,
          customDurationHours: _selectedFastingType == FastingType.custom
              ? _customDurationHours
              : null,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fasting session started successfully!'),
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
            content: Text('Error: $e'),
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
          _isEditing ? "Edit Fasting" : "Start Fasting",
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
                "Date",
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

              // Start Time Selection
              Text(
                "Start Time",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectStartTime,
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
                        _startTime.format(context),
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        color: TColor.gray,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Fasting Type Selection
              Text(
                "Fasting Protocol",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),

              // Fasting type grid
              Column(
                children: FastingType.values
                    .map((type) => _buildFastingTypeCard(type))
                    .toList(),
              ),

              // Custom duration input (only show if custom is selected)
              if (_selectedFastingType == FastingType.custom) ...[
                const SizedBox(height: 20),
                Text(
                  "Custom Duration (Hours)",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customHoursController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedFastingType == FastingType.custom) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter duration';
                      }
                      final hours = int.tryParse(value);
                      if (hours == null || hours < 1 || hours > 72) {
                        return 'Duration must be between 1-72 hours';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _customDurationHours = int.tryParse(value);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: TColor.lightGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: TColor.primaryColor1),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: TColor.lightGray,
                    hintText: "Enter hours (1-72)",
                    hintStyle: TextStyle(color: TColor.gray, fontSize: 12),
                  ),
                ),
              ],

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
                  hintText:
                      "Add any notes about your fasting goals or motivation...",
                  hintStyle: TextStyle(color: TColor.gray, fontSize: 12),
                ),
              ),

              const SizedBox(height: 30),

              // Start Button
              RoundButton(
                title: _isLoading
                    ? "Starting..."
                    : (_isEditing ? "Update Fasting" : "Start Fasting"),
                onPressed: _isLoading ? () {} : _startFasting,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFastingTypeCard(FastingType type) {
    final isSelected = _selectedFastingType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedFastingType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isSelected ? TColor.primaryColor1.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? TColor.primaryColor1
                : TColor.gray.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: TColor.primaryColor1.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? TColor.primaryColor1 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type.displayName,
                        style: TextStyle(
                          color:
                              isSelected ? TColor.primaryColor1 : TColor.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(type.difficulty)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type.difficulty,
                          style: TextStyle(
                            color: _getDifficultyColor(type.difficulty),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    type.description,
                    style: TextStyle(
                      color: isSelected
                          ? TColor.primaryColor1.withOpacity(0.8)
                          : TColor.gray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (type != FastingType.custom) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color:
                              isSelected ? TColor.primaryColor1 : TColor.gray,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Target: ${type.fastHours} hours",
                          style: TextStyle(
                            color:
                                isSelected ? TColor.primaryColor1 : TColor.gray,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: TColor.primaryColor1,
                size: 24,
              ),
          ],
        ),
      ),
    );
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
}
