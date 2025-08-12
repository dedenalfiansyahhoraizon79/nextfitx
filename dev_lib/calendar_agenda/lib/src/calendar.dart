import 'package:flutter/material.dart';
import 'package:calendar_agenda/calendar_agenda.dart';
import 'fullcalendar.dart';

class CalendarAgenda extends StatefulWidget {
  final CalendarAgendaController? controller;
  final bool appbar;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Color? backgroundColor;
  final Color? selectedDateColor;
  final Color? dateColor;
  final Color? calendarEventColor;
  final Color? dayBGColor;
  final Color? selectedDayLogo;
  final double? dayNameFontSize;
  final double? dayNumberFontSize;
  final double? titleSpaceBetween;
  final String? locale;
  final WeekDay? weekDay;
  final WeekDay? fullCalendarDay;
  final FullCalendarScroll? fullCalendarScroll;
  final SelectedDayPosition? selectedDayPosition;
  final Widget? leading;
  final Widget? calendarBackground;
  final List<String>? events;
  final Function onDateSelected;

  const CalendarAgenda({
    super.key,
    this.controller,
    this.appbar = false,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.backgroundColor,
    this.selectedDateColor,
    this.dateColor,
    this.calendarEventColor,
    this.dayBGColor,
    this.selectedDayLogo,
    this.dayNameFontSize,
    this.dayNumberFontSize,
    this.titleSpaceBetween,
    this.locale,
    this.weekDay,
    this.fullCalendarDay,
    this.fullCalendarScroll,
    this.selectedDayPosition,
    this.leading,
    this.calendarBackground,
    this.events,
    required this.onDateSelected,
  });

  @override
  CalendarAgendaState createState() => CalendarAgendaState();
}

class CalendarAgendaState extends State<CalendarAgenda> {
  late DateTime _selectedDate;
  late DateTime _firstDate;
  late DateTime _lastDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _firstDate =
        widget.firstDate ?? DateTime.now().subtract(const Duration(days: 140));
    _lastDate = widget.lastDate ?? DateTime.now().add(const Duration(days: 60));
  }

  @override
  Widget build(BuildContext context) {
    return widget.appbar
        ? AppBar(
            backgroundColor: widget.backgroundColor ?? Colors.white,
            leading: widget.leading,
            title: FullCalendar(
              startDate: _firstDate,
              endDate: _lastDate,
              selectedDate: _selectedDate,
              dateColor: widget.dateColor ?? Colors.black,
              dateSelectedColor: widget.selectedDateColor ?? Colors.white,
              dateSelectedBg:
                  widget.dayBGColor ?? Colors.grey.withValues(alpha: 0.15),
              padding: 25.0,
              locale: widget.locale ?? 'en',
              fullCalendarDay: widget.fullCalendarDay ?? WeekDay.long,
              calendarScroll:
                  widget.fullCalendarScroll ?? FullCalendarScroll.horizontal,
              calendarBackground: widget.calendarBackground,
              events: widget.events,
              onDateChange: (date) {
                setState(() {
                  _selectedDate = date;
                });
                widget.onDateSelected(date);
              },
            ),
          )
        : FullCalendar(
            startDate: _firstDate,
            endDate: _lastDate,
            selectedDate: _selectedDate,
            dateColor: widget.dateColor ?? Colors.black,
            dateSelectedColor: widget.selectedDateColor ?? Colors.white,
            dateSelectedBg:
                widget.dayBGColor ?? Colors.grey.withValues(alpha: 0.15),
            padding: 25.0,
            locale: widget.locale ?? 'en',
            fullCalendarDay: widget.fullCalendarDay ?? WeekDay.long,
            calendarScroll:
                widget.fullCalendarScroll ?? FullCalendarScroll.horizontal,
            calendarBackground: widget.calendarBackground,
            events: widget.events,
            onDateChange: (date) {
              setState(() {
                _selectedDate = date;
              });
              widget.onDateSelected(date);
            },
          );
  }
}
