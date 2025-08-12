import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../common/colo_extension.dart';
import 'widgets/profile_header.dart';
import 'widgets/account_section.dart';
import 'widgets/other_section.dart';
import '../login/login_view.dart';
import 'personal_data_view.dart';
import 'activity_history_view.dart';
import 'workout_progress_view.dart';
import 'settings_view.dart';
import 'achievements_view.dart';
import 'privacy_policy_view.dart';
import 'help_support_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Constants for better maintainability
  static const String _personalDataTag = "1";
  static const String _achievementsTag = "2";
  static const String _activityHistoryTag = "3";
  static const String _workoutProgressTag = "4";
  static const String _contactUsTag = "5";
  static const String _privacyPolicyTag = "6";
  static const String _settingsTag = "7";
  static const String _logoutTag = "8";

  // Type-safe lists with proper typing
  late final List<Map<String, String>> _accountItems;
  late final List<Map<String, String>> _otherItems;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _initializeMenuItems();
  }

  void _initializeMenuItems() {
    _accountItems = [
      {
        "image": "assets/img/p_personal.png",
        "name": "Personal Data",
        "tag": _personalDataTag
      },
      {
        "image": "assets/img/p_activity.png",
        "name": "Achievement",
        "tag": _achievementsTag
      },
      {
        "image": "assets/img/p_activity.png",
        "name": "Activity History",
        "tag": _activityHistoryTag
      },
      {
        "image": "assets/img/p_workout.png",
        "name": "Workout Progress",
        "tag": _workoutProgressTag
      }
    ];

    _otherItems = [
      {
        "image": "assets/img/p_contact.png",
        "name": "Contact Us",
        "tag": _contactUsTag
      },
      {
        "image": "assets/img/p_privacy.png",
        "name": "Privacy Policy",
        "tag": _privacyPolicyTag
      },
      {
        "image": "assets/img/p_setting.png",
        "name": "Settings",
        "tag": _settingsTag
      },
      {"image": "assets/img/logout.png", "name": "Logout", "tag": _logoutTag},
    ];
  }

  /// Handles account section navigation
  Future<void> _handleAccountAction(String tag) async {
    switch (tag) {
      case _personalDataTag:
        _navigateToPersonalData();
        break;
      case _achievementsTag:
        _navigateToAchievements();
        break;
      case _activityHistoryTag:
        _navigateToActivityHistory();
        break;
      case _workoutProgressTag:
        _navigateToWorkoutProgress();
        break;
      default:
        debugPrint('Unhandled account action: $tag');
    }
  }

  /// Handles logout and other actions from the "Other" section
  Future<void> _handleOtherAction(String tag) async {
    switch (tag) {
      case _logoutTag:
        await _performLogout();
        break;
      case _contactUsTag:
        _navigateToContactUs();
        break;
      case _privacyPolicyTag:
        _navigateToPrivacyPolicy();
        break;
      case _settingsTag:
        _navigateToSettings();
        break;
      default:
        debugPrint('Unhandled other action: $tag');
    }
  }

  // Navigation methods
  void _navigateToPersonalData() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalDataView(),
      ),
    );
  }

  void _navigateToAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AchievementsView(),
      ),
    );
  }

  void _navigateToActivityHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActivityHistoryView(),
      ),
    );
  }

  void _navigateToWorkoutProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutProgressView(),
      ),
    );
  }

  void _navigateToContactUs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpSupportView(),
      ),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyView(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsView(),
      ),
    );
  }

  /// Performs secure logout with loading state and confirmation
  Future<void> _performLogout() async {
    if (_isLoggingOut) return; // Prevent multiple logout attempts

    // Show confirmation dialog
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: TColor.primaryColor1),
              const SizedBox(width: 10),
              const Text('Confirm Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: TColor.gray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primaryColor1,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _handleMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "More Options",
              style: TextStyle(
                color: TColor.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TColor.primaryColor1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.share, color: TColor.primaryColor1),
              ),
              title: const Text("Share App"),
              subtitle: const Text("Invite friends to join"),
              onTap: () {
                Navigator.pop(context);
                _shareApp();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: Colors.orange),
              ),
              title: const Text("Rate App"),
              subtitle: const Text("Rate us on app store"),
              onTap: () {
                Navigator.pop(context);
                _rateApp();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.backup, color: Colors.green),
              ),
              title: const Text("Backup Data"),
              subtitle: const Text("Backup your fitness data"),
              onTap: () {
                Navigator.pop(context);
                _backupData();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _shareApp() {
    // TODO: Implement app sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _rateApp() {
    // TODO: Implement app rating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _backupData() {
    // TODO: Implement data backup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leadingWidth: 0,
        title: Text(
          "Profile",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          InkWell(
            onTap: _handleMoreOptions,
            borderRadius: BorderRadius.circular(10),
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
      body: _isLoggingOut
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Logging out...",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ProfileHeader(),
                    const SizedBox(height: 25),

                    // Account Section
                    AccountSection(
                      accountArr: _accountItems,
                      onItemPressed: _handleAccountAction,
                    ),
                    const SizedBox(height: 25),

                    // Other Section
                    OtherSection(
                      otherArr: _otherItems,
                      onItemPressed: _handleOtherAction,
                    ),

                    const SizedBox(height: 40),

                    // App version info
                    Center(
                      child: Text(
                        "Fitness App v1.0.0",
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
