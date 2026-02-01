import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/pdf_service.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String patientId; // Pass patient info
  final String patientName;

  const PrescriptionFormScreen({super.key, required this.patientId, required this.patientName});

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final List<Map<String, String>> _medicines = [];
  
  // Form Controllers
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _medicineSearchController = TextEditingController();
  
  // Dosage Selections
  String _selectedTiming = 'Morning';
  String _selectedContext = 'After Food';
  String _selectedInstructions = 'None';

  final List<String> _timings = ['Morning', 'Afternoon', 'Evening', 'Night', '2 Times/Day', '3 Times/Day'];
  final List<String> _contexts = ['After Food', 'Before Food', 'With Food', 'Empty Stomach'];
  final List<String> _instructions = ['None', 'With Warm Water', 'With Milk', 'Chewable', 'Dissolve in water'];

  // Dummy Medicine List
  final List<String> _allMedicines = [
    'Paracetamol 500mg', 'Amoxicillin 250mg', 'Cetirizine 10mg', 'Ibuprofen 400mg', 
    'Omeprazole 20mg', 'Metformin 500mg', 'Atorvastatin 10mg', 'Aspirin 75mg'
  ];

  void _addMedicine() {
    if (_medicineSearchController.text.isNotEmpty) {
      setState(() {
        _medicines.add({
          'name': _medicineSearchController.text,
          'timing': _selectedTiming,
          'context': _selectedContext,
          'instruction': _selectedInstructions,
        });
        _medicineSearchController.clear();
      });
    }
  }

  void _generatePrescription() async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one medicine")));
      return;
    }

    try {
      await PdfService.generateAndPrintPrescription(
        doctorName: "Dr. Tanishq",
        patientName: widget.patientName,
        patientId: widget.patientId,
        symptoms: _symptomsController.text,
        medicines: _medicines,
        date: DateTime.now().toString().split(' ')[0],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Write Prescription")),
      body: Row(
        children: [
          // Left Side: Form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Patient: ${widget.patientName} (${widget.patientId})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 24),
                  
                  // Symptoms
                  TextField(
                    controller: _symptomsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Symptoms / Diagnosis",
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  Text("Add Medicine", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Medicine Search
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return _allMedicines.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      _medicineSearchController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      _medicineSearchController.value = controller.value; // Sync
                      return TextField(
                        controller: controller, // Use the Autocomplete controller
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                          labelText: "Medicine Name",
                          prefixIcon: Icon(Icons.medication),
                        ),
                        // Manually sync controller text on change if needed, but Autocomplete handles it usually
                        onChanged: (val) => _medicineSearchController.text = val,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Dosage Controls
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTiming,
                          items: _timings.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _selectedTiming = v!),
                          decoration: const InputDecoration(labelText: "Timing"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedContext,
                          items: _contexts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _selectedContext = v!),
                          decoration: const InputDecoration(labelText: "Context"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedInstructions,
                    items: _instructions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedInstructions = v!),
                    decoration: const InputDecoration(labelText: "Special Instructions"),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: _addMedicine,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Medicine"),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Side: Preview List
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Prescription Preview", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _medicines.length,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final med = _medicines[index];
                        return ListTile(
                          title: Text(med['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${med['timing']} • ${med['context']}\nNote: ${med['instruction']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () => setState(() => _medicines.removeAt(index)),
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _generatePrescription,
                    icon: const Icon(Icons.print),
                    label: const Text("Generate & Print"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
