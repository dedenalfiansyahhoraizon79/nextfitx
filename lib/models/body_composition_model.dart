import 'package:cloud_firestore/cloud_firestore.dart';

// Main Body Composition Model
class BodyCompositionModel {
  final String? id;
  final String userId;
  final DateTime date;
  final BodyParameters bodyParameters;
  final BodyComposition bodyComposition;
  final SegmentalAnalysis segmentalAnalysis;
  final AdvancedMetrics advancedMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  BodyCompositionModel({
    this.id,
    required this.userId,
    required this.date,
    required this.bodyParameters,
    required this.bodyComposition,
    required this.segmentalAnalysis,
    required this.advancedMetrics,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'bodyParameters': bodyParameters.toMap(),
      'bodyComposition': bodyComposition.toMap(),
      'segmentalAnalysis': segmentalAnalysis.toMap(),
      'advancedMetrics': advancedMetrics.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BodyCompositionModel.fromMap(Map<String, dynamic> map, String id) {
    return BodyCompositionModel(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      bodyParameters: BodyParameters.fromMap(map['bodyParameters'] ?? {}),
      bodyComposition: BodyComposition.fromMap(map['bodyComposition'] ?? {}),
      segmentalAnalysis:
          SegmentalAnalysis.fromMap(map['segmentalAnalysis'] ?? {}),
      advancedMetrics: AdvancedMetrics.fromMap(map['advancedMetrics'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  BodyCompositionModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    BodyParameters? bodyParameters,
    BodyComposition? bodyComposition,
    SegmentalAnalysis? segmentalAnalysis,
    AdvancedMetrics? advancedMetrics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BodyCompositionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      bodyParameters: bodyParameters ?? this.bodyParameters,
      bodyComposition: bodyComposition ?? this.bodyComposition,
      segmentalAnalysis: segmentalAnalysis ?? this.segmentalAnalysis,
      advancedMetrics: advancedMetrics ?? this.advancedMetrics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Enhanced Body Parameters Model
class BodyParameters {
  final double weight; // kg
  final double height; // cm
  final double percentBodyFat; // %
  final double visceralFatIndex; // level
  final double basalMetabolicRate; // kcal
  final double totalEnergyExpenditure; // kcal
  final int physicalAge; // years
  final double fatFreeMassIndex; // kg/m²
  final double skeletalMuscleMass; // kg

  BodyParameters({
    required this.weight,
    required this.height,
    required this.percentBodyFat,
    required this.visceralFatIndex,
    required this.basalMetabolicRate,
    required this.totalEnergyExpenditure,
    required this.physicalAge,
    required this.fatFreeMassIndex,
    required this.skeletalMuscleMass,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'height': height,
      'percentBodyFat': percentBodyFat,
      'visceralFatIndex': visceralFatIndex,
      'basalMetabolicRate': basalMetabolicRate,
      'totalEnergyExpenditure': totalEnergyExpenditure,
      'physicalAge': physicalAge,
      'fatFreeMassIndex': fatFreeMassIndex,
      'skeletalMuscleMass': skeletalMuscleMass,
    };
  }

  factory BodyParameters.fromMap(Map<String, dynamic> map) {
    return BodyParameters(
      weight: _safeToDouble(map['weight']),
      height: _safeToDouble(map['height']),
      percentBodyFat: _safeToDouble(map['percentBodyFat']),
      visceralFatIndex: _safeToDouble(map['visceralFatIndex']),
      basalMetabolicRate: _safeToDouble(map['basalMetabolicRate']),
      totalEnergyExpenditure: _safeToDouble(map['totalEnergyExpenditure']),
      physicalAge: _safeToInt(map['physicalAge']),
      fatFreeMassIndex: _safeToDouble(map['fatFreeMassIndex']),
      skeletalMuscleMass: _safeToDouble(map['skeletalMuscleMass']),
    );
  }

  // Helper method for safe type conversion
  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  // Helper getters for common calculations
  String get weightCategory {
    if (weight < 50) return 'Underweight';
    if (weight < 80) return 'Normal';
    if (weight < 100) return 'Overweight';
    return 'Obese';
  }

  String get bodyFatCategory {
    if (percentBodyFat < 14) return 'Athletes';
    if (percentBodyFat < 21) return 'Fitness';
    if (percentBodyFat < 25) return 'Average';
    return 'Above Average';
  }

  String get visceralFatCategory {
    if (visceralFatIndex < 10) return 'Normal';
    if (visceralFatIndex < 15) return 'High';
    return 'Very High';
  }
}

// Enhanced Body Composition Model
class BodyComposition {
  final double bmi;
  final double bodyFatMass; // kg
  final double fatFreeWeight; // kg
  final double skeletalMuscleMass; // kg
  final double protein; // kg
  final double mineral; // kg
  final double totalBodyWater; // kg
  final double softLeanMass; // kg (Muscle, Water, etc.)
  final double bodyFatPercentage; // %
  final double skeletalMusclePercentage; // %
  final double visceralFatLevel; // level 1-30

  BodyComposition({
    required this.bmi,
    required this.bodyFatMass,
    required this.fatFreeWeight,
    required this.skeletalMuscleMass,
    required this.protein,
    required this.mineral,
    required this.totalBodyWater,
    required this.softLeanMass,
    required this.bodyFatPercentage,
    required this.skeletalMusclePercentage,
    required this.visceralFatLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'bmi': bmi,
      'bodyFatMass': bodyFatMass,
      'fatFreeWeight': fatFreeWeight,
      'skeletalMuscleMass': skeletalMuscleMass,
      'protein': protein,
      'mineral': mineral,
      'totalBodyWater': totalBodyWater,
      'softLeanMass': softLeanMass,
      'bodyFatPercentage': bodyFatPercentage,
      'skeletalMusclePercentage': skeletalMusclePercentage,
      'visceralFatLevel': visceralFatLevel,
    };
  }

  factory BodyComposition.fromMap(Map<String, dynamic> map) {
    return BodyComposition(
      bmi: BodyParameters._safeToDouble(map['bmi']),
      bodyFatMass: BodyParameters._safeToDouble(map['bodyFatMass']),
      fatFreeWeight: BodyParameters._safeToDouble(map['fatFreeWeight']),
      skeletalMuscleMass:
          BodyParameters._safeToDouble(map['skeletalMuscleMass']),
      protein: BodyParameters._safeToDouble(map['protein']),
      mineral: BodyParameters._safeToDouble(map['mineral']),
      totalBodyWater: BodyParameters._safeToDouble(map['totalBodyWater']),
      softLeanMass: BodyParameters._safeToDouble(map['softLeanMass']),
      bodyFatPercentage: BodyParameters._safeToDouble(map['bodyFatPercentage']),
      skeletalMusclePercentage:
          BodyParameters._safeToDouble(map['skeletalMusclePercentage']),
      visceralFatLevel: BodyParameters._safeToDouble(map['visceralFatLevel']),
    );
  }

  // Helper getters for assessments
  String get bodyFatCategory {
    // Based on ACE (American Council on Exercise) standards
    if (bodyFatPercentage < 14) return 'Athletes';
    if (bodyFatPercentage < 21) return 'Fitness';
    if (bodyFatPercentage < 25) return 'Average';
    return 'Above Average';
  }

  String get visceralFatCategory {
    if (visceralFatLevel < 10) return 'Normal';
    if (visceralFatLevel < 15) return 'High';
    return 'Very High';
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }
}

// Enhanced Segmental Analysis Model
class SegmentalAnalysis {
  final SegmentalData trunk;
  final SegmentalData leftArm;
  final SegmentalData rightArm;
  final SegmentalData leftLeg;
  final SegmentalData rightLeg;
  final BodyBalance bodyBalance;

  SegmentalAnalysis({
    required this.trunk,
    required this.leftArm,
    required this.rightArm,
    required this.leftLeg,
    required this.rightLeg,
    required this.bodyBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'trunk': trunk.toMap(),
      'leftArm': leftArm.toMap(),
      'rightArm': rightArm.toMap(),
      'leftLeg': leftLeg.toMap(),
      'rightLeg': rightLeg.toMap(),
      'bodyBalance': bodyBalance.toMap(),
    };
  }

  factory SegmentalAnalysis.fromMap(Map<String, dynamic> map) {
    return SegmentalAnalysis(
      trunk: SegmentalData.fromMap(map['trunk'] ?? {}),
      leftArm: SegmentalData.fromMap(map['leftArm'] ?? {}),
      rightArm: SegmentalData.fromMap(map['rightArm'] ?? {}),
      leftLeg: SegmentalData.fromMap(map['leftLeg'] ?? {}),
      rightLeg: SegmentalData.fromMap(map['rightLeg'] ?? {}),
      bodyBalance: BodyBalance.fromMap(map['bodyBalance'] ?? {}),
    );
  }

  // Helper methods for balance analysis
  double get totalBodyFatMass =>
      trunk.bodyFatMass +
      leftArm.bodyFatMass +
      rightArm.bodyFatMass +
      leftLeg.bodyFatMass +
      rightLeg.bodyFatMass;

  double get averageBodyFatPercentage =>
      (trunk.fatPercentage +
          leftArm.fatPercentage +
          rightArm.fatPercentage +
          leftLeg.fatPercentage +
          rightLeg.fatPercentage) /
      5;
}

// Enhanced Segmental Data Model
class SegmentalData {
  final double bodyFatMass; // kg
  final double fatPercentage; // %

  SegmentalData({
    required this.bodyFatMass,
    required this.fatPercentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'bodyFatMass': bodyFatMass,
      'fatPercentage': fatPercentage,
    };
  }

  factory SegmentalData.fromMap(Map<String, dynamic> map) {
    return SegmentalData(
      bodyFatMass: BodyParameters._safeToDouble(map['bodyFatMass']),
      fatPercentage: BodyParameters._safeToDouble(map['fatPercentage']),
    );
  }
}

// Body Balance Analysis Model
class BodyBalance {
  final double totalBodyFatMass; // total body fat mass
  final double averageBodyFatPercentage; // average body fat percentage
  final String balanceAssessment; // Overall assessment

  BodyBalance({
    required this.totalBodyFatMass,
    required this.averageBodyFatPercentage,
    required this.balanceAssessment,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalBodyFatMass': totalBodyFatMass,
      'averageBodyFatPercentage': averageBodyFatPercentage,
      'balanceAssessment': balanceAssessment,
    };
  }

  factory BodyBalance.fromMap(Map<String, dynamic> map) {
    return BodyBalance(
      totalBodyFatMass: BodyParameters._safeToDouble(map['totalBodyFatMass']),
      averageBodyFatPercentage:
          BodyParameters._safeToDouble(map['averageBodyFatPercentage']),
      balanceAssessment: map['balanceAssessment'] ?? 'Normal',
    );
  }
}

// Advanced Metrics Model for overall health assessment
class AdvancedMetrics {
  final double fitnessAge; // biological age based on body composition
  final String fitnessGrade; // A, B, C, D, F
  final double healthRiskScore; // 0-100 (lower is better)
  final List<String> healthRisks; // identified risk factors
  final List<String> recommendations; // personalized recommendations

  AdvancedMetrics({
    required this.fitnessAge,
    required this.fitnessGrade,
    required this.healthRiskScore,
    required this.healthRisks,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'fitnessAge': fitnessAge,
      'fitnessGrade': fitnessGrade,
      'healthRiskScore': healthRiskScore,
      'healthRisks': healthRisks,
      'recommendations': recommendations,
    };
  }

  factory AdvancedMetrics.fromMap(Map<String, dynamic> map) {
    return AdvancedMetrics(
      fitnessAge: BodyParameters._safeToDouble(map['fitnessAge']),
      fitnessGrade: map['fitnessGrade'] ?? 'C',
      healthRiskScore: BodyParameters._safeToDouble(map['healthRiskScore']),
      healthRisks: List<String>.from(map['healthRisks'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
    );
  }
}

// Chart Data Model for displaying trends
class BodyCompositionChartData {
  final DateTime date;
  final double value;
  final String type;
  final String label;

  BodyCompositionChartData({
    required this.date,
    required this.value,
    required this.type,
    String? label,
  }) : label = label ?? value.toStringAsFixed(1);
}

// Enhanced Summary Model
class BodyCompositionSummary {
  final double averageWeight;
  final double averageBMI;
  final double averageBodyFat;
  final double averageMuscleMass;
  final double averageBodyWater;
  final double averageVisceralFat;
  final double weightChange;
  final double bodyFatChange;
  final double muscleMassChange;
  final double bodyWaterChange;
  final double progressScore;
  final String overallTrend;
  final int totalRecords;
  final DateTime? lastRecordDate;
  final DateTime? firstRecordDate;
  final List<String> achievements;
  final List<String> concerns;

  BodyCompositionSummary({
    required this.averageWeight,
    required this.averageBMI,
    required this.averageBodyFat,
    required this.averageMuscleMass,
    required this.averageBodyWater,
    required this.averageVisceralFat,
    required this.weightChange,
    required this.bodyFatChange,
    required this.muscleMassChange,
    required this.bodyWaterChange,
    required this.progressScore,
    required this.overallTrend,
    required this.totalRecords,
    this.lastRecordDate,
    this.firstRecordDate,
    required this.achievements,
    required this.concerns,
  });
}

// Body Composition Calculator - Static methods for calculations
class BodyCompositionCalculator {
  // Calculate BMI
  static double calculateBMI(double weightKg, double heightCm) {
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  // Calculate BMR using Mifflin-St Jeor equation
  static double calculateBMR(
      double weightKg, double heightCm, int age, String gender) {
    double bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return gender.toLowerCase() == 'male' ? bmr + 5 : bmr - 161;
  }

  // Calculate TDEE (Total Daily Energy Expenditure)
  static double calculateTDEE(double bmr, double activityLevel) {
    return bmr * activityLevel;
  }

  // Calculate body fat percentage using multiple methods average
  static double calculateBodyFatPercentage(
      double weight, double height, double waist, double neck,
      {double? hip, required String gender}) {
    // US Navy method (simplified)
    double heightCm = height;
    double waistCm = waist;
    double neckCm = neck;

    if (gender.toLowerCase() == 'male') {
      return 495 / (1.0324 - 0.19077 * (waistCm - neckCm) / heightCm) - 450;
    } else {
      double hipCm = hip ?? waistCm * 1.1;
      return 495 / (1.29579 - 0.35004 * (waistCm + hipCm - neckCm) / heightCm) -
          450;
    }
  }

  // Calculate muscle quality score based on multiple factors
  static double calculateMuscleQualityScore(
      double muscleMass, double height, int age, double phaseAngle) {
    double expectedMuscle = height * 0.3; // Simplified expected muscle mass
    double muscleRatio = muscleMass / expectedMuscle;
    double ageAdjustment = (100 - age) / 100;
    double phaseAngleScore =
        phaseAngle / 10; // Phase angle typically 3-10 degrees

    return ((muscleRatio * 50) + (ageAdjustment * 25) + (phaseAngleScore * 25))
        .clamp(0, 100);
  }

  // Calculate body composition score
  static double calculateBodyCompositionScore(
      BodyComposition composition, BodyParameters parameters) {
    double fatScore = composition.bodyFatPercentage < 25
        ? (25 - composition.bodyFatPercentage) * 2
        : 0;
    double muscleScore = composition.skeletalMusclePercentage > 30
        ? composition.skeletalMusclePercentage
        : 0;
    double visceralScore = composition.visceralFatLevel < 10
        ? (10 - composition.visceralFatLevel) * 5
        : 0;
    double weightScore =
        parameters.weight >= 50 && parameters.weight <= 80 ? 30 : 0;

    return ((fatScore + muscleScore + visceralScore + weightScore) / 4)
        .clamp(0, 100);
  }

  // Generate health recommendations based on body composition
  static List<String> generateRecommendations(BodyCompositionModel model) {
    List<String> recommendations = [];

    if (model.bodyComposition.bodyFatPercentage > 25) {
      recommendations
          .add('Consider cardio exercises to reduce body fat percentage');
    }

    if (model.bodyComposition.skeletalMusclePercentage < 30) {
      recommendations.add('Include strength training to build muscle mass');
    }

    if (model.bodyComposition.visceralFatLevel > 10) {
      recommendations.add('Focus on core exercises and reduce abdominal fat');
    }

    if (model.bodyParameters.weight > 80) {
      recommendations.add('Consider a balanced diet to achieve healthy weight');
    }

    return recommendations;
  }

  // Identify health risks
  static List<String> identifyHealthRisks(BodyCompositionModel model) {
    List<String> risks = [];

    if (model.bodyComposition.visceralFatLevel > 15) {
      risks.add('High visceral fat - increased cardiovascular risk');
    }

    if (model.bodyParameters.weight > 100) {
      risks.add('Obesity - multiple health complications risk');
    }

    if (model.bodyComposition.bodyFatPercentage > 35) {
      risks.add('Very high body fat - metabolic syndrome risk');
    }

    if (model.bodyParameters.percentBodyFat > 30) {
      risks.add('High body fat percentage - diabetes and heart disease risk');
    }

    return risks;
  }
}
