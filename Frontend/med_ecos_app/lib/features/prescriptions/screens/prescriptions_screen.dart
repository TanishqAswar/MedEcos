import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/medecos_loader.dart';
import '../../prescription/services/pdf_service.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _prescriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    try {
      final list = await _api.getPrescriptions();
      if (mounted) {
        setState(() {
          _prescriptions = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
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
              Expanded(child: Text('Uploading & analyzing prescription via AI...')),
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
            const SnackBar(content: Text('Failed to upload prescription file')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading prescription: $e')),
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
                          'Verify Scanned Prescription (${scannedRows.length} Meds)',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...scannedRows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: row['nameCtrl'],
                                      decoration: const InputDecoration(
                                        labelText: 'Medicine Name',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () {
                                      setModalState(() {
                                        scannedRows.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: row['dosageCtrl'],
                                      decoration: const InputDecoration(
                                        labelText: 'Dosage',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: row['durationCtrl'],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Duration (Days)',
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
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Medicine'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final List<Map<String, dynamic>> toSave = [];
                          for (var row in scannedRows) {
                            final name = (row['nameCtrl'] as TextEditingController).text.trim();
                            if (name.isNotEmpty) {
                              toSave.add({
                                'name': name,
                                'timing': row['timing'],
                                'context': row['context'],
                                'instruction': 'Scanned prescription',
                                'dosage': (row['dosageCtrl'] as TextEditingController).text.trim(),
                                'durationDays': int.tryParse((row['durationCtrl'] as TextEditingController).text.trim()) ?? 0,
                              });
                              await ReminderService().addCustomMedicine(
                                name: name,
                                timing: row['timing'],
                                context: row['context'],
                                instruction: 'Scanned prescription',
                                dosage: (row['dosageCtrl'] as TextEditingController).text.trim(),
                                durationDays: int.tryParse((row['durationCtrl'] as TextEditingController).text.trim()) ?? 0,
                                startDate: DateTime.now().toIso8601String(),
                              );
                            }
                          }

                          // Save scanned prescription on server
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('jwt_token') ?? '';
                            await http.post(
                              Uri.parse('${AppConstants.apiBaseUrl}/api/v1/patient/prescriptions/scanned'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $token',
                              },
                              body: jsonEncode({
                                'attachmentUrl': secureUrl,
                                'doctorName': 'Dr. Scanned AI',
                                'diagnosis': 'Uploaded & Verified via OCR',
                                'medicines': toSave,
                              }),
                            );
                          } catch (_) {}

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Prescription saved and reminders created!')),
                            );
                            _fetchPrescriptions();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirm & Save Prescription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MedEcosLoader(size: 64, message: 'Loading prescriptions...');
    }

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Prescriptions",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 22 : 28,
                      color: AppColors.textPrimary,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: _scanAndUploadPrescription,
                icon: const Icon(Icons.document_scanner),
                label: const Text('Scan & Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.9), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.document_scanner, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan & Digitize Prescription',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload physical prescription photos or PDFs to extract medicines automatically.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Center(
              child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            )
          else if (_prescriptions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No prescriptions found. Tap "Scan & Upload" above to add your first prescription!',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _prescriptions.length,
              itemBuilder: (context, index) {
                final p = _prescriptions[index];
                final date = DateTime.parse(p['date']);
                return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dr. ${p['doctorName'] ?? 'Unknown'}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(date),
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (p['status'] == 'Active') ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (p['status']?.toString().toUpperCase() ?? 'ACTIVE'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (p['status'] == 'Active') ? Colors.green : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Diagnosis: ${p['diagnosis'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      const Divider(height: 24),
                      const Text(
                        "Medicines:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(p['medicines'] as List<dynamic>).map((m) {
                        if (m is Map) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.medication, size: 16, color: Colors.blueGrey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m['name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text("${m['dosage'] ?? m['timing'] ?? ''} • ${m['frequency'] ?? m['context'] ?? ''} • ${m['duration'] ?? ''}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.medication, size: 16, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Text(m.toString()),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            try {
                              final possibleUrlKeys = [
                                'attachmentUrl',
                                'fileUrl',
                                'prescriptionUrl',
                                'imageUrl',
                                'pdfUrl',
                                'cloudinaryUrl',
                                'url',
                              ];
                              String? cloudUrl;
                              for (final key in possibleUrlKeys) {
                                final val = p[key]?.toString().trim();
                                if (val != null &&
                                    (val.startsWith('http://') || val.startsWith('https://'))) {
                                  cloudUrl = val;
                                  break;
                                }
                              }

                              if (cloudUrl != null) {
                                final uri = Uri.parse(cloudUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  return;
                                }
                              }

                              final prefs = await SharedPreferences.getInstance();
                              final patientName = prefs.getString('username') ?? 'Patient';
                              final patientId = prefs.getString('user_id') ?? 'Unknown ID';
                              
                              final List<Map<String, String>> medList = (p['medicines'] as List<dynamic>).map((m) {
                                if (m is Map) {
                                  return {
                                    'name': m['name']?.toString() ?? '',
                                    'timing': m['timing']?.toString().isNotEmpty == true ? m['timing'].toString() : (m['dosage']?.toString() ?? ''),
                                    'context': m['context']?.toString().isNotEmpty == true ? m['context'].toString() : (m['frequency']?.toString() ?? ''),
                                    'duration': m['duration']?.toString() ?? '',
                                    'instruction': m['instruction']?.toString() ?? '',
                                  };
                                }
                                return {'name': m.toString(), 'timing': '', 'context': '', 'duration': '', 'instruction': ''};
                              }).toList();

                              await PdfService.generateAndPrintPrescription(
                                doctorName: "Dr. ${p['doctorName'] ?? 'Unknown'}",
                                patientName: patientName,
                                patientId: patientId,
                                symptoms: p['diagnosis'] ?? 'N/A',
                                medicines: medList,
                                labTests: [], // Add lab tests if they exist in p['labTests']
                                date: DateFormat('MMM dd, yyyy hh:mm a').format(date),
                                doctorSpeciality: prefs.getString('speciality') ?? 'General Physician',
                                clinicLocation: prefs.getString('location') ?? 'MedEcos Clinic Network',
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating PDF: $e")));
                              }
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Download PDF"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
