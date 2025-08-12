import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../common/colo_extension.dart';
import '../../models/workout_academy_model.dart';
import '../../services/workout_academy_service.dart';

class WorkoutTutorialDetailView extends StatefulWidget {
  final WorkoutTutorialModel tutorial;

  const WorkoutTutorialDetailView({
    super.key,
    required this.tutorial,
  });

  @override
  State<WorkoutTutorialDetailView> createState() =>
      _WorkoutTutorialDetailViewState();
}

class _WorkoutTutorialDetailViewState extends State<WorkoutTutorialDetailView>
    with SingleTickerProviderStateMixin {
  final WorkoutAcademyService _academyService = WorkoutAcademyService();
  late TabController _tabController;
  late YoutubePlayerController _youtubeController;

  bool _isPlayerReady = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize YouTube player
    _initializeYouTubePlayer();

    // Increment view count when user opens tutorial
    _incrementViewCount();
  }

  void _initializeYouTubePlayer() {
    _youtubeController = YoutubePlayerController(
      initialVideoId: widget.tutorial.youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        captionLanguage: 'en',
        showLiveFullscreenButton: true,
        forceHD: false,
        startAt: 0,
      ),
    );

    _youtubeController.addListener(() {
      if (_youtubeController.value.isReady && !_isPlayerReady) {
        setState(() {
          _isPlayerReady = true;
        });
      }

      if (_youtubeController.value.isFullScreen != _isFullScreen) {
        setState(() {
          _isFullScreen = _youtubeController.value.isFullScreen;
        });
      }
    });
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _incrementViewCount() async {
    try {
      if (widget.tutorial.id != null) {
        await _academyService.incrementViewCount(widget.tutorial.id!);
      }
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // Make sure to exit full screen when back button is pressed
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _youtubeController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: TColor.primaryColor1,
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              widget.tutorial.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 25.0,
            ),
            onPressed: () {
              // Settings can be added here
            },
          ),
        ],
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
        onEnded: (data) {
          // Auto show completion dialog or next video suggestions
          _showVideoCompletionDialog();
        },
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: TColor.white,
        body: Column(
          children: [
            // YouTube Player
            player,

            // Content below video
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and basic info
                    _buildTitleSection(),

                    // Tab bar
                    _buildTabBar(),

                    // Tab content
                    SizedBox(
                      height: 500, // Fixed height for tab content
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildInstructionsTab(),
                          _buildTipsTab(),
                          _buildDetailsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video control buttons
          Row(
            children: [
              // Play/Pause button
              Container(
                decoration: BoxDecoration(
                  color: TColor.primaryColor1,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () {
                    if (_youtubeController.value.isPlaying) {
                      _youtubeController.pause();
                    } else {
                      _youtubeController.play();
                    }
                  },
                  icon: Icon(
                    _youtubeController.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // Replay button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () {
                    _youtubeController.seekTo(Duration.zero);
                    _youtubeController.play();
                  },
                  icon: Icon(
                    Icons.replay,
                    color: TColor.black,
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // Speed control
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<double>(
                  value: _youtubeController.value.playbackRate,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                    DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                    DropdownMenuItem(value: 1.0, child: Text('1x')),
                    DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                    DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                    DropdownMenuItem(value: 2.0, child: Text('2x')),
                  ],
                  onChanged: (speed) {
                    if (speed != null) {
                      _youtubeController.setPlaybackRate(speed);
                    }
                  },
                ),
              ),

              const Spacer(),

              // Full screen button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () {
                    _youtubeController.toggleFullScreenMode();
                  },
                  icon: Icon(
                    Icons.fullscreen,
                    color: TColor.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            widget.tutorial.title,
            style: TextStyle(
              color: TColor.black,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),

          // Instructor and rating
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: TColor.lightGray,
                child: Icon(
                  Icons.person,
                  color: TColor.gray,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tutorial.instructor,
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < widget.tutorial.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.orange,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          "${widget.tutorial.rating.toStringAsFixed(1)} (${widget.tutorial.viewCount} views)",
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Quick stats
          Row(
            children: [
              _buildQuickStat(
                Icons.timer,
                widget.tutorial.durationFormatted,
                "Duration",
              ),
              const SizedBox(width: 20),
              _buildQuickStat(
                Icons.local_fire_department,
                "${widget.tutorial.estimatedCalories.toInt()} kcal",
                "Calories",
              ),
              const SizedBox(width: 20),
              _buildQuickStat(
                Icons.fitness_center,
                widget.tutorial.difficulty.displayName,
                "Level",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: TColor.primaryColor1, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: TColor.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: TColor.lightGray,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: TColor.primaryColor1,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: TColor.gray,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: "Overview"),
          Tab(text: "Instructions"),
          Tab(text: "Tips"),
          Tab(text: "Details"),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Description",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.tutorial.description,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          Text(
            "Target Muscles",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tutorial.muscleGroups
                .map((muscle) => _buildMuscleChip(muscle))
                .toList(),
          ),
          const SizedBox(height: 25),
          Text(
            "Equipment Needed",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          widget.tutorial.equipmentRequired.isEmpty
              ? Text(
                  "No equipment needed - bodyweight only! 💪",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.tutorial.equipmentRequired
                      .map((equipment) => _buildEquipmentChip(equipment))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildInstructionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Step-by-Step Instructions",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.tutorial.instructions.map((instruction) {
            return _buildInstructionStep(instruction);
          }),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pro Tips
          Text(
            "💡 Pro Tips",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),

          ...widget.tutorial.tips.map((tip) {
            return _buildTipItem(tip, Colors.green, Icons.lightbulb);
          }),

          const SizedBox(height: 30),

          // Common Mistakes
          Text(
            "⚠️ Common Mistakes",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),

          ...widget.tutorial.commonMistakes.map((mistake) {
            return _buildTipItem(mistake, Colors.red, Icons.warning);
          }),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("Category", widget.tutorial.category.displayName),
          _buildDetailRow("Difficulty", widget.tutorial.difficulty.displayName),
          _buildDetailRow("Duration", widget.tutorial.durationFormatted),
          _buildDetailRow("Estimated Calories",
              "${widget.tutorial.estimatedCalories.toInt()} kcal"),
          _buildDetailRow("Total Views", "${widget.tutorial.viewCount}"),
          _buildDetailRow(
              "Rating", "${widget.tutorial.rating.toStringAsFixed(1)}/5.0"),
          _buildDetailRow("Instructor", widget.tutorial.instructor),
          const SizedBox(height: 20),
          Text(
            "Tags",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.tutorial.tags.map((tag) => _buildTagChip(tag)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleChip(String muscle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TColor.primaryColor1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: TColor.primaryColor1.withOpacity(0.3)),
      ),
      child: Text(
        muscle,
        style: TextStyle(
          color: TColor.primaryColor1,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEquipmentChip(String equipment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Text(
        equipment,
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInstructionStep(WorkoutInstruction instruction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: TColor.primaryColor1,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                "${instruction.step}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        instruction.title,
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (instruction.stepInfo.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TColor.lightGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          instruction.stepInfo,
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  instruction.description,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: TColor.black,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: TColor.gray,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: TColor.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TColor.lightGray,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        "#$tag",
        style: TextStyle(
          color: TColor.gray,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_youtubeController.value.isPlaying) {
                  _youtubeController.pause();
                } else {
                  _youtubeController.play();
                }
              },
              icon: Icon(
                _youtubeController.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
              ),
              label: Text(
                _youtubeController.value.isPlaying
                    ? "Pause Video"
                    : "Play Video",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton(
            onPressed: () {
              // TODO: Add to workout plan
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Added "${widget.tutorial.title}" to your workout plan!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.primaryColor1,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _showVideoCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            const SizedBox(width: 10),
            const Text("Video Completed!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Great job completing the tutorial!"),
            const SizedBox(height: 15),
            Text(
              "You burned approximately ${widget.tutorial.estimatedCalories.toInt()} calories! 🔥",
              style: TextStyle(
                color: TColor.primaryColor1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Continue Reading"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _youtubeController.seekTo(Duration.zero);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.primaryColor1,
              foregroundColor: Colors.white,
            ),
            child: const Text("Watch Again"),
          ),
        ],
      ),
    );
  }
}
