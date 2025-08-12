import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';

class AchievementsView extends StatefulWidget {
  const AchievementsView({super.key});

  @override
  State<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView>
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
          "Achievements",
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
          TabBar(
            controller: _tabController,
            indicatorColor: TColor.primaryColor1,
            labelColor: TColor.primaryColor1,
            unselectedLabelColor: TColor.gray,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: "Earned"),
              Tab(text: "Progress"),
              Tab(text: "All Badges"),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEarnedTab(),
                _buildProgressTab(),
                _buildAllBadgesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnedTab() {
    final earnedAchievements = _getEarnedAchievements();

    if (earnedAchievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: TColor.gray,
            ),
            const SizedBox(height: 20),
            Text(
              "No Achievements Yet",
              style: TextStyle(
                color: TColor.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Start your fitness journey to earn badges",
              style: TextStyle(
                color: TColor.gray,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: earnedAchievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(earnedAchievements[index], true);
      },
    );
  }

  Widget _buildProgressTab() {
    final progressAchievements = _getProgressAchievements();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: progressAchievements.length,
      itemBuilder: (context, index) {
        return _buildProgressCard(progressAchievements[index]);
      },
    );
  }

  Widget _buildAllBadgesTab() {
    final allAchievements = _getAllAchievements();

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: allAchievements.length,
      itemBuilder: (context, index) {
        return _buildBadgeCard(allAchievements[index]);
      },
    );
  }

  Widget _buildAchievementCard(
      Map<String, dynamic> achievement, bool isEarned) {
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
        border: isEarned
            ? Border.all(color: achievement['color'].withOpacity(0.3), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: achievement['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              achievement['icon'],
              color: achievement['color'],
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement['title'],
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isEarned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: achievement['color'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Earned",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  achievement['description'],
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
                if (achievement['reward'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Reward: ${achievement['reward']}",
                    style: TextStyle(
                      color: achievement['color'],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> achievement) {
    double progress = achievement['progress'] / achievement['target'];

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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: achievement['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  achievement['icon'],
                  color: achievement['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement['title'],
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      achievement['description'],
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(
                  color: achievement['color'],
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "${achievement['progress']} / ${achievement['target']} ${achievement['unit']}",
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: TColor.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(achievement['color']),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> achievement) {
    bool isEarned = achievement['isEarned'] ?? false;

    return Container(
      padding: const EdgeInsets.all(15),
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
        border: isEarned
            ? Border.all(color: achievement['color'].withOpacity(0.3), width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: achievement['color'].withOpacity(isEarned ? 0.2 : 0.05),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              achievement['icon'],
              color: isEarned ? achievement['color'] : TColor.gray,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            achievement['title'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEarned ? TColor.black : TColor.gray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            achievement['category'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 10,
            ),
          ),
          if (isEarned) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: achievement['color'],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Earned",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getEarnedAchievements() {
    // In a real app, this would come from user data
    return [
      {
        'title': 'First Step',
        'description': 'Completed your first workout',
        'icon': Icons.directions_walk,
        'color': Colors.green,
        'category': 'Milestone',
        'reward': '+10 XP',
        'isEarned': true,
      },
      {
        'title': 'Getting Started',
        'description': 'Logged your first meal',
        'icon': Icons.restaurant,
        'color': Colors.orange,
        'category': 'Nutrition',
        'reward': '+5 XP',
        'isEarned': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getProgressAchievements() {
    return [
      {
        'title': 'Workout Warrior',
        'description': 'Complete 10 workouts',
        'icon': Icons.fitness_center,
        'color': TColor.primaryColor1,
        'progress': 3,
        'target': 10,
        'unit': 'workouts',
      },
      {
        'title': 'Sleep Master',
        'description': 'Track sleep for 7 consecutive days',
        'icon': Icons.bedtime,
        'color': Colors.purple,
        'progress': 2,
        'target': 7,
        'unit': 'days',
      },
      {
        'title': 'Calorie Crusher',
        'description': 'Burn 1000 calories through workouts',
        'icon': Icons.local_fire_department,
        'color': Colors.red,
        'progress': 450,
        'target': 1000,
        'unit': 'calories',
      },
      {
        'title': 'Hydration Hero',
        'description': 'Drink target water for 5 days',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'progress': 1,
        'target': 5,
        'unit': 'days',
      },
    ];
  }

  List<Map<String, dynamic>> _getAllAchievements() {
    return [
      // Earned achievements
      ..._getEarnedAchievements(),

      // Workout achievements
      {
        'title': 'Workout Warrior',
        'description': 'Complete 10 workouts',
        'icon': Icons.fitness_center,
        'color': TColor.primaryColor1,
        'category': 'Workout',
        'isEarned': false,
      },
      {
        'title': 'Consistency King',
        'description': 'Workout 5 days in a row',
        'icon': Icons.repeat,
        'color': Colors.green,
        'category': 'Workout',
        'isEarned': false,
      },
      {
        'title': 'Marathon Master',
        'description': 'Complete 50 workouts',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'category': 'Workout',
        'isEarned': false,
      },

      // Nutrition achievements
      {
        'title': 'Meal Tracker',
        'description': 'Log 20 meals',
        'icon': Icons.restaurant_menu,
        'color': Colors.orange,
        'category': 'Nutrition',
        'isEarned': false,
      },
      {
        'title': 'Nutrition Ninja',
        'description': 'Track nutrition for 7 days',
        'icon': Icons.local_dining,
        'color': Colors.deepOrange,
        'category': 'Nutrition',
        'isEarned': false,
      },

      // Sleep achievements
      {
        'title': 'Sleep Master',
        'description': 'Track sleep for 7 days',
        'icon': Icons.bedtime,
        'color': Colors.purple,
        'category': 'Sleep',
        'isEarned': false,
      },
      {
        'title': 'Dream Walker',
        'description': 'Get 8+ hours sleep 5 times',
        'icon': Icons.nights_stay,
        'color': Colors.indigo,
        'category': 'Sleep',
        'isEarned': false,
      },

      // Water achievements
      {
        'title': 'Hydration Hero',
        'description': 'Meet water goal 5 days',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'category': 'Hydration',
        'isEarned': false,
      },
      {
        'title': 'Ocean Master',
        'description': 'Drink 50L total water',
        'icon': Icons.waves,
        'color': Colors.cyan,
        'category': 'Hydration',
        'isEarned': false,
      },

      // Body composition achievements
      {
        'title': 'Body Tracker',
        'description': 'Log 10 body measurements',
        'icon': Icons.monitor_weight,
        'color': Colors.teal,
        'category': 'Body',
        'isEarned': false,
      },
      {
        'title': 'Progress Pioneer',
        'description': 'Track progress for 30 days',
        'icon': Icons.trending_up,
        'color': Colors.green,
        'category': 'Body',
        'isEarned': false,
      },

      // Special achievements
      {
        'title': 'All-Rounder',
        'description': 'Use all app features',
        'icon': Icons.star,
        'color': Colors.amber,
        'category': 'Special',
        'isEarned': false,
      },
      {
        'title': 'Fitness Legend',
        'description': 'Reach 1000 total XP',
        'icon': Icons.military_tech,
        'color': Colors.deepPurple,
        'category': 'Special',
        'isEarned': false,
      },
    ];
  }
}
