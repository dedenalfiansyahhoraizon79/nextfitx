import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user document reference
  DocumentReference get userDocument {
    if (currentUserId == null) {
      throw Exception('No authenticated user found');
    }
    return _firestore.collection('users').doc(currentUserId);
  }

  // Create or update user profile
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    String? goal,
    // Soft Lean Mass
    double? softLeanMassRightUpper,
    double? softLeanMassRightLower,
    double? softLeanMassLeftUpper,
    double? softLeanMassLeftLower,
    // Body Fat Mass
    double? bodyFatMassRightUpper,
    double? bodyFatMassRightLower,
    double? bodyFatMassLeftUpper,
    double? bodyFatMassLeftLower,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      final data = {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        if (weight != null) 'weight': weight,
        if (height != null) 'height': height,
        if (goal != null) 'goal': goal,
        // Soft Lean Mass
        if (softLeanMassRightUpper != null)
          'softLeanMassRightUpper': softLeanMassRightUpper,
        if (softLeanMassRightLower != null)
          'softLeanMassRightLower': softLeanMassRightLower,
        if (softLeanMassLeftUpper != null)
          'softLeanMassLeftUpper': softLeanMassLeftUpper,
        if (softLeanMassLeftLower != null)
          'softLeanMassLeftLower': softLeanMassLeftLower,
        // Body Fat Mass
        if (bodyFatMassRightUpper != null)
          'bodyFatMassRightUpper': bodyFatMassRightUpper,
        if (bodyFatMassRightLower != null)
          'bodyFatMassRightLower': bodyFatMassRightLower,
        if (bodyFatMassLeftUpper != null)
          'bodyFatMassLeftUpper': bodyFatMassLeftUpper,
        if (bodyFatMassLeftLower != null)
          'bodyFatMassLeftLower': bodyFatMassLeftLower,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await userDocument.set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      final doc = await userDocument.get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Check if profile is complete
  Future<bool> isProfileComplete() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return false;

      final requiredFields = [
        'firstName',
        'lastName',
        'gender',
        'dateOfBirth',
        'weight',
        'height',
        'goal'
      ];

      return requiredFields.every((field) => profile[field] != null);
    } catch (e) {
      return false;
    }
  }

  // Add workout record
  Future<void> addWorkout(Map<String, dynamic> workoutData) async {
    try {
      await userDocument.collection('workouts').add({
        ...workoutData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add workout: $e');
    }
  }

  // Add activity record
  Future<void> addActivity(Map<String, dynamic> activityData) async {
    try {
      await userDocument.collection('activities').add({
        ...activityData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add activity: $e');
    }
  }

  // Get user's workouts
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    try {
      final snapshot = await userDocument
          .collection('workouts')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Failed to get workouts: $e');
    }
  }

  // Get user's activities
  Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final snapshot = await userDocument
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Failed to get activities: $e');
    }
  }
}
