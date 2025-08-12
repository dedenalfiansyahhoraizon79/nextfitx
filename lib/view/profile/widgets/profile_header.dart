import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../common/colo_extension.dart';
import '../../../common_widget/title_subtitle_cell.dart';
import '../../../services/body_composition_service.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  User? user;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? profileImageUrl;
  final BodyCompositionService _bodyCompositionService = BodyCompositionService();
  
  // Body composition data
  double? _latestWeight;
  double? _latestHeight;
  int? _physicalAge;

  String calculateAge(dynamic birthDate) {
    if (birthDate == null) return 'N/A';

    final DateTime birthDateTime = _safeDateTime(birthDate);
    final DateTime now = DateTime.now();

    int age = now.year - birthDateTime.year;
    if (now.month < birthDateTime.month ||
        (now.month == birthDateTime.month && now.day < birthDateTime.day)) {
      age--;
    }

    return age.toString();
  }

  // Safe DateTime parsing helper
  DateTime _safeDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      // If it's a Timestamp (from Firestore)
      if (value.runtimeType.toString() == 'Timestamp') {
        return value.toDate();
      }

      // If it's already a DateTime
      if (value is DateTime) {
        return value;
      }

      // If it's a String, try to parse it
      if (value is String) {
        return DateTime.parse(value);
      }

      // If it's an int (milliseconds since epoch)
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      return DateTime.now();
    } catch (e) {
      print('Error parsing DateTime in ProfileHeader: $e');
      return DateTime.now();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      setState(() {
        userData = doc.data();
        profileImageUrl = userData?['profileImageUrl'];
      });

      // Load latest body composition data
      try {
        final latestBodyComposition = await _bodyCompositionService.getBodyCompositionRecords(limit: 1);
        if (latestBodyComposition.isNotEmpty && mounted) {
          final latestRecord = latestBodyComposition.first;
          setState(() {
            _latestWeight = latestRecord.bodyParameters.weight;
            _latestHeight = latestRecord.bodyParameters.height;
            _physicalAge = latestRecord.bodyParameters.physicalAge;
          });
        }
      } catch (e) {
        print('Failed to load body composition data: $e');
        // Continue without body composition data
      }

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && user != null) {
      final file = pickedFile.path;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user!.uid}.jpg');
      await storageRef.putFile(File(file));
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'profileImageUrl': downloadUrl,
      });

      setState(() {
        profileImageUrl = downloadUrl;
      });
    }
  }

  Future<void> _updateUserProfile(String field, String value) async {
    if (user != null) {
      Map<String, dynamic> updateData = {};

      // Only handle firstName and goal fields
      if (field == 'firstName') {
        updateData['firstName'] = value;
      } else if (field == 'goal') {
        updateData['goal'] = value;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update(updateData);

      _loadUserData(); // Reload data to reflect changes
    }
  }

  void _showEditDialog(String field, String currentValue) {
    TextEditingController controller =
        TextEditingController(text: currentValue);

    String getTitle() {
      switch (field) {
        case 'firstName':
          return 'First Name';
        case 'goal':
          return 'Fitness Goal';
        default:
          return field;
      }
    }

    String getHint() {
      switch (field) {
        case 'firstName':
          return 'Enter first name';
        case 'goal':
          return 'Enter your fitness goal';
        default:
          return 'Enter $field';
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${getTitle()}'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: getTitle(),
              hintText: getHint(),
            ),
            keyboardType: (field == 'height' || field == 'weight')
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateUserProfile(field, controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final firstName = userData?['firstName'] ?? 'User';

    // Format height and weight with one decimal place
    final height = _latestHeight?.toStringAsFixed(1) ?? 'N/A';
    final weight = _latestWeight?.toStringAsFixed(1) ?? 'N/A';
    final age = _physicalAge?.toString() ?? 'N/A';

    return Column(
      children: [
        // nextfitX Logo Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/img/logofix.png",
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: TColor.primaryColor1,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      child: Text(
                        'N',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TColor.primaryColor1,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TColor.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: profileImageUrl != null
                        ? Image.network(
                            profileImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "assets/img/u2.png",
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 60,
                                height: 60,
                                color: TColor.lightGray,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          TColor.primaryColor1),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            "assets/img/u2.png",
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: TColor.primaryColor1,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _showEditDialog('firstName', firstName),
                    child: Text(
                      firstName,
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showEditDialog(
                        'goal', userData?['goal'] ?? 'No Goal Set'),
                    child: Text(
                      userData?['goal'] ?? 'Tap to set goal',
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 13,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 15,
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Show a message that height comes from body composition
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Height is taken from your latest body composition record'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: TitleSubtitleCell(
                  title: "$height cm",
                  subtitle: "Height",
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Show a message that weight comes from body composition
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Weight is taken from your latest body composition record'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: TitleSubtitleCell(
                  title: "$weight kg",
                  subtitle: "Weight",
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Show a message that age comes from body composition
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Age is calculated from your latest body composition record'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: TitleSubtitleCell(
                  title: age,
                  subtitle: "Age",
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
