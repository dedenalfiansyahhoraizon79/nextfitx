import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../services/user_service.dart';
import '../../services/body_composition_service.dart';
import '../../models/body_composition_model.dart';

class PersonalDataView extends StatefulWidget {
  const PersonalDataView({super.key});

  @override
  State<PersonalDataView> createState() => _PersonalDataViewState();
}

class _PersonalDataViewState extends State<PersonalDataView> {
  final UserService _userService = UserService();
  final BodyCompositionService _bodyCompositionService =
      BodyCompositionService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _dateOfBirthController;

  // State variables
  String _selectedGender = 'Male';
  String _selectedGoal = 'Lose Weight';
  DateTime? _selectedDate;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  // Constants
  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];
  static const List<String> _goalOptions = [
    'Lose Weight',
    'Gain Weight',
    'Build Muscle',
    'Maintain Weight',
    'Improve Fitness'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _dateOfBirthController = TextEditingController();

    // Add listeners only for editable fields
    _firstNameController.addListener(_onDataChanged);
    _lastNameController.addListener(_onDataChanged);
    // Note: height and weight are read-only, so no listeners needed
  }

  void _onDataChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _dateOfBirthController.dispose();

    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _emailController.text = user.email ?? '';

      final userData = await _userService.getUserProfile();
      if (userData != null && mounted) {
        _populateFormFields(userData);
        _profileImageUrl = userData['profileImageUrl'];
      }

      // Load latest body composition data for weight, height, and age
      try {
        final latestBodyComposition =
            await _bodyCompositionService.getBodyCompositionRecords(limit: 1);
        if (latestBodyComposition.isNotEmpty && mounted) {
          final latestRecord = latestBodyComposition.first;
          _populateBodyCompositionData(latestRecord);
        }
      } catch (e) {
        debugPrint('Failed to load body composition data: $e');
        // Continue without body composition data
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load user data: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  void _populateFormFields(Map<String, dynamic> userData) {
    _firstNameController.text = userData['firstName']?.toString() ?? '';
    _lastNameController.text = userData['lastName']?.toString() ?? '';
    // Don't populate height and weight from user data - will use body composition data instead

    final gender = userData['gender']?.toString();
    _selectedGender =
        _genderOptions.contains(gender) ? gender! : _genderOptions.first;

    final goal = userData['goal']?.toString();
    _selectedGoal = _goalOptions.contains(goal) ? goal! : _goalOptions.first;

    if (userData['dateOfBirth'] != null) {
      try {
        _selectedDate = userData['dateOfBirth'].toDate();
        _dateOfBirthController.text =
            DateFormat('dd/MM/yyyy').format(_selectedDate!);
      } catch (e) {
        debugPrint('Error parsing date of birth: $e');
      }
    }
  }

  void _populateBodyCompositionData(BodyCompositionModel bodyComposition) {
    // Populate weight and height from body composition data
    _weightController.text =
        bodyComposition.bodyParameters.weight.toStringAsFixed(1);
    _heightController.text =
        bodyComposition.bodyParameters.height.toStringAsFixed(1);

    // Calculate age from physical age if available, otherwise use date of birth
    if (bodyComposition.bodyParameters.physicalAge > 0) {
      // If we have physical age from body composition, use it to calculate birth date
      final now = DateTime.now();
      final calculatedBirthYear =
          now.year - bodyComposition.bodyParameters.physicalAge;
      _selectedDate = DateTime(calculatedBirthYear, now.month, now.day);
      _dateOfBirthController.text =
          DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDate ?? now.subtract(const Duration(days: 365 * 25));
    final firstDate = DateTime(now.year - 100);
    final lastDate = now.subtract(const Duration(days: 365 * 13));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateOfBirthController.text =
            DateFormat('dd/MM/yyyy').format(pickedDate);
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fix the errors in the form');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.updateUserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: _selectedDate,
        goal: _selectedGoal,
      );

      if (mounted) {
        _showSuccessSnackBar('Personal data updated successfully!');
        setState(() {
          _hasUnsavedChanges = false;
        });
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save data: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadProfileImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadProfileImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Upload to Firebase Storage
        final file = File(pickedFile.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${user.uid}.jpg');

        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImageUrl': downloadUrl});

        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploadingImage = false;
        });

        _showSuccessSnackBar('Profile photo updated successfully!');
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      _showErrorSnackBar('Failed to upload image: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "Personal Data",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      backgroundColor: TColor.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Image Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: TColor.lightGray,
                                border: Border.all(
                                  color: TColor.primaryColor1,
                                  width: 3,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: _isUploadingImage
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  TColor.primaryColor1),
                                        ),
                                      )
                                    : _profileImageUrl != null
                                        ? Image.network(
                                            _profileImageUrl!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.person,
                                                size: 60,
                                                color: TColor.gray,
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 60,
                                            color: TColor.gray,
                                          ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: TColor.primaryColor1,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // First Name
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        validator: (value) =>
                            _validateRequired(value, 'First Name'),
                      ),
                      const SizedBox(height: 15),

                      // Last Name
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        validator: (value) =>
                            _validateRequired(value, 'Last Name'),
                      ),
                      const SizedBox(height: 15),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Date of Birth
                      GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dateOfBirthController,
                            decoration: InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            validator: (value) =>
                                _validateRequired(value, 'Date of Birth'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Age can be calculated from your latest body composition record',
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Gender
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        items: _genderOptions.map((String option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedGender = value!),
                      ),
                      const SizedBox(height: 15),

                      // Height
                      TextFormField(
                        controller: _heightController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          suffixIcon:
                              Icon(Icons.info_outline, color: TColor.gray),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Height is taken from your latest body composition record',
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Weight
                      TextFormField(
                        controller: _weightController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          suffixIcon:
                              Icon(Icons.info_outline, color: TColor.gray),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Weight is taken from your latest body composition record',
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Goal
                      DropdownButtonFormField<String>(
                        value: _selectedGoal,
                        decoration: InputDecoration(
                          labelText: 'Fitness Goal',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        items: _goalOptions.map((String option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedGoal = value!),
                      ),
                      const SizedBox(height: 40),

                      // Save Button
                      RoundButton(
                        title: _isSaving ? "Saving..." : "Save Changes",
                        onPressed: () {
                          if (!_isSaving) {
                            _saveUserData();
                          }
                        },
                      ),

                      if (_hasUnsavedChanges)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'You have unsaved changes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: TColor.secondaryColor1,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
