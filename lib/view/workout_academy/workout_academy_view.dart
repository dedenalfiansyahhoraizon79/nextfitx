import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../models/workout_academy_model.dart';
import '../../services/workout_academy_service.dart';
import 'workout_category_view.dart';
import 'workout_tutorial_detail_view.dart';

class WorkoutAcademyView extends StatefulWidget {
  const WorkoutAcademyView({super.key});

  @override
  State<WorkoutAcademyView> createState() => _WorkoutAcademyViewState();
}

class _WorkoutAcademyViewState extends State<WorkoutAcademyView> {
  final WorkoutAcademyService _academyService = WorkoutAcademyService();

  bool _isLoading = true;
  List<WorkoutTutorialModel> _featuredTutorials = [];
  List<WorkoutTutorialModel> _popularTutorials = [];
  List<WorkoutTutorialModel> _noEquipmentTutorials = [];
  WorkoutAcademyStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadAcademyData();
  }

  Future<void> _loadAcademyData() async {
    try {
      setState(() => _isLoading = true);

      // Load featured tutorials
      _featuredTutorials = await _academyService.getFeaturedTutorials(limit: 5);

      // Load popular tutorials
      _popularTutorials = await _academyService.getPopularTutorials(limit: 5);

      // Load no-equipment tutorials
      _noEquipmentTutorials =
          await _academyService.getNoEquipmentTutorials(limit: 5);

      // Load academy stats
      _stats = await _academyService.getAcademyStats();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading academy data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          "Workout Academy",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Generate Sample Data Button
          InkWell(
            onTap: () async {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              TColor.primaryColor1),
                        ),
                        const SizedBox(width: 20),
                        const Text(
                            "Generating comprehensive workout videos..."),
                      ],
                    ),
                  ),
                );

                await _academyService.generateSampleAcademyData();
                Navigator.pop(context); // Close loading dialog

                // Refresh data
                await _loadAcademyData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '✅ Generated 18 comprehensive workout tutorials with real YouTube videos! All videos can be played on Android.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error generating sample data: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.add_box,
                color: Colors.green,
                size: 20,
              ),
            ),
          ),
          // Search Button
          InkWell(
            onTap: () {
              _showSearchDialog();
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.search,
                color: TColor.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Hero Section
                  _buildHeroSection(),

                  const SizedBox(height: 25),

                  // Quick Stats
                  _buildQuickStats(),

                  const SizedBox(height: 25),

                  // Category Grid
                  _buildCategoriesSection(),

                  const SizedBox(height: 25),

                  // Featured Tutorials
                  _buildFeaturedSection(),

                  const SizedBox(height: 25),

                  // Popular Tutorials
                  _buildPopularSection(),

                  const SizedBox(height: 25),

                  // No Equipment Section
                  _buildNoEquipmentSection(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: TColor.primaryG,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TColor.primaryG.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🎯 Master Your Workouts",
                      style: TextStyle(
                        color: TColor.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Professional video tutorials with step-by-step guidance from expert trainers",
                      style: TextStyle(
                        color: TColor.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () => _generateSampleData(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          "🚀 Start Learning",
                          style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.play_circle_filled,
                  size: 50,
                  color: TColor.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "📚 Tutorials",
              "${_stats!.totalTutorials}",
              "Available",
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              "⭐ Rating",
              _stats!.averageRating.toStringAsFixed(1),
              "Average",
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              "👁️ Views",
              "${_stats!.totalViewCount}",
              "Total",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Workout Categories",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all categories
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: WorkoutCategory.values.length,
            itemBuilder: (context, index) {
              final category = WorkoutCategory.values[index];
              return _buildCategoryCard(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(WorkoutCategory category) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutCategoryView(category: category),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                category.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "⭐ Featured Tutorials",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to featured tutorials
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _featuredTutorials.length,
            itemBuilder: (context, index) {
              final tutorial = _featuredTutorials[index];
              return _buildTutorialCard(tutorial);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "🔥 Popular This Week",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to popular tutorials
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _popularTutorials.length,
            itemBuilder: (context, index) {
              final tutorial = _popularTutorials[index];
              return _buildTutorialCard(tutorial);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "🏠 No Equipment Needed",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to no equipment tutorials
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _noEquipmentTutorials.length,
            itemBuilder: (context, index) {
              final tutorial = _noEquipmentTutorials[index];
              return _buildTutorialCard(tutorial);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialCard(WorkoutTutorialModel tutorial) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WorkoutTutorialDetailView(tutorial: tutorial),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
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
              // Thumbnail
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(tutorial.youtubeThumbnail),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Play overlay
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    // Duration badge
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tutorial.durationFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Difficulty badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(tutorial.difficulty),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tutorial.difficulty.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorial.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: TColor.gray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tutorial.instructor,
                            style: TextStyle(
                              color: TColor.gray,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (tutorial.rating > 0) ...[
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            tutorial.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: TColor.gray,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Search Tutorials"),
        content: TextField(
          decoration: const InputDecoration(
            hintText: "Enter exercise, muscle group, or instructor...",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    // TODO: Navigate to search results page
    print("Searching for: $query");
  }

  Future<void> _generateSampleData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating sample data..."),
            ],
          ),
        ),
      );

      await _academyService.generateSampleAcademyData();

      if (mounted) {
        Navigator.pop(context);
        _loadAcademyData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sample workout tutorials generated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generating data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
