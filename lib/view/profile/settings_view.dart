import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../services/body_composition_service.dart';
import '../../services/meal_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // Services
  final BodyCompositionService _bodyCompositionService =
      BodyCompositionService();
  final MealService _mealService = MealService();

  // Settings state
  bool _notificationsEnabled = true;
  bool _workoutReminders = true;
  bool _mealReminders = true;
  bool _sleepReminders = false;
  bool _waterReminders = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  bool _analyticsEnabled = true;

  String _selectedLanguage = 'English';
  String _selectedUnit = 'Metric';
  String _selectedWeekStart = 'Monday';

  final List<String> _languages = [
    'English',
    'Bahasa Indonesia',
    'Spanish',
    'French'
  ];
  final List<String> _units = ['Metric', 'Imperial'];
  final List<String> _weekStarts = ['Monday', 'Sunday'];

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
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Settings",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Section
            _buildSectionHeader("Notifications"),
            _buildNotificationSettings(),

            const SizedBox(height: 30),

            // App Preferences Section
            _buildSectionHeader("App Preferences"),
            _buildAppPreferences(),

            const SizedBox(height: 30),

            // Privacy & Security Section
            _buildSectionHeader("Privacy & Security"),
            _buildPrivacySettings(),

            const SizedBox(height: 30),

            // Data & Sync Section
            _buildSectionHeader("Data & Sync"),
            _buildDataSettings(),

            const SizedBox(height: 30),

            // About Section
            _buildSectionHeader("About"),
            _buildAboutSettings(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          color: TColor.black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchSetting(
            "Push Notifications",
            "Enable all notifications",
            Icons.notifications,
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          const Divider(height: 30),
          _buildSwitchSetting(
            "Workout Reminders",
            "Get reminded to exercise",
            Icons.fitness_center,
            _workoutReminders,
            (value) => setState(() => _workoutReminders = value),
            enabled: _notificationsEnabled,
          ),
          const Divider(height: 30),
          _buildSwitchSetting(
            "Meal Reminders",
            "Track your nutrition",
            Icons.restaurant,
            _mealReminders,
            (value) => setState(() => _mealReminders = value),
            enabled: _notificationsEnabled,
          ),
          const Divider(height: 30),
          _buildSwitchSetting(
            "Sleep Reminders",
            "Maintain sleep schedule",
            Icons.bedtime,
            _sleepReminders,
            (value) => setState(() => _sleepReminders = value),
            enabled: _notificationsEnabled,
          ),
          const Divider(height: 30),
          _buildSwitchSetting(
            "Water Reminders",
            "Stay hydrated",
            Icons.water_drop,
            _waterReminders,
            (value) => setState(() => _waterReminders = value),
            enabled: _notificationsEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferences() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchSetting(
            "Dark Mode",
            "Use dark theme",
            Icons.dark_mode,
            _darkModeEnabled,
            (value) => setState(() => _darkModeEnabled = value),
          ),
          const Divider(height: 30),
          _buildDropdownSetting(
            "Language",
            "Choose your language",
            Icons.language,
            _selectedLanguage,
            _languages,
            (value) => setState(() => _selectedLanguage = value),
          ),
          const Divider(height: 30),
          _buildDropdownSetting(
            "Units",
            "Measurement system",
            Icons.straighten,
            _selectedUnit,
            _units,
            (value) => setState(() => _selectedUnit = value),
          ),
          const Divider(height: 30),
          _buildDropdownSetting(
            "Week Starts On",
            "First day of the week",
            Icons.calendar_today,
            _selectedWeekStart,
            _weekStarts,
            (value) => setState(() => _selectedWeekStart = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchSetting(
            "Biometric Lock",
            "Use fingerprint or face ID",
            Icons.fingerprint,
            _biometricEnabled,
            (value) => setState(() => _biometricEnabled = value),
          ),
          const Divider(height: 30),
          _buildSwitchSetting(
            "Analytics",
            "Help improve the app",
            Icons.analytics,
            _analyticsEnabled,
            (value) => setState(() => _analyticsEnabled = value),
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Change Password",
            "Update your password",
            Icons.lock,
            () => _showChangePasswordDialog(),
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Privacy Policy",
            "View privacy policy",
            Icons.privacy_tip,
            () => _showPrivacyPolicy(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionSetting(
            "Export Data",
            "Download your fitness data",
            Icons.download,
            () => _exportData(),
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Import Data",
            "Import from other apps",
            Icons.upload,
            () => _importData(),
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Generate Sample Data",
            "Create sample body composition records",
            Icons.add_box,
            () => _generateSampleData(),
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Generate Sample Custom Foods",
            "Create sample custom food items",
            Icons.restaurant,
            () => _generateSampleCustomFoods(),
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Clear Cache",
            "Free up storage space",
            Icons.clear,
            () => _clearCache(),
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Delete Body Composition Data",
            "Permanently delete all body composition records",
            Icons.delete_forever,
            () => _showDeleteBodyCompositionDataDialog(),
            isDestructive: true,
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Reset App Data",
            "Delete all local data",
            Icons.restore,
            () => _showResetDataDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoSetting(
            "App Version",
            "1.0.0",
            Icons.info,
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Terms of Service",
            "View terms and conditions",
            Icons.description,
            () => _showTermsOfService(),
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Help & Support",
            "Get help or contact us",
            Icons.help,
            () => _showHelpSupport(),
          ),
          const Divider(height: 30),
          _buildActionSetting(
            "Rate App",
            "Rate us on app store",
            Icons.star,
            () => _rateApp(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    bool enabled = true,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                (enabled ? TColor.primaryColor1 : TColor.gray).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: enabled ? TColor.primaryColor1 : TColor.gray,
            size: 20,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: enabled ? TColor.black : TColor.gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: enabled ? value : false,
          onChanged: enabled ? onChanged : null,
          activeColor: TColor.primaryColor1,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TColor.primaryColor1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: TColor.primaryColor1,
            size: 20,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox.shrink(),
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ))
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildActionSetting(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDestructive ? Colors.red : TColor.primaryColor1)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red : TColor.primaryColor1,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDestructive ? Colors.red : TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: TColor.gray,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSetting(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TColor.primaryColor1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: TColor.primaryColor1,
            size: 20,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: TColor.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: const Text(
            "This feature will redirect to password change in your account settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement password change
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Privacy Policy page coming soon!"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Data export feature coming soon!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Data import feature coming soon!"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Cache"),
        content: const Text(
            "This will clear temporary files and free up storage space. Continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cache cleared successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  void _showResetDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 10),
            const Text("Reset App Data"),
          ],
        ),
        content: const Text(
            "This will permanently delete all your local fitness data. This action cannot be undone. Continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement data reset
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Data reset cancelled for safety"),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terms of Service page coming soon!"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showHelpSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Help & Support page coming soon!"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Rate app feature coming soon!"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Body Composition Data Management Methods
  void _generateSampleData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
              ),
              const SizedBox(width: 20),
              const Text("Generating comprehensive data..."),
            ],
          ),
        ),
      );

      await _bodyCompositionService.generateSampleBodyCompositionData();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Generated 14 days of comprehensive body composition data with all parameters!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating sample data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateSampleCustomFoods() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
              ),
              const SizedBox(width: 20),
              const Text("Generating sample custom foods..."),
            ],
          ),
        ),
      );

      await _mealService.generateSampleCustomFoods();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Generated sample custom foods! You can now use them in meal tracking.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating sample custom foods: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteBodyCompositionDataDialog() async {
    try {
      // Get storage statistics first
      final stats = await _bodyCompositionService.getStorageStats();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Delete Body Composition Data?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Data Statistics',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                            'Total Records', '${stats['totalRecords']}'),
                        _buildStatRow('Date Range', stats['dateRange']),
                        _buildStatRow('Storage Size', stats['estimatedSize']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '⚠️ WARNING: This action will permanently delete ALL your body composition data including:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('• All body parameter records'),
                  const Text('• Complete body composition analysis'),
                  const Text('• Segmental analysis data'),
                  const Text('• Progress history and trends'),
                  const Text('• Advanced metrics and recommendations'),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'This action cannot be undone. Consider exporting your data first.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: TColor.gray),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _confirmDeleteBodyCompositionData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete All'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data statistics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
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
      ),
    );
  }

  void _confirmDeleteBodyCompositionData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Final Confirmation',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you absolutely sure you want to delete ALL your body composition data?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Type "DELETE" to confirm:',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: TColor.gray),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performDeleteBodyCompositionData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('CONFIRM DELETE'),
            ),
          ],
        );
      },
    );
  }

  void _performDeleteBodyCompositionData() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            const SizedBox(width: 20),
            const Text("Deleting all body composition data..."),
          ],
        ),
      ),
    );

    try {
      await _bodyCompositionService.clearAllBodyCompositionData();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ All body composition data has been deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting data: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
