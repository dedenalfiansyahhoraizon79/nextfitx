import 'dart:math';

import 'package:calendar_agenda/calendar_agenda.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  ExamplePageState createState() => ExamplePageState();
}

class ExamplePageState extends State<ExamplePage> {
  final CalendarAgendaController _calendarAgendaControllerAppBar =
      CalendarAgendaController();

  late DateTime _selectedDateAppBBar;

  Random random = Random();

  @override
  void initState() {
    super.initState();
    _selectedDateAppBBar = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: CalendarAgenda(
          controller: _calendarAgendaControllerAppBar,
          appbar: true,
          selectedDayPosition: SelectedDayPosition.center,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          weekDay: WeekDay.long,
          dayNameFontSize: 12,
          dayNumberFontSize: 16,
          dayBGColor: Colors.grey.withValues(alpha: 0.15),
          titleSpaceBetween: 15,
          backgroundColor: Colors.white,
          fullCalendarScroll: FullCalendarScroll.horizontal,
          fullCalendarDay: WeekDay.long,
          selectedDateColor: Colors.white,
          dateColor: Colors.black,
          locale: 'en',
          initialDate: DateTime.now(),
          calendarEventColor: Colors.green,
          firstDate: DateTime.now().subtract(const Duration(days: 140)),
          lastDate: DateTime.now().add(const Duration(days: 60)),
          events: List.generate(
              100,
              (index) => DateTime.now()
                  .subtract(Duration(days: index * random.nextInt(5)))
                  .toIso8601String()
                  .split('T')
                  .first),
          onDateSelected: (date) {
            setState(() {
              _selectedDateAppBBar = date;
            });
          },
          selectedDayLogo: const Color(0xff9DCEFF),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                _calendarAgendaControllerAppBar.goToDay(DateTime.now());
              },
              child: const Text("Today, appbar = true"),
            ),
            Text('Selected date is $_selectedDateAppBBar'),
            const SizedBox(
              height: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}
