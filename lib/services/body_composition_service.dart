import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/body_composition_model.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class BodyCompositionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Collection reference for body composition data
  CollectionReference get _bodyCompositionCollection {
    if (currentUserId == null) {
      throw Exception('No authenticated user found');
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('bodyComposition');
  }

  // Create new body composition record
  Future<String> createBodyComposition(
      BodyCompositionModel bodyComposition) async {
    try {
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      final now = DateTime.now();
      final data = bodyComposition.copyWith(
        userId: currentUserId!,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _bodyCompositionCollection.add(data.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create body composition record: $e');
    }
  }

  // Get all body composition records for current user
  Future<List<BodyCompositionModel>> getBodyCompositionRecords({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query =
          _bodyCompositionCollection.orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => BodyCompositionModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get body composition records: $e');
    }
  }

  // Get body composition record by ID
  Future<BodyCompositionModel?> getBodyCompositionById(String id) async {
    try {
      final doc = await _bodyCompositionCollection.doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return BodyCompositionModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get body composition record: $e');
    }
  }

  // Get body composition record for a specific date
  Future<BodyCompositionModel?> getBodyCompositionByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _bodyCompositionCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return BodyCompositionModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id);
    } catch (e) {
      throw Exception('Failed to get body composition record for date: $e');
    }
  }

  // Get body composition records for a date range
  Future<List<BodyCompositionModel>> getRecordsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      return await getBodyCompositionRecords(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception(
          'Failed to get body composition records for date range: $e');
    }
  }

  // Update body composition record
  Future<void> updateBodyComposition(
      String id, BodyCompositionModel bodyComposition) async {
    try {
      final data = bodyComposition.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );

      await _bodyCompositionCollection.doc(id).update(data.toMap());
    } catch (e) {
      throw Exception('Failed to update body composition record: $e');
    }
  }

  // Delete body composition record
  Future<void> deleteBodyComposition(String id) async {
    try {
      await _bodyCompositionCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete body composition record: $e');
    }
  }

  // Get chart data for different metrics
  Future<List<BodyCompositionChartData>> getChartData(
    String metric, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit = 30,
  }) async {
    try {
      final records = await getBodyCompositionRecords(
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      return records.map((record) {
        double value = 0.0;

        switch (metric.toLowerCase()) {
          case 'weight':
            value = record.bodyParameters.weight;
            break;
          case 'bmi':
            value = record.bodyComposition.bmi;
            break;
          case 'bodyfat':
          case 'body_fat':
            value = record.bodyParameters.percentBodyFat;
            break;
          case 'muscle':
          case 'muscle_mass':
            value = record.bodyComposition.skeletalMuscleMass;
            break;
          case 'muscle_percentage':
            value = record.bodyComposition.skeletalMusclePercentage;
            break;
          case 'visceral_fat':
            value = record.bodyComposition.visceralFatLevel;
            break;
          case 'bmr':
          case 'basal_metabolic_rate':
            value = record.bodyParameters.basalMetabolicRate;
            break;
          case 'fitness_age':
            value = record.advancedMetrics.fitnessAge;
            break;
          default:
            value = record.bodyParameters.weight;
        }

        return BodyCompositionChartData(
          date: record.date,
          value: value,
          type: metric,
          label: value.toStringAsFixed(1),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get chart data: $e');
    }
  }

  // Get body composition summary
  Future<BodyCompositionSummary> getBodyCompositionSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final records = await getBodyCompositionRecords(
        startDate: startDate,
        endDate: endDate,
      );

      if (records.isEmpty) {
        return BodyCompositionSummary(
          averageWeight: 0.0,
          averageBMI: 0.0,
          averageBodyFat: 0.0,
          averageMuscleMass: 0.0,
          averageBodyWater: 0.0,
          averageVisceralFat: 0.0,
          weightChange: 0.0,
          bodyFatChange: 0.0,
          muscleMassChange: 0.0,
          bodyWaterChange: 0.0,
          progressScore: 0.0,
          overallTrend: 'No Data',
          totalRecords: 0,
          achievements: [],
          concerns: [],
        );
      }

      // Calculate averages
      final averageWeight =
          records.map((r) => r.bodyParameters.weight).reduce((a, b) => a + b) /
              records.length;
      final averageBMI =
          records.map((r) => r.bodyComposition.bmi).reduce((a, b) => a + b) /
              records.length;
      final averageBodyFat = records
              .map((r) => r.bodyParameters.percentBodyFat)
              .reduce((a, b) => a + b) /
          records.length;
      final averageMuscleMass = records
              .map((r) => r.bodyComposition.skeletalMuscleMass)
              .reduce((a, b) => a + b) /
          records.length;
      final averageBodyWater = records
              .map((r) => r.bodyComposition.totalBodyWater)
              .reduce((a, b) => a + b) /
          records.length;
      final averageVisceralFat = records
              .map((r) => r.bodyComposition.visceralFatLevel)
              .reduce((a, b) => a + b) /
          records.length;

      // Calculate changes
      final firstRecord = records.first;
      final lastRecord = records.last;
      final weightChange =
          lastRecord.bodyParameters.weight - firstRecord.bodyParameters.weight;
      final bodyFatChange = lastRecord.bodyParameters.percentBodyFat -
          firstRecord.bodyParameters.percentBodyFat;
      final muscleMassChange = lastRecord.bodyComposition.skeletalMuscleMass -
          firstRecord.bodyComposition.skeletalMuscleMass;
      final bodyWaterChange = lastRecord.bodyComposition.totalBodyWater -
          firstRecord.bodyComposition.totalBodyWater;

      // Calculate progress score
      final progressScore = _calculateProgressScore(records);

      // Determine overall trend
      final overallTrend =
          _determineTrend(weightChange, bodyFatChange, muscleMassChange);

      // Generate achievements and concerns
      final achievements = _generateAchievements(records);
      final concerns = _generateConcerns(records);

      return BodyCompositionSummary(
        averageWeight: averageWeight,
        averageBMI: averageBMI,
        averageBodyFat: averageBodyFat,
        averageMuscleMass: averageMuscleMass,
        averageBodyWater: averageBodyWater,
        averageVisceralFat: averageVisceralFat,
        weightChange: weightChange,
        bodyFatChange: bodyFatChange,
        muscleMassChange: muscleMassChange,
        bodyWaterChange: bodyWaterChange,
        progressScore: progressScore,
        overallTrend: overallTrend,
        totalRecords: records.length,
        achievements: achievements,
        concerns: concerns,
      );
    } catch (e) {
      throw Exception('Failed to get body composition summary: $e');
    }
  }

  // Get recent records (last 7 days)
  Future<List<BodyCompositionModel>> getRecentRecords() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      return await getBodyCompositionRecords(
        startDate: sevenDaysAgo,
        limit: 10,
      );
    } catch (e) {
      throw Exception('Failed to get recent records: $e');
    }
  }

  // Check if record exists for today
  Future<bool> hasRecordForToday() async {
    try {
      final today = DateTime.now();
      final record = await getBodyCompositionByDate(today);
      return record != null;
    } catch (e) {
      return false;
    }
  }

  // Get segmental analysis trends
  Future<Map<String, List<BodyCompositionChartData>>> getSegmentalTrends({
    int? limit = 30,
  }) async {
    try {
      final records = await getBodyCompositionRecords(limit: limit);

      Map<String, List<BodyCompositionChartData>> trends = {
        'rightArmFat': [],
        'leftArmFat': [],
        'trunkFat': [],
        'rightLegFat': [],
        'leftLegFat': [],
        'rightArmMuscle': [],
        'leftArmMuscle': [],
        'trunkMuscle': [],
        'rightLegMuscle': [],
        'leftLegMuscle': [],
      };

      for (final record in records) {
        final date = record.date;

        trends['rightArmFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.rightArm.fatPercentage,
          type: 'rightArmFat',
        ));

        trends['leftArmFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.leftArm.fatPercentage,
          type: 'leftArmFat',
        ));

        trends['trunkFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.trunk.fatPercentage,
          type: 'trunkFat',
        ));

        trends['rightLegFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.rightLeg.fatPercentage,
          type: 'rightLegFat',
        ));

        trends['leftLegFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.leftLeg.fatPercentage,
          type: 'leftLegFat',
        ));

        // Fat trends
        trends['rightArmFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.rightArm.bodyFatMass,
          type: 'rightArmFat',
        ));

        trends['leftArmFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.leftArm.bodyFatMass,
          type: 'leftArmFat',
        ));

        trends['trunkFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.trunk.bodyFatMass,
          type: 'trunkFat',
        ));

        trends['rightLegFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.rightLeg.bodyFatMass,
          type: 'rightLegFat',
        ));

        trends['leftLegFat']!.add(BodyCompositionChartData(
          date: date,
          value: record.segmentalAnalysis.leftLeg.bodyFatMass,
          type: 'leftLegFat',
        ));
      }

      return trends;
    } catch (e) {
      throw Exception('Failed to get segmental trends: $e');
    }
  }

  // Stream for real-time updates
  Stream<List<BodyCompositionModel>> bodyCompositionStream() {
    try {
      return _bodyCompositionCollection
          .orderBy('date', descending: true)
          .limit(30)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => BodyCompositionModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList());
    } catch (e) {
      throw Exception('Failed to create body composition stream: $e');
    }
  }

  // Generate comprehensive sample body composition data
  Future<void> generateSampleBodyCompositionData() async {
    try {
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      final now = DateTime.now();
      final random = math.Random();

      // Generate 14 days of realistic sample data
      for (int i = 0; i < 14; i++) {
        final date = now.subtract(Duration(days: i));

        // Base parameters (simulating gradual improvements)
        final baseWeight = 70.0 + random.nextDouble() * 20; // 70-90 kg
        final height = 170.0 + random.nextDouble() * 15; // 170-185 cm
        final age = 25 + random.nextInt(20); // 25-45 years
        final isImproving = i < 7; // Showing improvement in recent days

        // Progressive improvements over time
        final improvementFactor = isImproving ? (7 - i) * 0.1 : 0;
        final bodyFatBase = 20.0 - improvementFactor + random.nextDouble() * 5;
        final muscleMassBase =
            35.0 + improvementFactor + random.nextDouble() * 5;

        // Enhanced Body Parameters
        final bodyParameters = BodyParameters(
          weight: baseWeight + random.nextDouble() * 2 - 1, // ±1kg variation
          height: height, // Use the height variable defined above
          percentBodyFat: bodyFatBase,
          visceralFatIndex: 8.0 - improvementFactor + random.nextDouble() * 4,
          basalMetabolicRate: BodyCompositionCalculator.calculateBMR(
              baseWeight, height, age, 'male'), // Use height variable
          totalEnergyExpenditure: BodyCompositionCalculator.calculateTDEE(
              BodyCompositionCalculator.calculateBMR(
                  baseWeight, height, age, 'male'),
              1.5 + random.nextDouble() * 0.3),
          physicalAge:
              age - (improvementFactor * 2).round() + random.nextInt(5),
          fatFreeMassIndex: (baseWeight * (1 - bodyFatBase / 100)) /
              ((height / 100) * (height / 100)),
          skeletalMuscleMass: muscleMassBase,
        );

        // Enhanced Body Composition
        final bodyComposition = BodyComposition(
          bmi: BodyCompositionCalculator.calculateBMI(baseWeight, height),
          bodyFatMass: baseWeight * bodyFatBase / 100,
          fatFreeWeight: baseWeight * (1 - bodyFatBase / 100),
          skeletalMuscleMass: muscleMassBase,
          protein: baseWeight * (0.18 + random.nextDouble() * 0.02),
          mineral: baseWeight * (0.04 + random.nextDouble() * 0.01),
          totalBodyWater: baseWeight * (0.55 + random.nextDouble() * 0.1),
          softLeanMass: baseWeight * (0.7 + random.nextDouble() * 0.1),
          bodyFatPercentage: bodyFatBase,
          skeletalMusclePercentage: muscleMassBase / baseWeight * 100,
          visceralFatLevel: 8.0 - improvementFactor + random.nextDouble() * 4,
        );

        // Create segmental data helper
        SegmentalData createSegmentalData(double sizeFactor) {
          return SegmentalData(
            bodyFatMass: baseWeight * bodyFatBase / 100 * sizeFactor,
            fatPercentage: bodyFatBase + random.nextDouble() * 2 - 1,
          );
        }

        // Enhanced Segmental Analysis
        final segmentalAnalysis = SegmentalAnalysis(
          trunk: createSegmentalData(0.48), // 48% of body mass
          leftArm: createSegmentalData(0.08),
          rightArm: createSegmentalData(0.08), // 8% of body mass
          leftLeg: createSegmentalData(0.18), // 18% of body mass
          rightLeg: createSegmentalData(0.18),
          bodyBalance: BodyBalance(
            totalBodyFatMass: baseWeight * bodyFatBase / 100,
            averageBodyFatPercentage: bodyFatBase,
            balanceAssessment: 'Good',
          ),
        );

        // Advanced Metrics
        final recommendations =
            BodyCompositionCalculator.generateRecommendations(
                BodyCompositionModel(
          userId: currentUserId!,
          date: date,
          bodyParameters: bodyParameters,
          bodyComposition: bodyComposition,
          segmentalAnalysis: segmentalAnalysis,
          advancedMetrics: AdvancedMetrics(
              fitnessAge: 0,
              healthRiskScore: 0,
              fitnessGrade: '',
              healthRisks: [],
              recommendations: []),
          createdAt: date,
          updatedAt: date,
        ));

        final healthRisks =
            BodyCompositionCalculator.identifyHealthRisks(BodyCompositionModel(
          userId: currentUserId!,
          date: date,
          bodyParameters: bodyParameters,
          bodyComposition: bodyComposition,
          segmentalAnalysis: segmentalAnalysis,
          advancedMetrics: AdvancedMetrics(
              fitnessAge: 0,
              healthRiskScore: 0,
              fitnessGrade: '',
              healthRisks: [],
              recommendations: []),
          createdAt: date,
          updatedAt: date,
        ));

        final advancedMetrics = AdvancedMetrics(
          fitnessAge:
              (age - improvementFactor.round() + random.nextInt(5)).toDouble(),
          fitnessGrade: bodyFatBase < 20
              ? 'A'
              : bodyFatBase < 25
                  ? 'B'
                  : 'C',
          healthRiskScore: math.max(
              0, 40 - improvementFactor * 5 + random.nextDouble() * 20),
          healthRisks: healthRisks,
          recommendations: recommendations,
        );

        // Create comprehensive body composition record
        final record = BodyCompositionModel(
          userId: currentUserId!,
          date: date,
          bodyParameters: bodyParameters,
          bodyComposition: bodyComposition,
          segmentalAnalysis: segmentalAnalysis,
          advancedMetrics: advancedMetrics,
          createdAt: date,
          updatedAt: date,
        );

        await createBodyComposition(record);
      }

      print('✅ Generated 14 days of comprehensive body composition data');
    } catch (e) {
      print('Error generating sample body composition data: $e');
      rethrow;
    }
  }

  // Clear all body composition data for current user
  Future<void> clearAllBodyCompositionData() async {
    try {
      if (currentUserId == null) {
        throw Exception('No authenticated user found');
      }

      print(
          '🗑️ Starting to clear all body composition data for user: $currentUserId');

      // Get all user's body composition records
      final snapshot = await _bodyCompositionCollection.get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ No body composition data found to delete');
        return;
      }

      print(
          '📊 Found ${snapshot.docs.length} body composition records to delete');

      // Delete all records in batch
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print(
          '✅ Successfully deleted ${snapshot.docs.length} body composition records');
    } catch (e) {
      print('❌ Error clearing body composition data: $e');
      throw Exception('Failed to clear body composition data: $e');
    }
  }

  // Get total count of records for current user
  Future<int> getTotalRecordsCount() async {
    try {
      if (currentUserId == null) {
        return 0;
      }

      final snapshot = await _bodyCompositionCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting records count: $e');
      return 0;
    }
  }

  // Get storage statistics for current user
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      if (currentUserId == null) {
        return {
          'totalRecords': 0,
          'dateRange': 'No data',
          'estimatedSize': '0 KB',
        };
      }

      final records = await getBodyCompositionRecords();

      if (records.isEmpty) {
        return {
          'totalRecords': 0,
          'dateRange': 'No data',
          'estimatedSize': '0 KB',
        };
      }

      // Calculate date range
      final sortedRecords = records..sort((a, b) => a.date.compareTo(b.date));
      final firstDate = sortedRecords.first.date;
      final lastDate = sortedRecords.last.date;
      final dateRange =
          '${DateFormat('dd/MM/yyyy').format(firstDate)} - ${DateFormat('dd/MM/yyyy').format(lastDate)}';

      // Estimate storage size (rough calculation)
      final estimatedSizeKB =
          records.length * 2; // ~2KB per comprehensive record
      final sizeDisplay = estimatedSizeKB < 1024
          ? '$estimatedSizeKB KB'
          : '${(estimatedSizeKB / 1024).toStringAsFixed(1)} MB';

      return {
        'totalRecords': records.length,
        'dateRange': dateRange,
        'estimatedSize': sizeDisplay,
        'firstRecord': firstDate,
        'lastRecord': lastDate,
      };
    } catch (e) {
      print('Error getting storage stats: $e');
      return {
        'totalRecords': 0,
        'dateRange': 'Error loading',
        'estimatedSize': 'Unknown',
      };
    }
  }

  // Helper methods for summary calculation
  double _calculateProgressScore(List<BodyCompositionModel> records) {
    if (records.length < 2) return 0.0;

    final firstRecord = records.first;
    final lastRecord = records.last;

    final weightChange =
        lastRecord.bodyParameters.weight - firstRecord.bodyParameters.weight;
    final bodyFatChange = lastRecord.bodyParameters.percentBodyFat -
        firstRecord.bodyParameters.percentBodyFat;
    final muscleMassChange = lastRecord.bodyComposition.skeletalMuscleMass -
        firstRecord.bodyComposition.skeletalMuscleMass;

    double score = 0.0;
    if (weightChange <= 0 && bodyFatChange <= 0 && muscleMassChange >= 0) {
      score = 85.0;
    } else if (weightChange <= 0 || bodyFatChange <= 0) {
      score = 65.0;
    } else {
      score = 45.0;
    }

    return score;
  }

  String _determineTrend(
      double weightChange, double bodyFatChange, double muscleMassChange) {
    if (weightChange > 2 || bodyFatChange > 2) {
      return 'Increasing';
    } else if (weightChange < -2 || bodyFatChange < -2) {
      return 'Decreasing';
    } else {
      return 'Stable';
    }
  }

  List<String> _generateAchievements(List<BodyCompositionModel> records) {
    List<String> achievements = [];

    if (records.length < 2) return achievements;

    final firstRecord = records.first;
    final lastRecord = records.last;
    final muscleMassChange = lastRecord.bodyComposition.skeletalMuscleMass -
        firstRecord.bodyComposition.skeletalMuscleMass;
    final bodyFatChange = lastRecord.bodyParameters.percentBodyFat -
        firstRecord.bodyParameters.percentBodyFat;
    final weightChange =
        lastRecord.bodyParameters.weight - firstRecord.bodyParameters.weight;

    if (muscleMassChange > 1) achievements.add('Muscle mass increased');
    if (bodyFatChange < -2) achievements.add('Body fat reduced');
    if (weightChange < 0 && bodyFatChange < 0) {
      achievements.add('Healthy weight loss');
    }

    return achievements;
  }

  List<String> _generateConcerns(List<BodyCompositionModel> records) {
    List<String> concerns = [];

    if (records.isEmpty) return concerns;

    final latestRecord = records.first;
    final averageVisceralFat = records
            .map((r) => r.bodyComposition.visceralFatLevel)
            .reduce((a, b) => a + b) /
        records.length;

    if (records.length >= 2) {
      final firstRecord = records.first;
      final lastRecord = records.last;
      final bodyFatChange = lastRecord.bodyParameters.percentBodyFat -
          firstRecord.bodyParameters.percentBodyFat;
      final muscleMassChange = lastRecord.bodyComposition.skeletalMuscleMass -
          firstRecord.bodyComposition.skeletalMuscleMass;

      if (bodyFatChange > 3) concerns.add('Body fat percentage increasing');
      if (muscleMassChange < -1) concerns.add('Muscle mass declining');
    }

    if (averageVisceralFat > 10) concerns.add('High visceral fat level');

    return concerns;
  }
}
