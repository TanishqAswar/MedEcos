import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final PreferencesService _prefs = PreferencesService();
  List<Medicine> _medicines = [];
  Map<String, String> _timeLabels = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() { _loading = true; });
    try {
      final List<dynamic> prescriptions = await ApiService().getPrescriptions();
      List<Medicine> parsedMedicines = [];
      
      for (var p in prescriptions) {
        if (p['fullMedicines'] != null) {
          for (var m in p['fullMedicines']) {
            final freqStr = m['frequency']?.toString().toLowerCase() ?? '';
            int freq = 1;
            if (freqStr.contains('twice') || freqStr.contains('bid') || freqStr.contains('2')) freq = 2;
            if (freqStr.contains('thrice') || freqStr.contains('tid') || freqStr.contains('3')) freq = 3;
            
            parsedMedicines.add(Medicine(
              id: m['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: m['name'] ?? 'Unknown Medicine',
              dosage: [m['frequency'], m['timing'], m['dosage']].firstWhere((val) => val != null && val.toString().trim().isNotEmpty, orElse: () => '')?.toString() ?? '',
              frequency: freq,
              timings: [], 
              startDate: DateTime.now(),
            ));
          }
        }
      }

      // Also include custom reminder medicines
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('custom_reminder_medicines');
      if (localJson != null) {
        try {
          final List<dynamic> customList = jsonDecode(localJson);
          for (var m in customList) {
            if (m is Map) {
              final durDays = int.tryParse(m['durationDays']?.toString() ?? '0') ?? 0;
              final durText = durDays > 0 ? '$durDays Days course' : 'Ongoing course';
              parsedMedicines.add(Medicine(
                id: m['id']?.toString() ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: m['name']?.toString() ?? 'Custom Medicine',
                dosage: '${m['timing'] ?? 'Morning'} • ${m['context'] ?? 'After Food'} • $durText',
                frequency: 1,
                timings: [],
                startDate: DateTime.now(),
              ));
            }
          }
        } catch (_) {}
      }

      final localDelJson = prefs.getString('deleted_reminder_medicines');
      List<String> deletedReminders = [];
      if (localDelJson != null) {
        try {
          final List<dynamic> list = jsonDecode(localDelJson);
          deletedReminders = list.map((e) => e.toString().toLowerCase().trim()).toList();
        } catch (_) {}
      }

      final uniqueMedicines = <String, Medicine>{};
      for (var m in parsedMedicines) {
        final key = m.name.toLowerCase().trim();
        if (!deletedReminders.contains(key) && !deletedReminders.contains(m.id)) {
          uniqueMedicines.putIfAbsent(key, () => m);
        }
      }

      setState(() {
        _medicines = uniqueMedicines.values.toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showAddMedicineReminderDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 Tablet');
    final instructionCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String selectedTiming = 'Morning';
    String selectedContext = 'After Food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Medicine Reminder',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name *',
                        hintText: 'e.g. Paracetamol 500mg, Vitamin D3',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medication),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dosageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        hintText: 'e.g. 1 Tablet, 10 ml',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration in Days (Optional)',
                        hintText: 'e.g. 5, 10 (Leave empty or 0 for ongoing course)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Timing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Morning', 'Afternoon', 'Evening', 'Night'].map((t) {
                        final isSel = selectedTiming == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSel,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          onSelected: (selected) {
                            if (selected) setModalState(() => selectedTiming = t);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Context', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['After Food', 'Before Food', 'With Food'].map((c) {
                        final isSel = selectedContext == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: isSel,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          onSelected: (selected) {
                            if (selected) setModalState(() => selectedContext = c);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: instructionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Special Instruction (Optional)',
                        hintText: 'e.g. Take with warm water',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please enter a medicine name')),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          await ReminderService().addCustomMedicine(
                            name: name,
                            timing: selectedTiming,
                            context: selectedContext,
                            instruction: instructionCtrl.text.trim(),
                            dosage: dosageCtrl.text.trim(),
                            durationDays: int.tryParse(durationCtrl.text.trim()) ?? 0,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Reminder for $name added successfully!')),
                            );
                            _loadMedicines();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _scanAndUploadPrescription() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(child: Text('Uploading & analyzing prescription to Cloudinary...')),
              ],
            ),
          ),
        );

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token') ?? '';

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConstants.apiBaseUrl}/api/v1/patient/prescriptions/upload'),
        );
        request.headers.addAll({'Authorization': 'Bearer $token'});

        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        final ext = fileName.split('.').last.toLowerCase();
        final contentType = ext == 'pdf'
            ? MediaType('application', 'pdf')
            : MediaType('image', ext == 'png' ? 'png' : 'jpeg');

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: contentType,
        ));

        final resStream = await request.send();
        final res = await http.Response.fromStream(resStream);
        if (mounted) Navigator.pop(context); // close loading

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final secureUrl = data['secure_url'] ?? '';
          if (mounted) {
            _showVerifyScannedPrescriptionModal(secureUrl);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload prescription to cloud storage')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning prescription: $e')),
        );
      }
    }
  }

  void _showVerifyScannedPrescriptionModal(String secureUrl) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 Tablet');
    final durationCtrl = TextEditingController(text: '5');
    String selectedTiming = 'Morning, Night';
    String selectedContext = 'After Food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verify Scanned Prescription',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cloud_done, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Prescription securely uploaded to Cloudinary! Review & add detected medicines below.',
                              style: TextStyle(fontSize: 13, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name *',
                        hintText: 'e.g. Amoxicillin 500mg',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medication),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dosageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        hintText: 'e.g. 1 Tablet',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration in Days',
                        hintText: 'e.g. 5',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please enter medicine name')),
                            );
                            return;
                          }
                          Navigator.pop(ctx);

                          // Save to Backend /prescriptions/scanned
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('jwt_token') ?? '';
                            await http.post(
                              Uri.parse('${AppConstants.apiBaseUrl}/api/v1/patient/prescriptions/scanned'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({
                                'attachmentUrl': secureUrl,
                                'doctorName': 'Scanned Prescription',
                                'medicines': [
                                  {
                                    'name': name,
                                    'timing': selectedTiming,
                                    'context': selectedContext,
                                    'dosage': dosageCtrl.text.trim(),
                                    'durationDays': int.tryParse(durationCtrl.text.trim()) ?? 0,
                                  }
                                ]
                              }),
                            );
                          } catch (_) {}

                          await ReminderService().addCustomMedicine(
                            name: name,
                            timing: selectedTiming,
                            context: selectedContext,
                            instruction: 'Scanned prescription dose',
                            dosage: dosageCtrl.text.trim(),
                            durationDays: int.tryParse(durationCtrl.text.trim()) ?? 0,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Scanned prescription saved & $name added to reminders!')),
                            );
                            _loadMedicines();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirm & Save Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteMedicine(Medicine med) async {
    await ReminderService().deleteReminderMedicine(med.id, med.name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${med.name} from reminders')),
      );
      _loadMedicines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines & Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Scan Prescription',
            onPressed: _scanAndUploadPrescription,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedicines,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineReminderDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _medicines.isEmpty
                  ? const Center(child: Text('No medicines found. Tap "+ Add Medicine" to create a reminder!'))
                  : ListView.builder(
                      itemCount: _medicines.length,
                      itemBuilder: (context, index) {
                        final med = _medicines[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: const Icon(Icons.medication, color: AppColors.primary),
                            ),
                            title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${med.dosage} • ${med.frequency}x daily'),
                                if (_timeLabels.containsKey(med.id))
                                  Text(_timeLabels[med.id]!, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Remove reminder',
                              onPressed: () => _deleteMedicine(med),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
