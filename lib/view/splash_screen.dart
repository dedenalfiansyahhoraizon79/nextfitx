import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/colo_extension.dart';
import '../services/onboarding_service.dart';
import 'on_boarding/started_view.dart';
import 'login/login_view.dart';
import 'main_tab/main_tab_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Tampilkan splash screen selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Cek apakah user sudah login
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User sudah login, langsung ke main tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainTabView()),
      );
    } else {
      // User belum login, cek onboarding
      final hasSeenOnboarding = await _onboardingService.hasSeenOnboarding();

      if (hasSeenOnboarding) {
        // Sudah pernah lihat onboarding, langsung ke login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      } else {
        // Belum pernah lihat onboarding, tampilkan onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StartedView()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.white,
      body: Container(
        width: media.width,
        height: media.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: TColor.primaryG,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: TColor.white,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Image.asset(
                  "assets/img/logofix.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Nama aplikasi
            Text(
              "nextfitX",
              style: TextStyle(
                color: TColor.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Your Fitness Journey Starts Here",
              style: TextStyle(
                color: TColor.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 50),

            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TColor.white),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
