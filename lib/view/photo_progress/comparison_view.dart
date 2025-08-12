import 'package:nextfitx/common_widget/icon_title_next_row.dart';
import 'package:nextfitx/common_widget/round_button.dart';
import 'package:nextfitx/services/photo_service.dart';
import 'package:nextfitx/view/photo_progress/result_view.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';

class ComparisonView extends StatefulWidget {
  const ComparisonView({super.key});

  @override
  State<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  final PhotoService _photoService = PhotoService();
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime _selectedMonth1 = DateTime.now();
  DateTime _selectedMonth2 = DateTime.now();

  Future<void> _selectMonth(bool isFirstMonth) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFirstMonth ? _selectedMonth1 : _selectedMonth2,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        if (isFirstMonth) {
          _selectedMonth1 = picked;
        } else {
          _selectedMonth2 = picked;
        }
      });
    }
  }

  String _formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> _comparePhotos() async {
    if (_selectedMonth1.isAfter(_selectedMonth2)) {
      setState(() {
        _errorMessage = 'First month should be before second month';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final month1Photos =
          await _photoService.getPhotosByMonth(_selectedMonth1);
      final month2Photos =
          await _photoService.getPhotosByMonth(_selectedMonth2);

      if (!mounted) return;

      if (month1Photos.isEmpty && month2Photos.isEmpty) {
        setState(() {
          _errorMessage = 'No photos found for comparison';
        });
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultView(
            date1: _selectedMonth1,
            date2: _selectedMonth2,
            month1Photos: month1Photos,
            month2Photos: month2Photos,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load photos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Comparison",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          InkWell(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset(
                "assets/img/more_btn.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          )
        ],
      ),
      backgroundColor: TColor.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          children: [
            IconTitleNextRow(
                icon: "assets/img/date.png",
                title: "Select Month 1",
                time: _formatMonth(_selectedMonth1),
                onPressed: () => _selectMonth(true),
                color: TColor.lightGray),
            const SizedBox(height: 15),
            IconTitleNextRow(
                icon: "assets/img/date.png",
                title: "Select Month 2",
                time: _formatMonth(_selectedMonth2),
                onPressed: () => _selectMonth(false),
                color: TColor.lightGray),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: TColor.secondaryColor1),
                ),
              ),
            const Spacer(),
            _isLoading
                ? CircularProgressIndicator(color: TColor.primaryColor1)
                : RoundButton(
                    title: "Compare",
                    onPressed: _comparePhotos,
                  ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
