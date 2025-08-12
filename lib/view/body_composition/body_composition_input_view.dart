import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/body_composition_model.dart';
import '../../services/body_composition_service.dart';

class BodyCompositionInputView extends StatefulWidget {
  final BodyCompositionModel? recordToEdit;

  const BodyCompositionInputView({super.key, this.recordToEdit});

  @override
  State<BodyCompositionInputView> createState() =>
      _BodyCompositionInputViewState();
}

class _BodyCompositionInputViewState extends State<BodyCompositionInputView>
    with TickerProviderStateMixin {
  final BodyCompositionService _bodyCompositionService =
      BodyCompositionService();
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  DateTime _selectedDate = DateTime.now();

  // Body Parameters Controllers
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _percentBodyFatController = TextEditingController();
  final _visceralFatIndexController = TextEditingController();
  final _basalMetabolicRateController = TextEditingController();
  final _totalEnergyExpenditureController = TextEditingController();
  final _physicalAgeController = TextEditingController();
  final _fatFreeMassIndexController = TextEditingController();
  final _skeletalMuscleMassController = TextEditingController();

  // Default values for calculations
  final int _defaultAge = 25;
  final String _defaultGender = 'male';

  // Body Composition Controllers
  final _bmiController = TextEditingController();
  final _bodyFatMassController = TextEditingController();
  final _fatFreeWeightController = TextEditingController();
  final _proteinController = TextEditingController();
  final _mineralController = TextEditingController();
  final _totalBodyWaterController = TextEditingController();
  final _softLeanMassController = TextEditingController();

  // Segmental Controllers
  final _trunkFatMassController = TextEditingController();
  final _leftArmFatMassController = TextEditingController();
  final _rightArmFatMassController = TextEditingController();
  final _leftLegFatMassController = TextEditingController();
  final _rightLegFatMassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check if we're editing an existing record
    if (widget.recordToEdit != null) {
      _isEditing = true;
      _selectedDate = widget.recordToEdit!.date;

      // Use Future.microtask to ensure data is populated after build
      Future.microtask(() {
        _populateFieldsWithRecord(widget.recordToEdit!);
        setState(() {
          // Trigger UI update after populating data
        });
      });
    }

    // Add calculation listeners after populating data
    _addCalculationListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _percentBodyFatController.dispose();
    _visceralFatIndexController.dispose();
    _basalMetabolicRateController.dispose();
    _totalEnergyExpenditureController.dispose();
    _physicalAgeController.dispose();
    _fatFreeMassIndexController.dispose();
    _skeletalMuscleMassController.dispose();
    _bmiController.dispose();
    _bodyFatMassController.dispose();
    _fatFreeWeightController.dispose();
    _proteinController.dispose();
    _mineralController.dispose();
    _totalBodyWaterController.dispose();
    _softLeanMassController.dispose();
    _trunkFatMassController.dispose();
    _leftArmFatMassController.dispose();
    _rightArmFatMassController.dispose();
    _leftLegFatMassController.dispose();
    _rightLegFatMassController.dispose();
    super.dispose();
  }

  void _addCalculationListeners() {
    // Auto-calculate BMI and related values when weight, height, or body fat changes
    void calculateValues() {
      // Skip auto-calculation if we're in editing mode
      if (_isEditing) return;

      final weight = double.tryParse(_weightController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0;
      final percentBodyFat =
          double.tryParse(_percentBodyFatController.text) ?? 0;

      if (weight > 0 && height > 0) {
        final bmi = weight / ((height / 100) * (height / 100));
        _bmiController.text = bmi.toStringAsFixed(1);
      }

      if (weight > 0 && percentBodyFat > 0) {
        final bodyFatMass = (weight * percentBodyFat) / 100;
        final fatFreeWeight = weight - bodyFatMass;

        _bodyFatMassController.text = bodyFatMass.toStringAsFixed(1);
        _fatFreeWeightController.text = fatFreeWeight.toStringAsFixed(1);

        // Calculate Fat Free Mass Index if we have height
        if (height > 0) {
          final heightM = height / 100;
          final ffmi = fatFreeWeight / (heightM * heightM);
          _fatFreeMassIndexController.text = ffmi.toStringAsFixed(1);
        }

        // Calculate Skeletal Muscle Mass (typically 40-50% of fat-free weight)
        final skeletalMuscleMass =
            fatFreeWeight * 0.45; // 45% of fat-free weight
        _skeletalMuscleMassController.text =
            skeletalMuscleMass.toStringAsFixed(1);

        // Calculate other body composition values
        final protein = weight * 0.18; // 18% of weight
        final mineral = weight * 0.04; // 4% of weight
        final totalBodyWater = weight * 0.55; // 55% of weight
        final softLeanMass = weight * 0.7; // 70% of weight

        _proteinController.text = protein.toStringAsFixed(1);
        _mineralController.text = mineral.toStringAsFixed(1);
        _totalBodyWaterController.text = totalBodyWater.toStringAsFixed(1);
        _softLeanMassController.text = softLeanMass.toStringAsFixed(1);
      }

      // Calculate BMR if we have weight, height, and age
      final age = int.tryParse(_physicalAgeController.text) ?? _defaultAge;
      if (weight > 0 && height > 0 && age > 0) {
        final bmr = BodyCompositionCalculator.calculateBMR(
            weight, height, age, _defaultGender);
        _basalMetabolicRateController.text = bmr.toStringAsFixed(0);

        // Calculate TDEE (assuming moderate activity level of 1.55)
        final tdee = BodyCompositionCalculator.calculateTDEE(bmr, 1.55);
        _totalEnergyExpenditureController.text = tdee.toStringAsFixed(0);
      }
    }

    _weightController.addListener(calculateValues);
    _heightController.addListener(calculateValues);
    _percentBodyFatController.addListener(calculateValues);
    _physicalAgeController.addListener(calculateValues);
  }

  void _populateFieldsWithRecord(BodyCompositionModel record) {
    print('🔄 Populating fields with record data...');
    print('📊 Weight: ${record.bodyParameters.weight}');
    print('📏 Height: ${record.bodyParameters.height}');
    print('📈 BMI: ${record.bodyComposition.bmi}');
    print('📅 Date: ${record.date}');
    print('🆔 Record ID: ${record.id}');

    // Populate body parameters
    _weightController.text = record.bodyParameters.weight.toString();
    _heightController.text = record.bodyParameters.height.toString();
    _percentBodyFatController.text =
        record.bodyParameters.percentBodyFat.toString();
    _visceralFatIndexController.text =
        record.bodyParameters.visceralFatIndex.toString();
    _basalMetabolicRateController.text =
        record.bodyParameters.basalMetabolicRate.toString();
    _totalEnergyExpenditureController.text =
        record.bodyParameters.totalEnergyExpenditure.toString();
    _physicalAgeController.text = record.bodyParameters.physicalAge.toString();
    _fatFreeMassIndexController.text =
        record.bodyParameters.fatFreeMassIndex.toString();
    _skeletalMuscleMassController.text =
        record.bodyParameters.skeletalMuscleMass.toString();

    // Populate body composition
    _bmiController.text = record.bodyComposition.bmi.toString();
    _bodyFatMassController.text = record.bodyComposition.bodyFatMass.toString();
    _fatFreeWeightController.text =
        record.bodyComposition.fatFreeWeight.toString();
    _proteinController.text = record.bodyComposition.protein.toString();
    _mineralController.text = record.bodyComposition.mineral.toString();
    _totalBodyWaterController.text =
        record.bodyComposition.totalBodyWater.toString();
    _softLeanMassController.text =
        record.bodyComposition.softLeanMass.toString();

    // Populate segmental data
    _trunkFatMassController.text =
        record.segmentalAnalysis.trunk.bodyFatMass.toString();
    _leftArmFatMassController.text =
        record.segmentalAnalysis.leftArm.bodyFatMass.toString();
    _rightArmFatMassController.text =
        record.segmentalAnalysis.rightArm.bodyFatMass.toString();
    _leftLegFatMassController.text =
        record.segmentalAnalysis.leftLeg.bodyFatMass.toString();
    _rightLegFatMassController.text =
        record.segmentalAnalysis.rightLeg.bodyFatMass.toString();

    print('✅ Fields populated successfully');
    print('🔍 Checking populated data:');
    print('   Weight controller: "${_weightController.text}"');
    print('   Height controller: "${_heightController.text}"');
    print('   BMI controller: "${_bmiController.text}"');
    print('   Body Fat controller: "${_bodyFatMassController.text}"');
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
          _isEditing ? "Edit Body Composition" : "Add Body Composition",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Auto-calculation enabled. Changes will recalculate values.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Enable Auto-calculation',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Date Selection
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: TColor.gray, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: Text(
                      "Change",
                      style: TextStyle(color: TColor.primaryColor1),
                    ),
                  ),
                ],
              ),
            ),

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
                Tab(text: "Basic"),
                Tab(text: "Composition"),
                Tab(text: "Segmental"),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicTab(),
                  _buildCompositionTab(),
                  _buildSegmentalTab(),
                ],
              ),
            ),

            // Save Button
            Container(
              padding: const EdgeInsets.all(20),
              child: RoundButton(
                title: _isLoading ? "Saving..." : "Save Body Composition",
                onPressed: () {
                  if (!_isLoading) {
                    _saveBodyComposition();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Body Parameters"),
          const SizedBox(height: 20),
          _buildTextField(
            "Weight (kg)",
            _weightController,
            TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight <= 0 || weight > 300) {
                return 'Invalid weight';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Height (cm)",
            _heightController,
            TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final height = double.tryParse(value);
              if (height == null || height <= 0 || height > 250) {
                return 'Invalid height';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Percent Body Fat (%)",
            _percentBodyFatController,
            TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final percent = double.tryParse(value);
              if (percent == null || percent < 0 || percent > 50) {
                return 'Invalid percentage';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Visceral Fat Index",
            _visceralFatIndexController,
            TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final index = double.tryParse(value);
              if (index == null || index < 0 || index > 30) {
                return 'Invalid index';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          _buildReadOnlyTextField(
            "Basal Metabolic Rate (kcal) (Auto-calculated)",
            _basalMetabolicRateController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildReadOnlyTextField(
            "Total Energy Expenditure (kcal) (Auto-calculated)",
            _totalEnergyExpenditureController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Physical Age (years)",
            _physicalAgeController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildReadOnlyTextField(
            "Fat Free Mass Index (kg/m²) (Auto-calculated)",
            _fatFreeMassIndexController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Skeletal Muscle Mass (kg)",
            _skeletalMuscleMassController,
            TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildCompositionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Body Composition"),
          const SizedBox(height: 20),
          _buildReadOnlyTextField(
            "BMI (Auto-calculated)",
            _bmiController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildReadOnlyTextField(
            "Body Fat Mass (kg) (Auto-calculated)",
            _bodyFatMassController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildReadOnlyTextField(
            "Fat-Free Weight (kg) (Auto-calculated)",
            _fatFreeWeightController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildReadOnlyTextField(
            "Skeletal Muscle Mass (kg) (Auto-calculated)",
            _skeletalMuscleMassController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Protein (kg)",
            _proteinController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Mineral (kg)",
            _mineralController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Total Body Water (kg)",
            _totalBodyWaterController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Soft Lean Mass (kg)",
            _softLeanMassController,
            TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Segmental Body Fat Mass"),
          const SizedBox(height: 20),
          _buildTextField(
            "Trunk Fat Mass (kg)",
            _trunkFatMassController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Left Arm Fat Mass (kg)",
            _leftArmFatMassController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Right Arm Fat Mass (kg)",
            _rightArmFatMassController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Left Leg Fat Mass (kg)",
            _leftLegFatMassController,
            TextInputType.number,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Right Leg Fat Mass (kg)",
            _rightLegFatMassController,
            TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    String? Function(String?)? validator,
    String? suffixText,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : null,
          decoration: InputDecoration(
            hintText: "Enter $label",
            suffixText: suffixText,
            suffixStyle: TextStyle(
              color: TColor.primaryColor1,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColor.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColor.primaryColor1),
            ),
            fillColor: TColor.lightGray,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyTextField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: true,
          style: TextStyle(
            color: TColor.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: "Auto-calculated",
            suffixText: suffixText,
            suffixStyle: TextStyle(
              color: TColor.primaryColor1,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColor.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColor.primaryColor1),
            ),
            fillColor: Colors.grey.shade100,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: TColor.primaryColor1,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: TColor.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _saveBodyComposition() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate required fields
      if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
        throw Exception('Weight and Height are required fields.');
      }

      // Parse all input values with safe parsing
      final weight = double.tryParse(_weightController.text) ?? 0.0;
      final height = double.tryParse(_heightController.text) ?? 0.0;
      final percentBodyFat = double.tryParse(_percentBodyFatController.text) ??
          20.0; // Default 20%
      final visceralFatIndex =
          double.tryParse(_visceralFatIndexController.text) ?? 8.0; // Default 8
      final basalMetabolicRate =
          double.tryParse(_basalMetabolicRateController.text) ?? 0.0;
      final totalEnergyExpenditure =
          double.tryParse(_totalEnergyExpenditureController.text) ?? 0.0;
      final physicalAge =
          int.tryParse(_physicalAgeController.text) ?? _defaultAge;
      final fatFreeMassIndex =
          double.tryParse(_fatFreeMassIndexController.text) ?? 0.0;
      final skeletalMuscleMass =
          double.tryParse(_skeletalMuscleMassController.text) ?? 0.0;

      // Body composition values with safe parsing
      final bmi = double.tryParse(_bmiController.text) ?? 0.0;
      if (bmi <= 0) {
        throw Exception(
            'BMI must be calculated. Please enter weight and height.');
      }

      // Validate auto-calculated values
      if (_bodyFatMassController.text.isEmpty ||
          _fatFreeWeightController.text.isEmpty) {
        throw Exception(
            'Please enter Percent Body Fat to calculate Body Fat Mass and Fat-Free Weight.');
      }
      final bodyFatMass = double.tryParse(_bodyFatMassController.text) ?? 0.0;
      final fatFreeWeight =
          double.tryParse(_fatFreeWeightController.text) ?? 0.0;
      final protein = double.tryParse(_proteinController.text) ??
          (weight * 0.18); // Default 18% of weight
      final mineral = double.tryParse(_mineralController.text) ??
          (weight * 0.04); // Default 4% of weight
      final totalBodyWater = double.tryParse(_totalBodyWaterController.text) ??
          (weight * 0.55); // Default 55% of weight
      final softLeanMass = double.tryParse(_softLeanMassController.text) ??
          (weight * 0.7); // Default 70% of weight

      // Segmental values with safe parsing and default values
      final trunkFatMass = double.tryParse(_trunkFatMassController.text) ??
          (bodyFatMass * 0.48); // 48% of body fat
      final leftArmFatMass = double.tryParse(_leftArmFatMassController.text) ??
          (bodyFatMass * 0.08); // 8% of body fat
      final rightArmFatMass =
          double.tryParse(_rightArmFatMassController.text) ??
              (bodyFatMass * 0.08); // 8% of body fat
      final leftLegFatMass = double.tryParse(_leftLegFatMassController.text) ??
          (bodyFatMass * 0.18); // 18% of body fat
      final rightLegFatMass =
          double.tryParse(_rightLegFatMassController.text) ??
              (bodyFatMass * 0.18); // 18% of body fat

      // Create body parameters
      final bodyParameters = BodyParameters(
        weight: weight,
        height: height,
        percentBodyFat: percentBodyFat,
        visceralFatIndex: visceralFatIndex,
        basalMetabolicRate: basalMetabolicRate,
        totalEnergyExpenditure: totalEnergyExpenditure,
        physicalAge: physicalAge,
        fatFreeMassIndex: fatFreeMassIndex,
        skeletalMuscleMass: skeletalMuscleMass,
      );

      // Create body composition
      final bodyComposition = BodyComposition(
        bmi: bmi,
        bodyFatMass: bodyFatMass,
        fatFreeWeight: fatFreeWeight,
        skeletalMuscleMass: skeletalMuscleMass,
        protein: protein,
        mineral: mineral,
        totalBodyWater: totalBodyWater,
        softLeanMass: softLeanMass,
        bodyFatPercentage: percentBodyFat,
        skeletalMusclePercentage: (skeletalMuscleMass / weight) * 100,
        visceralFatLevel: visceralFatIndex,
      );

      // Create segmental data
      SegmentalData createSegmentalData(double fatMass, double fatPercentage) {
        return SegmentalData(
          bodyFatMass: fatMass,
          fatPercentage: fatPercentage,
        );
      }

      final segmentalAnalysis = SegmentalAnalysis(
        trunk: createSegmentalData(trunkFatMass, percentBodyFat * 1.1),
        leftArm: createSegmentalData(leftArmFatMass, percentBodyFat * 0.8),
        rightArm: createSegmentalData(rightArmFatMass, percentBodyFat * 0.8),
        leftLeg: createSegmentalData(leftLegFatMass, percentBodyFat * 0.9),
        rightLeg: createSegmentalData(rightLegFatMass, percentBodyFat * 0.9),
        bodyBalance: BodyBalance(
          totalBodyFatMass: trunkFatMass +
              leftArmFatMass +
              rightArmFatMass +
              leftLegFatMass +
              rightLegFatMass,
          averageBodyFatPercentage: percentBodyFat,
          balanceAssessment: 'Good',
        ),
      );

      // Create advanced metrics
      final advancedMetrics = AdvancedMetrics(
        fitnessAge: physicalAge.toDouble(),
        fitnessGrade: percentBodyFat < 20
            ? 'A'
            : percentBodyFat < 25
                ? 'B'
                : 'C',
        healthRiskScore: visceralFatIndex > 10 ? 40.0 : 20.0,
        healthRisks:
            BodyCompositionCalculator.identifyHealthRisks(BodyCompositionModel(
          userId: '',
          date: _selectedDate,
          bodyParameters: bodyParameters,
          bodyComposition: bodyComposition,
          segmentalAnalysis: segmentalAnalysis,
          advancedMetrics: AdvancedMetrics(
            fitnessAge: 0,
            fitnessGrade: '',
            healthRiskScore: 0,
            healthRisks: [],
            recommendations: [],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )),
        recommendations: BodyCompositionCalculator.generateRecommendations(
            BodyCompositionModel(
          userId: '',
          date: _selectedDate,
          bodyParameters: bodyParameters,
          bodyComposition: bodyComposition,
          segmentalAnalysis: segmentalAnalysis,
          advancedMetrics: AdvancedMetrics(
            fitnessAge: 0,
            fitnessGrade: '',
            healthRiskScore: 0,
            healthRisks: [],
            recommendations: [],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )),
      );

      // Create final model
      final record = BodyCompositionModel(
        userId: '', // Will be set by service
        date: _selectedDate,
        bodyParameters: bodyParameters,
        bodyComposition: bodyComposition,
        segmentalAnalysis: segmentalAnalysis,
        advancedMetrics: advancedMetrics,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing && widget.recordToEdit != null) {
        // Update existing record
        await _bodyCompositionService.updateBodyComposition(
          widget.recordToEdit!.id!,
          record,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Body composition updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Create new record
        await _bodyCompositionService.createBodyComposition(record);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Body composition saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving body composition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
