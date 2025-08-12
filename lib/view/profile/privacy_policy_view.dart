import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
          "Privacy Policy",
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
            Text(
              "Privacy Policy",
              style: TextStyle(
                color: TColor.black,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
              style: TextStyle(
                color: TColor.gray,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 30),
            _buildSection(
              "1. Introduction",
              "Welcome to Fitness App. We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our mobile application.",
            ),
            _buildSection(
              "2. Information We Collect",
              "We collect information you provide directly to us, such as:\n"
                  "• Account information (email, name, profile picture)\n"
                  "• Fitness data (workouts, body measurements, sleep patterns)\n"
                  "• Nutrition information (meals, water intake)\n"
                  "• Device information (device type, operating system)\n"
                  "• Usage data (app interactions, features used)",
            ),
            _buildSection(
              "3. How We Use Your Information",
              "We use your information to:\n"
                  "• Provide and maintain our service\n"
                  "• Personalize your fitness experience\n"
                  "• Track your progress and achievements\n"
                  "• Send you notifications and reminders\n"
                  "• Improve our app and develop new features\n"
                  "• Provide customer support",
            ),
            _buildSection(
              "4. Data Storage and Security",
              "Your data is stored securely using Firebase, Google's cloud platform. We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.",
            ),
            _buildSection(
              "5. Data Sharing",
              "We do not sell, trade, or otherwise transfer your personal information to third parties. We may share anonymized, aggregated data for research and improvement purposes. Your personal fitness data remains private and is never shared without your explicit consent.",
            ),
            _buildSection(
              "6. Your Rights",
              "You have the right to:\n"
                  "• Access your personal data\n"
                  "• Correct inaccurate information\n"
                  "• Delete your account and data\n"
                  "• Export your data\n"
                  "• Opt-out of notifications\n"
                  "• Withdraw consent at any time",
            ),
            _buildSection(
              "7. Data Retention",
              "We retain your personal information only as long as necessary to provide our services and fulfill the purposes outlined in this policy. You can delete your account and data at any time through the app settings.",
            ),
            _buildSection(
              "8. Children's Privacy",
              "Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.",
            ),
            _buildSection(
              "9. Changes to This Policy",
              "We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the 'Last updated' date.",
            ),
            _buildSection(
              "10. Contact Us",
              "If you have any questions about this Privacy Policy, please contact us:\n"
                  "• Email: privacy@fitnessapp.com\n"
                  "• Address: 123 Fitness Street, Health City, HC 12345",
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TColor.primaryColor1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: TColor.primaryColor1.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: TColor.primaryColor1,
                    size: 24,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Privacy Matters",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "We are committed to protecting your personal information and maintaining transparency about our data practices.",
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
