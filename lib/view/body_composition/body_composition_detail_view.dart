import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../models/body_composition_model.dart';
import '../../services/body_composition_service.dart';
import 'body_composition_input_view.dart';

class BodyCompositionDetailView extends StatefulWidget {
  final BodyCompositionModel record;

  const BodyCompositionDetailView({super.key, required this.record});

  @override
  State<BodyCompositionDetailView> createState() =>
      _BodyCompositionDetailViewState();
}

class _BodyCompositionDetailViewState extends State<BodyCompositionDetailView>
    with TickerProviderStateMixin {
  final BodyCompositionService _bodyCompositionService =
      BodyCompositionService();
  late TabController _tabController;
  late BodyCompositionModel _record;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _record = widget.record;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  String _getBodyFatCategory(double bodyFat, String gender) {
    if (gender.toLowerCase() == 'male') {
      if (bodyFat < 6) return 'Essential Fat';
      if (bodyFat < 14) return 'Athletes';
      if (bodyFat < 18) return 'Fitness';
      if (bodyFat < 25) return 'Average';
      return 'Above Average';
    } else {
      if (bodyFat < 14) return 'Essential Fat';
      if (bodyFat < 21) return 'Athletes';
      if (bodyFat < 25) return 'Fitness';
      if (bodyFat < 32) return 'Average';
      return 'Above Average';
    }
  }

  Future<void> _deleteRecord() async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed && _record.id != null) {
      try {
        await _bodyCompositionService.deleteBodyComposition(_record.id!);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting record: $e')),
          );
        }
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Record'),
              content: const Text(
                  'Are you sure you want to delete this body composition record? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
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
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/img/ArrowLeft.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Body Composition Details",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                print('🔄 Opening edit view with record:');
                print('📊 Weight: ${_record.bodyParameters.weight}');
                print('📏 Height: ${_record.bodyParameters.height}');
                print('📈 BMI: ${_record.bodyComposition.bmi}');
                print('📅 Date: ${_record.date}');

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BodyCompositionInputView(
                      recordToEdit: _record,
                    ),
                  ),
                ).then((result) {
                  if (result != null) {
                    // Refresh the current view with updated data
                    setState(() {
                      _record = result as BodyCompositionModel;
                    });
                  }
                });
              } else if (value == 'delete') {
                _deleteRecord();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: TColor.primaryG),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE').format(_record.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('MMM dd, yyyy').format(_record.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: TColor.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: TColor.primaryColor1,
              labelColor: TColor.primaryColor1,
              unselectedLabelColor: TColor.gray,
              tabs: const [
                Tab(text: "Overview"),
                Tab(text: "Composition"),
                Tab(text: "Segmental"),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCompositionTab(),
                _buildSegmentalTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TColor.white,
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 2, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _deleteRecord,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: RoundButton(
                title: "Edit",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BodyCompositionInputView(recordToEdit: _record),
                    ),
                  ).then((result) {
                    if (result != null) {
                      Navigator.pop(context, result);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Weight",
                  "${_record.bodyParameters.weight.toStringAsFixed(1)} kg",
                  "Current Weight",
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildMetricCard(
                  "BMI",
                  _record.bodyComposition.bmi.toStringAsFixed(1),
                  _getBMICategory(_record.bodyComposition.bmi),
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Body Fat %",
                  "${_record.bodyParameters.percentBodyFat.toStringAsFixed(1)}%",
                  _getBodyFatCategory(
                      _record.bodyParameters.percentBodyFat, "Male"),
                  Colors.red,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildMetricCard(
                  "Muscle Mass",
                  "${_record.bodyComposition.skeletalMuscleMass.toStringAsFixed(1)} kg",
                  "Skeletal Muscle",
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Body Parameters Section
          Text(
            "Body Parameters",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),

          _buildParametersGrid([
            {
              "label": "Basal Metabolic Rate",
              "value":
                  "${_record.bodyParameters.basalMetabolicRate.toStringAsFixed(0)} kcal"
            },
            {
              "label": "Total Energy Expenditure",
              "value":
                  "${_record.bodyParameters.totalEnergyExpenditure.toStringAsFixed(0)} kcal"
            },
            {
              "label": "Physical Age",
              "value": "${_record.bodyParameters.physicalAge} years"
            },
            {
              "label": "Fat Free Mass Index",
              "value":
                  "${_record.bodyParameters.fatFreeMassIndex.toStringAsFixed(1)} kg/m²"
            },
            {
              "label": "Skeletal Muscle Mass",
              "value":
                  "${_record.bodyParameters.skeletalMuscleMass.toStringAsFixed(1)} kg"
            },
            {
              "label": "Visceral Fat Index",
              "value":
                  _record.bodyParameters.visceralFatIndex.toStringAsFixed(1)
            },
          ]),
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
          Text(
            "Body Composition Analysis",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Fat Analysis
          _buildSectionHeader("Fat Analysis", Icons.analytics, Colors.red),
          const SizedBox(height: 15),
          _buildParametersGrid([
            {
              "label": "Body Fat Percentage",
              "value":
                  "${_record.bodyComposition.bodyFatPercentage.toStringAsFixed(1)}%"
            },
            {
              "label": "Body Fat Mass",
              "value":
                  "${_record.bodyComposition.bodyFatMass.toStringAsFixed(1)} kg"
            },
            {
              "label": "Visceral Fat Level",
              "value":
                  _record.bodyComposition.visceralFatLevel.toStringAsFixed(0)
            },
            {
              "label": "Fat-Free Weight",
              "value":
                  "${_record.bodyComposition.fatFreeWeight.toStringAsFixed(1)} kg"
            },
          ]),

          const SizedBox(height: 30),

          // Muscle Analysis
          _buildSectionHeader(
              "Muscle Analysis", Icons.fitness_center, Colors.orange),
          const SizedBox(height: 15),
          _buildParametersGrid([
            {
              "label": "Skeletal Muscle Mass",
              "value":
                  "${_record.bodyComposition.skeletalMuscleMass.toStringAsFixed(1)} kg"
            },
            {
              "label": "Skeletal Muscle %",
              "value":
                  "${_record.bodyComposition.skeletalMusclePercentage.toStringAsFixed(1)}%"
            },
            {
              "label": "Soft Lean Mass",
              "value":
                  "${_record.bodyComposition.softLeanMass.toStringAsFixed(1)} kg"
            },
            {
              "label": "Protein",
              "value":
                  "${_record.bodyComposition.protein.toStringAsFixed(1)} kg"
            },
          ]),
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
          Text(
            "Segmental Analysis",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _buildSegmentalCard(
              "Trunk", _record.segmentalAnalysis.trunk, Colors.purple),
          _buildSegmentalCard(
              "Left Arm", _record.segmentalAnalysis.leftArm, Colors.blue),
          _buildSegmentalCard(
              "Right Arm", _record.segmentalAnalysis.rightArm, Colors.green),
          _buildSegmentalCard(
              "Left Leg", _record.segmentalAnalysis.leftLeg, Colors.orange),
          _buildSegmentalCard(
              "Right Leg", _record.segmentalAnalysis.rightLeg, Colors.red),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, String category, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildParametersGrid(List<Map<String, String>> parameters) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: TColor.lightGray,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          for (int i = 0; i < parameters.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildParameterItem(
                    parameters[i]["label"]!,
                    parameters[i]["value"]!,
                  ),
                ),
                if (i + 1 < parameters.length) ...[
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildParameterItem(
                      parameters[i + 1]["label"]!,
                      parameters[i + 1]["value"]!,
                    ),
                  ),
                ] else ...[
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParameterItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: TColor.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentalCard(String title, SegmentalData data, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildParameterItem(
                  "Body Fat Mass",
                  "${data.bodyFatMass.toStringAsFixed(1)} kg",
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildParameterItem(
                  "Fat Percentage",
                  "${data.fatPercentage.toStringAsFixed(1)}%",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
