import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fl_chart/fl_chart.dart';

class PhotoService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;

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
      print('Error parsing DateTime in PhotoService: $e');
      return DateTime.now();
    }
  }

  Future<void> verifyConnection() async {
    try {
      // Verify Auth
      final user = _auth.currentUser;
      print('Firebase Auth Status:');
      print('- User logged in: ${user != null}');
      print('- User ID: ${user?.uid}');
      print('- User email: ${user?.email}');

      // Verify Firestore
      print('\nFirestore Status:');
      try {
        await _firestore.collection('test').doc('test').get();
        print('- Firestore connection successful');
      } catch (e) {
        print('- Firestore connection failed: $e');
      }

      // Verify Storage
      print('\nStorage Status:');
      try {
        await _storage.ref().child('test').listAll();
        print('- Storage connection successful');
      } catch (e) {
        print('- Storage connection failed: $e');
      }
    } catch (e) {
      print('Error verifying Firebase connection: $e');
    }
  }

  Future<String> uploadProgressPhoto(File photo, String photoType) async {
    try {
      print('Starting photo upload process for type: $photoType');

      // Compress image before upload
      final compressedImage = await FlutterImageCompress.compressWithFile(
        photo.path,
        minWidth: 1024,
        minHeight: 1024,
        quality: 85,
      );

      if (compressedImage == null) {
        throw Exception('Failed to compress image');
      }

      print('Image compressed successfully');

      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$photoType.jpg';
      final ref =
          _storage.ref().child('users/$userId/progress_photos/$fileName');
      print('Uploading to path: users/$userId/progress_photos/$fileName');

      // Upload to Firebase Storage
      final uploadTask = ref.putData(compressedImage);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      print('File uploaded successfully. URL: $url');

      // Save metadata to Firestore
      final docRef = await _firestore.collection('progress_photos').add({
        'userId': userId,
        'photoType': photoType,
        'url': url,
        'uploadedAt': FieldValue.serverTimestamp(),
        'fileName': fileName,
        'storagePath': 'users/$userId/progress_photos/$fileName',
      });
      print('Metadata saved to Firestore. Document ID: ${docRef.id}');

      return url;
    } catch (e) {
      print('Error uploading photo: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProgressPhotos(
      [String? photoType]) async {
    try {
      final userId = _auth.currentUser?.uid;
      print('Current auth state - User ID: $userId');
      print(
          'Current auth state - Is authenticated: ${_auth.currentUser != null}');

      if (userId == null) throw Exception('User not authenticated');

      print('Fetching photos for user: $userId, type: $photoType');

      // Simplified query without orderBy to avoid index requirement
      var query = _firestore
          .collection('progress_photos')
          .where('userId', isEqualTo: userId);

      if (photoType != null) {
        query = query.where('photoType', isEqualTo: photoType);
      }

      print('Executing Firestore query');
      final querySnapshot = await query.get();

      // Sort in memory
      final docs = querySnapshot.docs.toList()
        ..sort((a, b) {
          final aTime =
              (a.data()['uploadedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                  0;
          final bTime =
              (b.data()['uploadedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                  0;
          return bTime.compareTo(aTime); // Descending order
        });

      print('Found ${docs.length} photos');

      final photos = await Future.wait(docs.map((doc) async {
        final data = doc.data();
        print('Processing document ${doc.id}:');
        print('- Photo type: ${data['photoType']}');
        print('- URL: ${data['url']}');
        print('- Storage path: ${data['storagePath']}');

        // Verify URL is still valid
        try {
          final ref = _storage.refFromURL(data['url'] as String);
          await ref.getDownloadURL();
          print('- URL is valid');
        } catch (e) {
          print('- URL validation failed: $e');
          // Try to regenerate URL using storage path
          if (data['storagePath'] != null) {
            try {
              final newUrl = await _storage
                  .ref(data['storagePath'] as String)
                  .getDownloadURL();
              print('- Generated new URL: $newUrl');
              // Update Firestore with new URL
              await doc.reference.update({'url': newUrl});
              data['url'] = newUrl;
            } catch (e) {
              print('- Failed to regenerate URL: $e');
              // Fallback to old path format if exists
              if (data['fileName'] != null) {
                try {
                  final oldPathUrl = await _storage
                      .ref(
                          'users/${data['userId']}/progress_photos/${data['fileName']}')
                      .getDownloadURL();
                  print('- Generated URL from old path: $oldPathUrl');
                  await doc.reference.update({
                    'url': oldPathUrl,
                    'storagePath':
                        'users/${data['userId']}/progress_photos/${data['fileName']}'
                  });
                  data['url'] = oldPathUrl;
                } catch (e) {
                  print('- Failed to generate URL from old path: $e');
                }
              }
            }
          }
        }

        // Convert Timestamp to DateTime safely
        data['uploadedAt'] = _safeDateTime(data['uploadedAt']);

        return data;
      }));

      print('Processed ${photos.length} photos successfully');
      return photos;
    } catch (e) {
      print('Error getting photos: $e');
      throw Exception('Failed to get photos: $e');
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getPhotosByMonth(
      DateTime date) async {
    try {
      final userId = _auth.currentUser?.uid;
      print('Fetching photos for month: ${date.month}/${date.year}');

      if (userId == null) throw Exception('User not authenticated');

      // Get the start and end of the month
      final startOfMonth = DateTime(date.year, date.month, 1);
      final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

      print('Date range: $startOfMonth to $endOfMonth');

      try {
        // Try with simple query first
        var query = _firestore
            .collection('progress_photos')
            .where('userId', isEqualTo: userId);

        print('Executing Firestore query for month');
        final querySnapshot = await query.get();

        // Filter by date in memory
        final filteredDocs = querySnapshot.docs.where((doc) {
          final uploadedDate = _safeDateTime(doc.data()['uploadedAt']);
          return uploadedDate.isAfter(startOfMonth) &&
              uploadedDate.isBefore(endOfMonth);
        }).toList();

        print(
            'Found ${filteredDocs.length} photos for ${date.month}/${date.year}');

        final photos = await Future.wait(filteredDocs.map((doc) async {
          final data = doc.data();
          print('Processing document ${doc.id}:');
          print('- Photo type: ${data['photoType']}');
          print('- URL: ${data['url']}');
          print('- Upload date: ${_safeDateTime(data['uploadedAt'])}');

          // Verify URL is still valid
          try {
            final ref = _storage.refFromURL(data['url'] as String);
            await ref.getDownloadURL();
            print('- URL is valid');
          } catch (e) {
            print('- URL validation failed: $e');
            // Try to regenerate URL using storage path
            if (data['storagePath'] != null) {
              try {
                final newUrl = await _storage
                    .ref(data['storagePath'] as String)
                    .getDownloadURL();
                print('- Generated new URL: $newUrl');
                // Update Firestore with new URL
                await doc.reference.update({'url': newUrl});
                data['url'] = newUrl;
              } catch (e) {
                print('- Failed to regenerate URL: $e');
                // Fallback to old path format if exists
                if (data['fileName'] != null) {
                  try {
                    final oldPathUrl = await _storage
                        .ref(
                            'users/${data['userId']}/progress_photos/${data['fileName']}')
                        .getDownloadURL();
                    print('- Generated URL from old path: $oldPathUrl');
                    await doc.reference.update({
                      'url': oldPathUrl,
                      'storagePath':
                          'users/${data['userId']}/progress_photos/${data['fileName']}'
                    });
                    data['url'] = oldPathUrl;
                  } catch (e) {
                    print('- Failed to generate URL from old path: $e');
                  }
                }
              }
            }
          }

          // Convert Timestamp to DateTime safely
          data['uploadedAt'] = _safeDateTime(data['uploadedAt']);

          return data;
        }));

        // Group photos by type
        final photosByType = <String, List<Map<String, dynamic>>>{
          'front': [],
          'back': [],
          'left': [],
          'right': [],
        };

        for (var photo in photos) {
          final type = photo['photoType'] as String;
          if (photosByType.containsKey(type)) {
            // Add photo to its type list
            photosByType[type]!.add(photo);
            // Sort photos by date (newest first)
            photosByType[type]!.sort((a, b) {
              final aDate = a['uploadedAt'] as DateTime;
              final bDate = b['uploadedAt'] as DateTime;
              return bDate.compareTo(aDate);
            });
          }
        }

        print('Processed photos by type:');
        photosByType.forEach((type, photos) {
          print('- $type: ${photos.length} photos');
        });

        return photosByType;
      } catch (e) {
        print('Error with query: $e');
        // If there's an error with the query, return empty results
        return {
          'front': [],
          'back': [],
          'left': [],
          'right': [],
        };
      }
    } catch (e) {
      print('Error getting photos for month: $e');
      throw Exception('Failed to get photos for month: $e');
    }
  }

  // Calculate statistics between two months
  Map<String, List<Map<String, dynamic>>> calculateStatistics(
    Map<String, List<Map<String, dynamic>>> month1Photos,
    Map<String, List<Map<String, dynamic>>> month2Photos,
  ) {
    final stats = <String, List<Map<String, dynamic>>>{
      'front': [],
      'back': [],
      'left': [],
      'right': [],
    };

    // Define measurement points for each photo type
    final measurementPoints = {
      'front': [
        {'title': 'Shoulder Width', 'key': 'shoulder_width'},
        {'title': 'Chest Size', 'key': 'chest_size'},
        {'title': 'Waist Size', 'key': 'waist_size'},
        {'title': 'Hip Size', 'key': 'hip_size'},
      ],
      'back': [
        {'title': 'Upper Back Width', 'key': 'upper_back_width'},
        {'title': 'Lower Back Width', 'key': 'lower_back_width'},
        {'title': 'Waist Size', 'key': 'waist_size'},
      ],
      'left': [
        {'title': 'Arm Size', 'key': 'arm_size'},
        {'title': 'Chest Projection', 'key': 'chest_projection'},
        {'title': 'Stomach Projection', 'key': 'stomach_projection'},
      ],
      'right': [
        {'title': 'Arm Size', 'key': 'arm_size'},
        {'title': 'Chest Projection', 'key': 'chest_projection'},
        {'title': 'Stomach Projection', 'key': 'stomach_projection'},
      ],
    };

    // Generate mock statistics for demonstration
    measurementPoints.forEach((photoType, measurements) {
      if (month1Photos[photoType]?.isNotEmpty == true ||
          month2Photos[photoType]?.isNotEmpty == true) {
        for (var measurement in measurements) {
          // Generate random values for demonstration
          final month1Value = 80 + (DateTime.now().millisecondsSinceEpoch % 20);
          final month2Value =
              month1Value + (DateTime.now().millisecondsSinceEpoch % 10) - 5;

          stats[photoType]!.add({
            'title': measurement['title'],
            'month_1_per': month1Value.toString(),
            'month_2_per': month2Value.toString(),
            'diff_per': ((month2Value - month1Value) * 100 / month1Value)
                .abs()
                .toStringAsFixed(1),
            'improved': month2Value >= month1Value,
          });
        }
      }
    });

    return stats;
  }

  // Get chart data for the last 7 months
  List<List<FlSpot>> getChartData(DateTime startDate) {
    final spots1 = <FlSpot>[];
    final spots2 = <FlSpot>[];

    // Generate mock data for demonstration
    for (int i = 1; i <= 7; i++) {
      final value1 = 35.0 + (DateTime.now().millisecondsSinceEpoch % 45);
      final value2 = value1 + (DateTime.now().millisecondsSinceEpoch % 20) - 10;

      spots1.add(FlSpot(i.toDouble(), value1));
      spots2.add(FlSpot(i.toDouble(), value2));
    }

    return [spots1, spots2];
  }
}
