import 'package:nextfitx/common/colo_extension.dart';
import 'package:nextfitx/common_widget/tab_button.dart';
import 'package:nextfitx/view/main_tab/select_view.dart';
import 'package:flutter/material.dart';

import '../home/home_view.dart';
import '../photo_progress/photo_progress_view.dart';
import '../profile/profile_view.dart';
import '../meal/meal_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selectTab = 0;
  final PageStorageBucket pageBucket = PageStorageBucket();
  Widget currentTab = const HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: PageStorage(bucket: pageBucket, child: currentTab),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 40),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MealView(),
              ),
            );
          },
          backgroundColor: TColor.primaryColor1,
          elevation: 8,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: TColor.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TabButton(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: "Home",
                  isActive: selectTab == 0,
                  onTap: () {
                    selectTab = 0;
                    currentTab = const HomeView();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                TabButton(
                  icon: Icons.fitness_center_outlined,
                  selectedIcon: Icons.fitness_center_rounded,
                  label: "Activities",
                  isActive: selectTab == 1,
                  onTap: () {
                    selectTab = 1;
                    currentTab = const SelectView();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(width: 60), // Space for FAB
                TabButton(
                  icon: Icons.camera_alt_outlined,
                  selectedIcon: Icons.camera_alt_rounded,
                  label: "Progress",
                  isActive: selectTab == 2,
                  onTap: () {
                    selectTab = 2;
                    currentTab = const PhotoProgressView();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                TabButton(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: "Profile",
                  isActive: selectTab == 3,
                  onTap: () {
                    selectTab = 3;
                    currentTab = const ProfileView();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
