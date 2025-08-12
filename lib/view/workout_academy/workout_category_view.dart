import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../models/workout_academy_model.dart';
import '../../services/workout_academy_service.dart';
import 'workout_tutorial_detail_view.dart';

class WorkoutCategoryView extends StatefulWidget {
  final WorkoutCategory category;
  
  const WorkoutCategoryView({
    super.key,
    required this.category,
  });

  @override
  State<WorkoutCategoryView> createState() => _WorkoutCategoryViewState();
}

class _WorkoutCategoryViewState extends State<WorkoutCategoryView> {
  final WorkoutAcademyService _academyService = WorkoutAcademyService();
  
  bool _isLoading = true;
  List<WorkoutTutorialModel> _tutorials = [];
  List<WorkoutTutorialModel> _filteredTutorials = [];
  
  DifficultyLevel? _selectedDifficulty;
  String _sortBy = 'rating'; // rating, duration, popularity
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadTutorials();
  }

  Future<void> _loadTutorials() async {
    try {
      setState(() => _isLoading = true);

      _tutorials = await _academyService.getTutorialsByCategory(widget.category);
      _applyFiltersAndSort();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading tutorials: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFiltersAndSort() {
    _filteredTutorials = List.from(_tutorials);

    // Apply difficulty filter
    if (_selectedDifficulty != null) {
      _filteredTutorials = _filteredTutorials
          .where((tutorial) => tutorial.difficulty == _selectedDifficulty)
          .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'rating':
        _filteredTutorials.sort((a, b) => _sortAscending
            ? a.rating.compareTo(b.rating)
            : b.rating.compareTo(a.rating));
        break;
      case 'duration':
        _filteredTutorials.sort((a, b) => _sortAscending
            ? a.durationMinutes.compareTo(b.durationMinutes)
            : b.durationMinutes.compareTo(a.durationMinutes));
        break;
      case 'popularity':
        _filteredTutorials.sort((a, b) => _sortAscending
            ? a.viewCount.compareTo(b.viewCount)
            : b.viewCount.compareTo(a.viewCount));
        break;
    }

    setState(() {});
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.category.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              widget.category.displayName,
              style: TextStyle(
                color: TColor.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () => _showFilterBottomSheet(),
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
                Icons.filter_list,
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
          : Column(
              children: [
                // Category description and stats
                _buildCategoryHeader(),
                
                // Filter and sort bar
                _buildFilterSortBar(),
                
                // Tutorials grid
                Expanded(
                  child: _filteredTutorials.isEmpty
                      ? _buildEmptyState()
                      : _buildTutorialsGrid(),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
          Text(
            widget.category.description,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildStatBadge(
                Icons.video_library,
                "${_tutorials.length} Videos",
              ),
              const SizedBox(width: 15),
              _buildStatBadge(
                Icons.timer,
                "${_getTotalDuration()} min total",
              ),
              const SizedBox(width: 15),
              _buildStatBadge(
                Icons.local_fire_department,
                "${_getTotalCalories().toInt()} kcal",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TColor.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TColor.gray),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Active filters count
          if (_selectedDifficulty != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TColor.primaryColor1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedDifficulty!.displayName,
                    style: TextStyle(
                      color: TColor.primaryColor1,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDifficulty = null);
                      _applyFiltersAndSort();
                    },
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: TColor.primaryColor1,
                    ),
                  ),
                ],
              ),
            ),
          
          const Spacer(),
          
          // Results count
          Text(
            "${_filteredTutorials.length} results",
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 2.5,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: _filteredTutorials.length,
      itemBuilder: (context, index) {
        final tutorial = _filteredTutorials[index];
        return _buildTutorialListCard(tutorial);
      },
    );
  }

  Widget _buildTutorialListCard(WorkoutTutorialModel tutorial) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutTutorialDetailView(tutorial: tutorial),
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
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 120,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Duration badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tutorial.durationFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
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
                    // Instructor and rating
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
                    const Spacer(),
                    // Tags and difficulty
                    Row(
                      children: [
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(tutorial.difficulty),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tutorial.difficulty.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Equipment
                        Expanded(
                          child: Text(
                            tutorial.equipmentSummary,
                            style: TextStyle(
                              color: TColor.gray,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "🔍",
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 20),
          Text(
            "No tutorials found",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your filters or check back later",
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedDifficulty = null;
                _sortBy = 'rating';
                _sortAscending = false;
              });
              _applyFiltersAndSort();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.primaryColor1,
              foregroundColor: Colors.white,
            ),
            child: const Text("Clear Filters"),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filter & Sort",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedDifficulty = null;
                        _sortBy = 'rating';
                        _sortAscending = false;
                      });
                    },
                    child: const Text("Reset"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Difficulty filter
              Text(
                "Difficulty Level",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  _buildFilterChip(
                    "All",
                    _selectedDifficulty == null,
                    () => setModalState(() => _selectedDifficulty = null),
                  ),
                  ...DifficultyLevel.values.map(
                    (difficulty) => _buildFilterChip(
                      difficulty.displayName,
                      _selectedDifficulty == difficulty,
                      () => setModalState(() => _selectedDifficulty = difficulty),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 25),
              
              // Sort options
              Text(
                "Sort By",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  _buildSortOption(
                    "Rating",
                    "rating",
                    Icons.star,
                    setModalState,
                  ),
                  _buildSortOption(
                    "Duration",
                    "duration",
                    Icons.timer,
                    setModalState,
                  ),
                  _buildSortOption(
                    "Popularity",
                    "popularity",
                    Icons.trending_up,
                    setModalState,
                  ),
                ],
              ),
              
              const SizedBox(height: 25),
              
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFiltersAndSort();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primaryColor1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Apply Filters",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TColor.primaryColor1 : TColor.lightGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : TColor.gray,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    String label,
    String value,
    IconData icon,
    StateSetter setModalState,
  ) {
    final isSelected = _sortBy == value;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? TColor.primaryColor1 : TColor.gray,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? TColor.primaryColor1 : TColor.black,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? GestureDetector(
              onTap: () => setModalState(() => _sortAscending = !_sortAscending),
              child: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: TColor.primaryColor1,
              ),
            )
          : null,
      onTap: () => setModalState(() => _sortBy = value),
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

  int _getTotalDuration() {
    return _tutorials.fold(0, (sum, tutorial) => sum + tutorial.durationMinutes);
  }

  double _getTotalCalories() {
    return _tutorials.fold(0.0, (sum, tutorial) => sum + tutorial.estimatedCalories);
  }
} 
