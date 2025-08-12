import 'package:flutter/material.dart';
import 'calendar.dart';

class CalendarAgendaState extends State<CalendarAgenda> {
  void getDate(DateTime date) {
    setState(() {
      widget.onDateSelected(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
