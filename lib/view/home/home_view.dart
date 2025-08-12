import 'package:nextfitx/common_widget/round_button.dart';
import 'package:nextfitx/services/user_service.dart';
import 'package:nextfitx/services/body_composition_service.dart';
import 'package:nextfitx/services/workout_service.dart';
import 'package:nextfitx/services/sleep_service.dart';
import 'package:nextfitx/services/meal_service.dart';
import 'package:nextfitx/services/intermittent_fasting_service.dart';
import 'package:nextfitx/services/water_intake_service.dart';
import 'package:nextfitx/services/notification_service.dart';
import 'package:nextfitx/models/sleep_model.dart';
import 'package:nextfitx/view/body_composition/body_composition_view.dart';
import 'package:nextfitx/view/notifications/notifications_view.dart';
import 'package:nextfitx/view/workout/workout_view.dart';
import 'package:nextfitx/view/sleep/sleep_view.dart';
import 'package:nextfitx/view/meal/meal_view.dart';
import 'package:nextfitx/view/intermittent_fasting/intermittent_fasting_view.dart';
import 'package:nextfitx/view/workout_academy/workout_academy_view.dart';
import 'package:nextfitx/view/home/daily_progress_view.dart';
import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final UserService _userService = UserService();
  final BodyCompositionService _bodyCompositionService =
      BodyCompositionService();
  final WorkoutService _workoutService = WorkoutService();
  final SleepService _sleepService = SleepService();
  final MealService _mealService = MealService();
  final IntermittentFastingService _fastingService =
      IntermittentFastingService();
  final WaterIntakeService _waterService = WaterIntakeService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  String _userName = '';
  double _userBMI = 0.0;
  String _bmiStatus = '';
  double _todayCaloriesBurned = 0.0;
  int _todayWorkouts = 0;
  double _lastNightSleepHours = 0.0;
  double _todayCaloriesConsumed = 0.0;
  bool _isFasting = false;
  int _fastingStreak = 0;
  int _todayWaterMl = 0;
  double _waterProgress = 0.0;
  int _waterTarget = 2500;
  bool _isAddingWater = false;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTodayProgress();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userService.getUserProfile();

      if (mounted) {
        setState(() {
          _userName =
              '${profile?['firstName'] ?? ''} ${profile?['lastName'] ?? ''}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _userName = 'User';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTodayProgress() async {
    try {
      // Load workout summary for today only
      final currentDateTime = DateTime.now();
      final todayStart = DateTime(
          currentDateTime.year, currentDateTime.month, currentDateTime.day);
      final todayEnd = DateTime(currentDateTime.year, currentDateTime.month,
          currentDateTime.day, 23, 59, 59);

      final workoutSummary = await _workoutService.getWorkoutSummary(
        startDate: todayStart,
        endDate: todayEnd,
      );

      // Load latest body composition for BMI
      final bodyCompRecords =
          await _bodyCompositionService.getBodyCompositionRecords(limit: 1);

      // Load today's sleep data only - Focus on current date
      final now = DateTime.now();

      // Only look for sleep data from TODAY (current date)
      final todayDate = DateTime(now.year, now.month, now.day);

      print('=== DEBUG SLEEP DATA ===');
      print('Current time: $now');
      print('Looking for sleep data on: $todayDate (TODAY ONLY)');

      // Only get sleep data from TODAY - STRICT CHECK
      SleepModel? todaySleep;

      // Get sleep data for today only
      final sleepData = await _sleepService.getSleepForDate(todayDate);
      if (sleepData != null) {
        // Validate the date is actually today
        final sleepDate = DateTime(
            sleepData.date.year, sleepData.date.month, sleepData.date.day);
        if (sleepDate.isAtSameMomentAs(todayDate)) {
          todaySleep = sleepData;
          print('Found today\'s sleep: ${todaySleep.durationHours}h');
        } else {
          print('Sleep data found but date mismatch: $sleepDate vs $todayDate');
        }
      }

      // STRICT: If no sleep data found for today, explicitly set to null
      if (todaySleep == null) {
        print('No sleep data found for today - will show 0.0h');
      }

      print('Final sleep data: ${todaySleep?.durationHours ?? 0.0}h');
      print('========================');

      // Load today's nutrition summary
      final todayNutrition = await _mealService.getTodayNutritionSummary();

      // Load current fasting status
      final activeFasting = await _fastingService.getActiveFasting();
      final fastingStreak = await _fastingService.getFastingSummary(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      // Load today's water intake
      final waterSummary = await _waterService.getTodayWaterSummary();

      // Load unread notification count
      final unreadCount = await _notificationService.getUnreadCount();

      if (mounted) {
        setState(() {
          _todayCaloriesBurned = workoutSummary.totalCaloriesBurned;
          _todayWorkouts = workoutSummary.totalWorkouts;

          // Sleep data - TODAY ONLY validation
          if (todaySleep != null) {
            // Double-check the sleep date is exactly today
            final sleepDate = DateTime(todaySleep.date.year,
                todaySleep.date.month, todaySleep.date.day);
            final currentDate = DateTime(currentDateTime.year,
                currentDateTime.month, currentDateTime.day);

            if (sleepDate.isAtSameMomentAs(currentDate)) {
              // Sleep is from today - valid
              _lastNightSleepHours = todaySleep.durationHours;
              print(
                  'Using today\'s sleep data: ${_lastNightSleepHours}h from $sleepDate');
            } else {
              // Sleep is not from today - reject it
              _lastNightSleepHours = 0.0;
              print(
                  'Rejecting sleep data - not from today: $sleepDate vs $currentDate');
            }
          } else {
            // No sleep data found for today
            _lastNightSleepHours = 0.0;
            print('No sleep data for today - setting to 0.0h');
          }

          // Meal data
          _todayCaloriesConsumed = todayNutrition['calories'] ?? 0.0;

          // Fasting data
          _isFasting = activeFasting != null;
          _fastingStreak = fastingStreak.currentStreak;

          // Water data
          _todayWaterMl = waterSummary.effectiveHydrationMl;
          _waterProgress = waterSummary.progressPercentage;
          _waterTarget = waterSummary.targetMl;

          // Notification data
          _unreadNotificationCount = unreadCount;

          if (bodyCompRecords.isNotEmpty) {
            _userBMI = bodyCompRecords.first.bodyComposition.bmi;

            // Calculate BMI status
            if (_userBMI < 18.5) {
              _bmiStatus = 'Underweight';
            } else if (_userBMI < 25) {
              _bmiStatus = 'Normal weight';
            } else if (_userBMI < 30) {
              _bmiStatus = 'Overweight';
            } else {
              _bmiStatus = 'Obese';
            }
          } else {
            _userBMI = 0.0;
            _bmiStatus = 'No Data';
          }
        });
      }
    } catch (e) {
      print('Error loading today progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    var isTablet = media.width > 600;
    var isLargeScreen = media.width > 900;

    // Responsive sizing
    double cardHeight = isTablet ? media.width * 0.25 : media.width * 0.45;
    double headerHeight = isTablet ? 80 : 60;
    double iconSize = isTablet ? 32 : 28;
    double fontSize = isTablet ? 16 : 14;
    double titleFontSize = isTablet ? 18 : 16;
    double largeFontSize = isTablet ? 22 : 18;
    double bmiFontSize = isTablet ? 32 : 26;
    double padding = isTablet ? 30 : 20;
    double spacing = isTablet ? 30 : 25;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: TColor.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isTablet ? 15 : 10),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: isTablet ? 55 : 45,
                          height: isTablet ? 55 : 45,
                          decoration: BoxDecoration(
                            color: TColor.white,
                            borderRadius:
                                BorderRadius.circular(isTablet ? 27.5 : 22.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
                            child: Image.asset(
                              "assets/img/logohome.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 20 : 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "NextFitX",
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: isTablet ? 3 : 2),
                            Text(
                              "Welcome Back, $_userName",
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: isTablet ? 15 : 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Daily Progress Button
                        Container(
                          margin: EdgeInsets.only(right: isTablet ? 15 : 10),
                          decoration: BoxDecoration(
                            color: TColor.white,
                            borderRadius:
                                BorderRadius.circular(isTablet ? 18 : 15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DailyProgressView(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.trending_up,
                              size: iconSize,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        // Notifications Button
                        Container(
                          decoration: BoxDecoration(
                            color: TColor.white,
                            borderRadius:
                                BorderRadius.circular(isTablet ? 18 : 15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsView(),
                                    ),
                                  ).then((_) {
                                    // Refresh notification count when returning
                                    _loadTodayProgress();
                                  });
                                },
                                icon: Icon(
                                  Icons.notifications_outlined,
                                  size: iconSize,
                                  color: _unreadNotificationCount > 0
                                      ? TColor.primaryColor1
                                      : TColor.gray,
                                ),
                              ),
                              // Unread notification badge
                              if (_unreadNotificationCount > 0)
                                Positioned(
                                  right: isTablet ? 10 : 8,
                                  top: isTablet ? 10 : 8,
                                  child: Container(
                                    padding: EdgeInsets.all(isTablet ? 6 : 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(
                                          isTablet ? 12 : 10),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: isTablet ? 20 : 16,
                                      minHeight: isTablet ? 20 : 16,
                                    ),
                                    child: Text(
                                      _unreadNotificationCount > 99
                                          ? '99+'
                                          : _unreadNotificationCount.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 12 : 10,
                                        fontWeight: FontWeight.bold,
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
                  ],
                ),
                SizedBox(height: spacing),

                // BMI Card
                Container(
                  height: isTablet ? media.width * 0.25 : media.width * 0.4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: TColor.primaryG),
                    borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: TColor.primaryG.first.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        "assets/img/bg_dots.png",
                        height:
                            isTablet ? media.width * 0.25 : media.width * 0.4,
                        width: double.maxFinite,
                        fit: BoxFit.fitHeight,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 30 : 25,
                          horizontal: isTablet ? 30 : 25,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "BMI (Body Mass Index)",
                                    style: TextStyle(
                                      color: TColor.white,
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 8 : 5),
                                  Text(
                                    "You have a $_bmiStatus",
                                    style: TextStyle(
                                      color: TColor.white.withOpacity(0.8),
                                      fontSize: isTablet ? 15 : 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 25 : 20),
                                  SizedBox(
                                    width: isTablet ? 150 : 130,
                                    height: isTablet ? 45 : 38,
                                    child: RoundButton(
                                      title: "View More",
                                      type: RoundButtonType.bgSGradient,
                                      fontSize: isTablet ? 15 : 13,
                                      fontWeight: FontWeight.w600,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const BodyCompositionView(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isTablet ? 25 : 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: isTablet ? 100 : 85,
                                  height: isTablet ? 100 : 85,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: TColor.white,
                                    borderRadius: BorderRadius.circular(
                                        isTablet ? 50 : 42.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _userBMI.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: TColor.primaryColor1,
                                      fontSize: bmiFontSize,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isTablet ? 10 : 8),
                                Text(
                                  "kg/m²",
                                  style: TextStyle(
                                    color: TColor.white,
                                    fontSize: isTablet ? 15 : 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing),

                // Today's Activity Summary
                Row(
                  children: [
                    // Calories Burned
                    Expanded(
                      child: Container(
                        height: cardHeight,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 30 : 25,
                          horizontal: isTablet ? 30 : 25,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(isTablet ? 25 : 20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Calories Burned",
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: isTablet ? 15 : 12),
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: TColor.primaryG,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(
                                  Rect.fromLTRB(
                                    0,
                                    0,
                                    bounds.width,
                                    bounds.height,
                                  ),
                                );
                              },
                              child: Text(
                                "${_todayCaloriesBurned.toStringAsFixed(0)} kcal",
                                style: TextStyle(
                                  color: TColor.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: largeFontSize,
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 15 : 12),
                            Text(
                              "Total today",
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 12 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 25 : 20),
                                ),
                                child: Icon(
                                  Icons.local_fire_department,
                                  size: isTablet ? 40 : 35,
                                  color: Colors.orange.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 25 : 20),

                    // Workouts Today
                    Expanded(
                      child: Container(
                        height: cardHeight,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 30 : 25,
                          horizontal: isTablet ? 30 : 25,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(isTablet ? 25 : 20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Workouts",
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: isTablet ? 15 : 12),
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: TColor.primaryG,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(
                                  Rect.fromLTRB(
                                    0,
                                    0,
                                    bounds.width,
                                    bounds.height,
                                  ),
                                );
                              },
                              child: Text(
                                _todayWorkouts.toString(),
                                style: TextStyle(
                                  color: TColor.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: largeFontSize,
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 15 : 12),
                            Text(
                              "Sessions today",
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 12 : 8),
                                decoration: BoxDecoration(
                                  color: TColor.primaryColor1.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 25 : 20),
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  size: isTablet ? 40 : 35,
                                  color: TColor.primaryColor1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 25 : 20),

                // Sleep & Nutrition Row
                Row(
                  children: [
                    // Sleep Duration
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SleepView(),
                            ),
                          ).then((_) => _loadTodayProgress());
                        },
                        child: Container(
                          height: cardHeight,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 30 : 25,
                            horizontal: isTablet ? 30 : 25,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(isTablet ? 25 : 20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sleep Today",
                                style: TextStyle(
                                  color: TColor.black,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: isTablet ? 15 : 12),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: [
                                      const Color(0xFF9C27B0),
                                      const Color(0xFF673AB7),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ).createShader(
                                    Rect.fromLTRB(
                                      0,
                                      0,
                                      bounds.width,
                                      bounds.height,
                                    ),
                                  );
                                },
                                child: Text(
                                  _lastNightSleepHours == 0.0
                                      ? "No data"
                                      : "${_lastNightSleepHours.toStringAsFixed(1)}h",
                                  style: TextStyle(
                                    color: TColor.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w700,
                                    fontSize: largeFontSize,
                                  ),
                                ),
                              ),
                              SizedBox(height: isTablet ? 15 : 12),
                              Text(
                                _lastNightSleepHours == 0.0
                                    ? "Add today's sleep"
                                    : (_lastNightSleepHours >= 7 &&
                                            _lastNightSleepHours <= 9)
                                        ? "Good sleep today! 😴"
                                        : _lastNightSleepHours < 7
                                            ? "Too short today 😪"
                                            : "Too long today 😴",
                                style: TextStyle(
                                  color: TColor.gray,
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9C27B0)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        isTablet ? 25 : 20),
                                  ),
                                  child: Icon(
                                    Icons.bedtime,
                                    size: isTablet ? 40 : 35,
                                    color: const Color(0xFF9C27B0)
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 25 : 20),

                    // Calories Consumed
                    Expanded(
                      child: Container(
                        height: cardHeight,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 30 : 25,
                          horizontal: isTablet ? 30 : 25,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(isTablet ? 25 : 20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nutrition",
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: isTablet ? 15 : 12),
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    const Color(0xFF4CAF50),
                                    const Color(0xFF2E7D32),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(
                                  Rect.fromLTRB(
                                    0,
                                    0,
                                    bounds.width,
                                    bounds.height,
                                  ),
                                );
                              },
                              child: Text(
                                "${_todayCaloriesConsumed.toStringAsFixed(0)} kcal",
                                style: TextStyle(
                                  color: TColor.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: largeFontSize,
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 15 : 12),
                            Text(
                              "Consumed today",
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 12 : 8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 25 : 20),
                                ),
                                child: Icon(
                                  Icons.restaurant,
                                  size: isTablet ? 40 : 35,
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 25 : 20),

                // Water Intake Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 25 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00BCD4),
                        const Color(0xFF0097A7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isTablet ? 15 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(isTablet ? 18 : 15),
                            ),
                            child: Icon(
                              Icons.water_drop,
                              size: isTablet ? 32 : 28,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "💧 Water Intake",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 8 : 5),
                                Text(
                                  "${(_todayWaterMl / 1000).toStringAsFixed(1)}L / ${(_waterTarget / 1000).toStringAsFixed(1)}L",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quick Add 250ml Button
                          GestureDetector(
                            onTap:
                                _isAddingWater ? null : () => _quickAddWater(),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 20 : 15,
                                  vertical: isTablet ? 12 : 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 25 : 20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isAddingWater) ...[
                                    SizedBox(
                                      width: isTablet ? 14 : 12,
                                      height: isTablet ? 14 : 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 10 : 8),
                                  ] else ...[
                                    Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: isTablet ? 18 : 16,
                                    ),
                                    SizedBox(width: isTablet ? 6 : 5),
                                  ],
                                  Text(
                                    "250ml",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 20 : 15),

                      // Progress Bar
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: (_waterProgress / 100).clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: isTablet ? 10 : 8,
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Progress: ${_waterProgress.toStringAsFixed(0)}%",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _waterProgress >= 100
                                    ? "Goal reached! 🎉"
                                    : "${((_waterTarget - _todayWaterMl) / 250).ceil()} glasses left",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 25 : 20),

                // Fasting Status Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IntermittentFastingView(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 25 : 20),
                    decoration: BoxDecoration(
                      gradient: _isFasting
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF6A5ACD),
                                const Color(0xFF4169E1),
                              ],
                            )
                          : null,
                      color: _isFasting ? null : Colors.white,
                      borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: _isFasting
                              ? const Color(0xFF6A5ACD).withOpacity(0.3)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 15 : 12),
                          decoration: BoxDecoration(
                            color: _isFasting
                                ? Colors.white.withOpacity(0.2)
                                : TColor.primaryColor1.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(isTablet ? 18 : 15),
                          ),
                          child: Icon(
                            Icons.schedule,
                            size: isTablet ? 32 : 28,
                            color: _isFasting
                                ? Colors.white
                                : TColor.primaryColor1,
                          ),
                        ),
                        SizedBox(width: isTablet ? 20 : 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isFasting
                                    ? "🔥 Currently Fasting"
                                    : "Intermittent Fasting",
                                style: TextStyle(
                                  color:
                                      _isFasting ? Colors.white : TColor.black,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: isTablet ? 8 : 5),
                              Text(
                                _isFasting
                                    ? "Fasting session active"
                                    : "Streak: $_fastingStreak days",
                                style: TextStyle(
                                  color: _isFasting
                                      ? Colors.white.withOpacity(0.8)
                                      : TColor.gray,
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 15 : 12,
                              vertical: isTablet ? 10 : 8),
                          decoration: BoxDecoration(
                            color: _isFasting
                                ? Colors.white.withOpacity(0.2)
                                : (_fastingStreak > 0
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1)),
                            borderRadius:
                                BorderRadius.circular(isTablet ? 18 : 15),
                          ),
                          child: Text(
                            _isFasting
                                ? "ACTIVE"
                                : (_fastingStreak > 0
                                    ? "$_fastingStreak🔥"
                                    : "START"),
                            style: TextStyle(
                              color: _isFasting
                                  ? Colors.white
                                  : (_fastingStreak > 0
                                      ? Colors.orange
                                      : TColor.gray),
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: spacing),

                // Quick Actions
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 25 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quick Actions",
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: isTablet ? 20 : 15),
                      // Responsive grid for quick actions
                      if (isLargeScreen) ...[
                        // Large screen: 3 columns
                        Row(
                          children: [
                            Expanded(
                                child: _buildQuickActionButton(
                                    "🎓 Academy",
                                    Colors.indigo,
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const WorkoutAcademyView())))),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    "💪 Workout",
                                    Colors.orange,
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const WorkoutView())))),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    "📊 Body Comp",
                                    TColor.primaryColor1,
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const BodyCompositionView())))),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                                child: _buildQuickActionButton(
                                    "😴 Sleep",
                                    const Color(0xFF9C27B0),
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SleepView())))),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    "🍽️ Meals",
                                    const Color(0xFF4CAF50),
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const MealView())))),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    _isFasting
                                        ? "🔥 Manage Fasting"
                                        : "⏱️ Start Fasting",
                                    const Color(0xFF6A5ACD),
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const IntermittentFastingView())))),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                                child: _buildQuickActionButton(
                                    "💧 Water +250ml",
                                    const Color(0xFF00BCD4),
                                    () => _quickAddWater())),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    "📊 Daily Progress",
                                    Colors.indigo,
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const DailyProgressView())))),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    "🔔 Notifications${_unreadNotificationCount > 0 ? ' ($_unreadNotificationCount)' : ''}",
                                    Colors.purple,
                                    () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const NotificationsView()))
                                        .then((_) => _loadTodayProgress()))),
                          ],
                        ),
                      ] else ...[
                        // Small/medium screen: 2 columns
                        Row(
                          children: [
                            Expanded(
                                child: _buildQuickActionButton(
                                    "🎓 Academy",
                                    Colors.indigo,
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const WorkoutAcademyView())))),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    "💪 Workout",
                                    Colors.orange,
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const WorkoutView())))),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                                child: _buildQuickActionButton(
                                    "📊 Body Comp",
                                    TColor.primaryColor1,
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const BodyCompositionView())))),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    "😴 Sleep",
                                    const Color(0xFF9C27B0),
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SleepView())))),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                                child: _buildQuickActionButton(
                                    "🍽️ Meals",
                                    const Color(0xFF4CAF50),
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const MealView())))),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    _isFasting
                                        ? "🔥 Manage Fasting"
                                        : "⏱️ Start Fasting",
                                    const Color(0xFF6A5ACD),
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const IntermittentFastingView())))),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                                child: _buildQuickActionButton(
                                    "💧 Water +250ml",
                                    const Color(0xFF00BCD4),
                                    () => _quickAddWater())),
                            const SizedBox(width: 15),
                            Expanded(
                                child: _buildQuickActionButton(
                                    "📊 Daily Progress",
                                    Colors.indigo,
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const DailyProgressView())))),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                                child: _buildQuickActionButton(
                                    "🔔 Notifications${_unreadNotificationCount > 0 ? ' ($_unreadNotificationCount)' : ''}",
                                    Colors.purple,
                                    () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const NotificationsView()))
                                        .then((_) => _loadTodayProgress()))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: spacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _quickAddWater() async {
    setState(() => _isAddingWater = true);

    try {
      await _waterService.quickAddWater(250);

      // Reload water data
      final waterSummary = await _waterService.getTodayWaterSummary();

      if (mounted) {
        setState(() {
          _todayWaterMl = waterSummary.effectiveHydrationMl;
          _waterProgress = waterSummary.progressPercentage;
          _waterTarget = waterSummary.targetMl;
          _isAddingWater = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '💧 Added 250ml water! ${waterSummary.effectiveHydrationFormatted} / ${waterSummary.targetFormatted}',
            ),
            backgroundColor: const Color(0xFF00BCD4),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingWater = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding water: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildQuickActionButton(
      String title, Color color, VoidCallback onPressed) {
    var media = MediaQuery.of(context).size;
    var isTablet = media.width > 600;

    return Container(
      height: isTablet ? 60 : 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
