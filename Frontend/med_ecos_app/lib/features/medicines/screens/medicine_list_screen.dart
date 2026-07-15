import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/medecos_loader.dart';
import '../../dashboard/widgets/rearrange_medicines_sheet.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  List<Medicine> _medicines = [];
  bool _loading = true;
  String? _error;
  String _selectedTimeFilter = 'All'; // 'All', 'Morning', 'Afternoon', 'Evening', 'Night'
  Set<String> _takenMedicines = {};

  @override
  void initState() {
    super.initState();
    _loadTakenStatus();
    _loadMedicines();
  }

  Future<void> _loadTakenStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = 'taken_doses_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    final list = prefs.getStringList(todayKey) ?? [];
    if (mounted) {
      setState(() {
        _takenMedicines = list.toSet();
      });
    }
  }

  Future<void> _toggleMedicineTaken(String medId) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = 'taken_doses_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    bool markedTaken = false;
    setState(() {
      if (_takenMedicines.contains(medId)) {
        _takenMedicines.remove(medId);
      } else {
        _takenMedicines.add(medId);
        markedTaken = true;
      }
    });
    await prefs.setStringList(todayKey, _takenMedicines.toList());
    if (markedTaken) {
      final med = _medicines.firstWhere((m) => m.id == medId, orElse: () => Medicine(id: medId, name: 'Medicine', dosage: '', frequency: 1, timings: [], startDate: DateTime.now()));
      ApiService().logMedicineTaken(med.id, med.name);
    }
  }

  Future<void> _loadMedicines() async {
    setState(() { _loading = true; });
    try {
      final List<dynamic> prescriptions = await ApiService().getPrescriptions();
      List<Medicine> parsedMedicines = [];
      
      for (var p in prescriptions) {
        final rawDoc = p['doctorName']?.toString() ?? p['doctor']?['name']?.toString() ?? 'Prescribed Doctor';
        final docName = AppConstants.formatDoctorName(rawDoc);
        final rawDateStr = p['date']?.toString() ?? p['createdAt']?.toString() ?? DateTime.now().toIso8601String();
        final parsedDate = DateTime.tryParse(rawDateStr) ?? DateTime.now();
        final formattedDate = DateFormat('MMM dd, yyyy').format(parsedDate);

        final medList = p['fullMedicines'] ?? p['medicines'] ?? [];
        for (var m in medList) {
          if (m is Map) {
            final freqStr = m['frequency']?.toString().toLowerCase() ?? '';
            int freq = 1;
            if (freqStr.contains('twice') || freqStr.contains('bid') || freqStr.contains('2')) freq = 2;
            if (freqStr.contains('thrice') || freqStr.contains('tid') || freqStr.contains('3')) freq = 3;
            
            final timingStr = m['timing']?.toString() ?? 'Morning';
            parsedMedicines.add(Medicine(
              id: m['_id']?.toString() ?? m['id']?.toString() ?? '${docName}_${m['name']}',
              name: m['name']?.toString() ?? 'Unknown Medicine',
              dosage: [m['frequency'], m['timing'], m['dosage']].firstWhere((val) => val != null && val.toString().trim().isNotEmpty, orElse: () => '')?.toString() ?? '',
              frequency: freq,
              timings: [], 
              startDate: parsedDate,
              doctorName: docName,
              prescriptionDate: formattedDate,
              timingCategory: timingStr,
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
              final timingStr = m['timing']?.toString() ?? 'Morning';
              parsedMedicines.add(Medicine(
                id: m['id']?.toString() ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: m['name']?.toString() ?? 'Custom Medicine',
                dosage: '${m['timing'] ?? 'Morning'} • ${m['context'] ?? 'After Food'} • $durText',
                frequency: 1,
                timings: [],
                startDate: DateTime.now(),
                doctorName: 'My Reminders',
                prescriptionDate: DateFormat('MMM dd, yyyy').format(DateTime.now()),
                timingCategory: timingStr,
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
        final key = '${m.name.toLowerCase().trim()}___${m.doctorName}';
        if (!deletedReminders.contains(m.name.toLowerCase().trim()) && !deletedReminders.contains(m.id)) {
          uniqueMedicines.putIfAbsent(key, () => m);
        }
      }

      final sortedMedicines = uniqueMedicines.values.toList();
      await ReminderService().sortMedicineObjects(sortedMedicines);

      setState(() {
        _medicines = sortedMedicines;
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
    Set<String> selectedTimings = {'Morning'};
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
                        final isSel = selectedTimings.contains(t);
                        return FilterChip(
                          label: Text(t),
                          selected: isSel,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedTimings.add(t);
                              } else {
                                if (selectedTimings.length > 1) {
                                  selectedTimings.remove(t);
                                }
                              }
                            });
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
                            timing: selectedTimings.join(', '),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Prescription',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how you want to add your prescription',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Scan with Camera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Capture a photo of physical prescription'),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureCameraPrescription();
                },
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload_file, color: AppColors.accent),
                ),
                title: const Text('Upload Document / Image',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Choose PDF report or photo from files'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFilePrescription();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureCameraPrescription() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _uploadPrescriptionBytes(bytes, photo.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera: $e')),
        );
      }
    }
  }

  Future<void> _pickFilePrescription() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        await _uploadPrescriptionBytes(
            result.files.single.bytes!, result.files.single.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _uploadPrescriptionBytes(Uint8List fileBytes, String fileName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              MedEcosLoader(size: 48),
              SizedBox(width: 20),
              Expanded(child: Text('Uploading & analyzing prescription via MedEcos AI...')),
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
      if (mounted) Navigator.pop(context);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final secureUrl = data['secure_url'] ?? '';
        final extracted = data['extracted'] as Map<String, dynamic>?;
        if (mounted) {
          _showVerifyScannedPrescriptionModal(secureUrl, extracted);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload prescription to cloud storage')),
          );
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

  void _showVerifyScannedPrescriptionModal(String secureUrl, [Map<String, dynamic>? extractedData]) {
    final List<Map<String, dynamic>> scannedRows = [];

    if (extractedData != null && extractedData['medicines'] != null && (extractedData['medicines'] as List).isNotEmpty) {
      for (var med in (extractedData['medicines'] as List)) {
        if (med is Map) {
          scannedRows.add({
            'nameCtrl': TextEditingController(text: med['name']?.toString() ?? ''),
            'dosageCtrl': TextEditingController(text: med['dosage']?.toString() ?? '1 Tablet'),
            'durationCtrl': TextEditingController(text: med['durationDays']?.toString() ?? '5'),
            'timing': med['timing']?.toString() ?? 'Morning, Night',
            'context': med['context']?.toString() ?? 'After Food',
          });
        }
      }
    }

    if (scannedRows.isEmpty) {
      scannedRows.add({
        'nameCtrl': TextEditingController(),
        'dosageCtrl': TextEditingController(text: '1 Tablet'),
        'durationCtrl': TextEditingController(text: '5'),
        'timing': 'Morning, Night',
        'context': 'After Food',
      });
    }

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
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Verify Scanned Medicines (${scannedRows.length})',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
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
                              'AI extracted all detected medicines! Please confirm or edit the doses below before saving.',
                              style: TextStyle(fontSize: 13, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(scannedRows.length, (index) {
                      final row = scannedRows[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Medicine #${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  if (scannedRows.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setModalState(() {
                                          scannedRows.removeAt(index);
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: row['nameCtrl'] as TextEditingController,
                                decoration: const InputDecoration(
                                  labelText: 'Medicine Name *',
                                  hintText: 'e.g. Amoxicillin 500mg',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: row['dosageCtrl'] as TextEditingController,
                                      decoration: const InputDecoration(
                                        labelText: 'Dosage',
                                        hintText: 'e.g. 1 Tablet',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: row['durationCtrl'] as TextEditingController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Duration (Days)',
                                        hintText: 'e.g. 5',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setModalState(() {
                          scannedRows.add({
                            'nameCtrl': TextEditingController(),
                            'dosageCtrl': TextEditingController(text: '1 Tablet'),
                            'durationCtrl': TextEditingController(text: '5'),
                            'timing': 'Morning, Night',
                            'context': 'After Food',
                          });
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      label: const Text('+ Add Another Medicine Row'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final validMedicines = [];
                          for (var row in scannedRows) {
                            final name = (row['nameCtrl'] as TextEditingController).text.trim();
                            if (name.isNotEmpty) {
                              validMedicines.add({
                                'name': name,
                                'dosage': (row['dosageCtrl'] as TextEditingController).text.trim(),
                                'durationDays': int.tryParse((row['durationCtrl'] as TextEditingController).text.trim()) ?? 0,
                                'timing': row['timing'] as String,
                                'context': row['context'] as String,
                              });
                            }
                          }

                          if (validMedicines.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please verify at least one medicine name')),
                            );
                            return;
                          }
                          Navigator.pop(ctx);

                          // 1. Save all confirmed medicines to Backend /prescriptions/scanned
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
                                'doctorName': extractedData?['doctorName'] ?? 'Scanned Prescription',
                                'diagnosis': extractedData?['diagnosis'] ?? 'Prescription Scan',
                                'medicines': validMedicines,
                              }),
                            );
                          } catch (_) {}

                          // 2. Add each confirmed medicine to Reminders
                          for (var med in validMedicines) {
                            await ReminderService().addCustomMedicine(
                              name: med['name'],
                              timing: med['timing'],
                              context: med['context'],
                              instruction: 'Scanned prescription dose',
                              dosage: med['dosage'],
                              durationDays: med['durationDays'],
                            );
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Scanned prescription saved & ${validMedicines.length} medicines added to reminders!')),
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
                        child: const Text('Confirm & Save All Reminders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            icon: const Icon(Icons.swap_vert),
            tooltip: 'Hold and Drag to Rearrange Order',
            onPressed: () => showRearrangeMedicinesBottomSheet(context, medicines: _medicines, onUpdate: _loadMedicines),
          ),
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
          ? const MedEcosLoader(size: 64, message: 'Loading medicines...')
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _medicines.isEmpty
                  ? const Center(child: Text('No medicines found. Tap "+ Add Medicine" to create a reminder!'))
                  : Column(
                      children: [
                        _buildAdherenceBanner(),
                        _buildTimeFilterTabs(),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 80),
                            children: _buildDoctorGroupedContainers(),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildAdherenceBanner() {
    final total = _medicines.length;
    final takenCount = _medicines.where((m) => _takenMedicines.contains(m.id)).length;
    final progress = total > 0 ? takenCount / total : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.track_changes, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Today's Daily Adherence",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$takenCount / $total Doses',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            takenCount == total
                ? "Excellent! You've taken all your scheduled medicines today 🌟"
                : 'Tap the checkbox on each medicine card as you complete your dose.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterTabs() {
    final times = ['All', 'Morning', 'Afternoon', 'Evening', 'Night'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: times.map((time) {
          final isSelected = _selectedTimeFilter == time;
          IconData? icon;
          if (time == 'Morning') icon = Icons.wb_sunny_outlined;
          if (time == 'Afternoon') icon = Icons.light_mode_outlined;
          if (time == 'Evening') icon = Icons.wb_twilight;
          if (time == 'Night') icon = Icons.nightlight_round;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: icon != null
                  ? Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primary,
                    )
                  : null,
              label: Text(time),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              backgroundColor: Colors.blue.withOpacity(0.08),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTimeFilter = time);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildDoctorGroupedContainers() {
    // 1. Filter medicines by selected time
    final filtered = _medicines.where((med) {
      if (_selectedTimeFilter == 'All') return true;
      final t = med.effectiveTiming.toLowerCase();
      final d = med.dosage.toLowerCase();
      final filterLower = _selectedTimeFilter.toLowerCase();
      return t.contains(filterLower) || d.contains(filterLower);
    }).toList();

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'No medicines scheduled for $_selectedTimeFilter.',
              style: const TextStyle(color: Colors.blueGrey, fontSize: 15),
            ),
          ),
        ),
      ];
    }

    // 2. Group by Doctor Name + Prescription Date
    final Map<String, List<Medicine>> grouped = {};
    for (var med in filtered) {
      final key = '${med.doctorName}|||${med.prescriptionDate}';
      grouped.putIfAbsent(key, () => []).add(med);
    }

    // 3. Build a Light Blue Container for each doctor group, sorting "My Reminders" to the top
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final aIsReminder = a.contains('My Reminders') || a.contains('Reminders');
      final bIsReminder = b.contains('My Reminders') || b.contains('Reminders');
      if (aIsReminder && !bIsReminder) return -1;
      if (!aIsReminder && bIsReminder) return 1;
      return a.compareTo(b);
    });

    final List<Widget> containers = [];
    for (final key in sortedKeys) {
      final meds = grouped[key]!;
      final parts = key.split('|||');
      final doctorName = parts.isNotEmpty ? AppConstants.formatDoctorName(parts[0]) : 'Dr. Prescribed';
      final dateStr = parts.length > 1 && parts[1].isNotEmpty
          ? parts[1]
          : DateFormat('MMM dd, yyyy').format(DateTime.now());

      containers.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5FF), // Light blue container
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFB3E5FC), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Tag & Date Tag Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tag of the Doctor
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.medical_services, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Prescribed by: $doctorName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // List of medicines inside this Doctor's Light Blue Container
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meds.length,
                onReorder: (oldIndex, newIndex) async {
                  if (oldIndex < newIndex) newIndex -= 1;
                  final item = meds.removeAt(oldIndex);
                  meds.insert(newIndex, item);

                  final prefs = await SharedPreferences.getInstance();
                  final customOrder = prefs.getStringList('medicine_custom_order') ?? [];
                  final draggedName = item.name.toLowerCase().trim();
                  customOrder.remove(draggedName);
                  if (newIndex < meds.length) {
                    final targetName = meds[newIndex].name.toLowerCase().trim();
                    final targetIdx = customOrder.indexOf(targetName);
                    if (targetIdx != -1) {
                      customOrder.insert(targetIdx, draggedName);
                    } else {
                      customOrder.add(draggedName);
                    }
                  } else {
                    customOrder.add(draggedName);
                  }
                  await prefs.setStringList('medicine_custom_order', customOrder);
                  await prefs.setString('medicine_sort_mode', 'custom');
                  _loadMedicines();
                },
                itemBuilder: (ctx, idx) {
                  final med = meds[idx];
                  final isTaken = _takenMedicines.contains(med.id);
                  return Card(
                    key: ValueKey("${med.id}_$idx"),
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isTaken ? Colors.green.shade300 : Colors.grey.shade200,
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: InkWell(
                          onTap: () => _toggleMedicineTaken(med.id),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isTaken
                                  ? Colors.green.withOpacity(0.15)
                                  : AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTaken ? Icons.check_circle : Icons.medication,
                              color: isTaken ? Colors.green : AppColors.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          med.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            decoration: isTaken ? TextDecoration.lineThrough : null,
                            color: isTaken ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  med.effectiveTiming,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  med.dosage.isNotEmpty ? med.dosage : '${med.frequency}x daily',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: isTaken,
                              activeColor: Colors.green,
                              onChanged: (val) => _toggleMedicineTaken(med.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 21),
                              tooltip: 'Remove reminder',
                              onPressed: () => _deleteMedicine(med),
                            ),
                            const Icon(Icons.drag_handle, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return containers;
  }
}
