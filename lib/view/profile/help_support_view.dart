import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';

class HelpSupportView extends StatefulWidget {
  const HelpSupportView({super.key});

  @override
  State<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends State<HelpSupportView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Help & Support",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TabBar(
              controller: _tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 2.0,
                  color: TColor.primaryColor1,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              labelColor: TColor.primaryColor1,
              unselectedLabelColor: TColor.gray,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: "FAQ"),
                Tab(text: "Contact"),
                Tab(text: "Guides"),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFAQTab(),
                _buildContactTab(),
                _buildGuidesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    final faqs = _getFAQs();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return _buildFAQItem(faqs[index]);
      },
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Get in Touch",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _buildContactCard(
            "Email Support",
            "Send us an email for detailed assistance",
            Icons.email,
            TColor.primaryColor1,
            () => _sendEmail(),
          ),
          const SizedBox(height: 15),
          _buildContactCard(
            "Live Chat",
            "Chat with our support team",
            Icons.chat,
            Colors.green,
            () => _startLiveChat(),
          ),
          const SizedBox(height: 15),
          _buildContactCard(
            "Call Us",
            "Speak directly with our team",
            Icons.phone,
            Colors.blue,
            () => _makePhoneCall(),
          ),
          const SizedBox(height: 15),
          _buildContactCard(
            "Report Bug",
            "Found a bug? Let us know",
            Icons.bug_report,
            Colors.orange,
            () => _reportBug(),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Support Hours",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Monday - Friday: 9:00 AM - 6:00 PM\nSaturday: 10:00 AM - 4:00 PM\nSunday: Closed",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
    final guides = _getGuides();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: guides.length,
      itemBuilder: (context, index) {
        return _buildGuideCard(guides[index]);
      },
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: TextStyle(
            color: TColor.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: faq['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            faq['icon'],
            color: faq['color'],
            size: 20,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              faq['answer'],
              style: TextStyle(
                color: TColor.gray,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                  const SizedBox(height: 2),
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
      ),
    );
  }

  Widget _buildGuideCard(Map<String, dynamic> guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: guide['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  guide['icon'],
                  color: guide['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  guide['title'],
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            guide['description'],
            style: TextStyle(
              color: TColor.gray,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),

          // Steps
          ...guide['steps'].asMap().entries.map((entry) {
            int index = entry.key + 1;
            String step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: guide['color'],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "$index",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFAQs() {
    return [
      {
        'question': 'How do I track my workouts?',
        'answer':
            'To track workouts, go to the Workout section from the home screen. Tap the "+" button to add a new workout. Select your exercise type, duration, and the app will automatically calculate calories burned.',
        'icon': Icons.fitness_center,
        'color': TColor.primaryColor1,
      },
      {
        'question': 'Why is my data not syncing?',
        'answer':
            'Data syncing issues can occur due to poor internet connection or Firebase server issues. Make sure you have a stable internet connection and try refreshing the app. If the problem persists, contact support.',
        'icon': Icons.sync_problem,
        'color': Colors.orange,
      },
      {
        'question': 'How do I change my notification settings?',
        'answer':
            'Go to Profile > Settings > Notifications. Here you can enable or disable different types of notifications including workout reminders, meal tracking, and water intake alerts.',
        'icon': Icons.notifications,
        'color': Colors.blue,
      },
      {
        'question': 'Can I export my fitness data?',
        'answer':
            'Yes! Go to Profile > Settings > Data & Sync > Export Data. You can download your complete fitness data including workouts, nutrition, sleep, and body measurements in CSV format.',
        'icon': Icons.download,
        'color': Colors.green,
      },
      {
        'question': 'How is my calorie calculation done?',
        'answer':
            'Calorie calculations are based on MET (Metabolic Equivalent of Task) values, your body weight, and workout duration. For meals, we use a comprehensive food database with nutritional information.',
        'icon': Icons.calculate,
        'color': Colors.purple,
      },
      {
        'question': 'Is my data secure and private?',
        'answer':
            'Absolutely! Your data is stored securely on Firebase with encryption. We never share your personal fitness data with third parties. Read our Privacy Policy for complete details.',
        'icon': Icons.security,
        'color': Colors.red,
      },
    ];
  }

  List<Map<String, dynamic>> _getGuides() {
    return [
      {
        'title': 'Getting Started Guide',
        'description':
            'Learn how to set up your profile and start tracking your fitness journey.',
        'icon': Icons.play_circle,
        'color': TColor.primaryColor1,
        'steps': [
          'Complete your profile with accurate body measurements',
          'Set your fitness goals and target weights',
          'Enable notifications for reminders',
          'Start with your first workout or meal log',
          'Explore all features: sleep, water, body composition',
        ],
      },
      {
        'title': 'Workout Tracking',
        'description': 'Master the art of tracking your workouts effectively.',
        'icon': Icons.fitness_center,
        'color': Colors.orange,
        'steps': [
          'Navigate to Workout section from home',
          'Tap "+" to add a new workout session',
          'Select workout type from the dropdown',
          'Enter duration in minutes',
          'Review auto-calculated calories',
          'Save and view your progress',
        ],
      },
      {
        'title': 'Troubleshooting',
        'description': 'Common issues and how to resolve them.',
        'icon': Icons.settings_suggest,
        'color': Colors.red,
        'steps': [
          'Force close and restart the app',
          'Check your internet connection',
          'Update to the latest app version',
          'Clear app cache in settings',
          'Contact support if issues persist',
        ],
      },
      {
        'title': 'Data Management',
        'description': 'Manage, backup, and export your fitness data.',
        'icon': Icons.storage,
        'color': Colors.green,
        'steps': [
          'Go to Profile > Settings > Data & Sync',
          'Use "Export Data" to download your information',
          'Use "Clear Cache" to free up storage',
          'Enable cloud sync for data backup',
          'Set up regular export schedules',
        ],
      },
    ];
  }

  void _sendEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening email client...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _startLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live chat feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _makePhoneCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone support: +1-800-FITNESS'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the issue you encountered:'),
            const SizedBox(height: 15),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the bug...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bug report submitted. Thank you!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
