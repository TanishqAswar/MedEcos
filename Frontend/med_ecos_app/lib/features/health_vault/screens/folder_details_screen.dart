import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../services/health_vault_service.dart';
import 'document_viewer_screen.dart';

class FolderDetailsScreen extends StatefulWidget {
  final FolderModel folder;

  const FolderDetailsScreen({super.key, required this.folder});

  @override
  State<FolderDetailsScreen> createState() => _FolderDetailsScreenState();
}

class _FolderDetailsScreenState extends State<FolderDetailsScreen> {
  final HealthVaultService _service = HealthVaultService();
  late FolderModel _folder;
  List<MedicalDocumentModel> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _folder = widget.folder;
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    setState(() => _loading = true);
    final docs = await _service.getDocumentsByFolder(_folder.id);
    if (mounted) {
      setState(() {
        _docs = docs;
        _loading = false;
      });
    }
  }

  Future<void> _showUploadSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Upload Medical Document',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                ),
                title: const Text('PDF Document', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Upload lab reports, discharge summaries, or bills'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPdfFile();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library, color: Colors.blue, size: 24),
                ),
                title: const Text('Photo from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Choose existing prescription or scan photos'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFile(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt, color: Colors.green, size: 24),
                ),
                title: const Text('Take Photo (Camera)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Snap a paper prescription or report instantly'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFile(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        await _saveAndRegisterFile(
          fileBytes: file.bytes,
          sourcePath: file.path,
          originalName: file.name,
          fileSize: file.size,
          fileType: 'pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking PDF: $e')));
      }
    }
  }

  Future<void> _pickImageFile(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final size = bytes.length;
        await _saveAndRegisterFile(
          fileBytes: bytes,
          sourcePath: picked.path,
          originalName: p.basename(picked.path),
          fileSize: size,
          fileType: 'image',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error capturing photo: $e')));
      }
    }
  }

  Future<void> _saveAndRegisterFile({
    Uint8List? fileBytes,
    String? sourcePath,
    required String originalName,
    required int fileSize,
    required String fileType,
  }) async {
    // Show prompt for Document Title & Notes
    final TextEditingController titleCtrl = TextEditingController(
      text: originalName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').replaceAll('_', ' '),
    );
    final TextEditingController notesCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Document Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  hintText: 'e.g. Blood Test Report Jan 2026',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes / Doctor Comments (Optional)',
                  hintText: 'e.g. Hemoglobin normal, prescribed D3',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Document', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    String savedPath = '';
    // Try copying to persistent app documents directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDir.path}/health_vault_files');
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }
      final ext = p.extension(originalName).isEmpty ? (fileType == 'pdf' ? '.pdf' : '.jpg') : p.extension(originalName);
      final destPath = '${vaultDir.path}/doc_${DateTime.now().millisecondsSinceEpoch}$ext';

      if (fileBytes != null) {
        final destFile = File(destPath);
        await destFile.writeAsBytes(fileBytes);
        savedPath = destPath;
      } else if (sourcePath != null && sourcePath.isNotEmpty) {
        final srcFile = File(sourcePath);
        final destFile = await srcFile.copy(destPath);
        savedPath = destFile.path;
      }
    } catch (_) {
      // Fallback to base64 if directory copy fails
      if (fileBytes != null) {
        savedPath = 'data:application/${fileType == "pdf" ? "pdf" : "image"};base64,${base64Encode(fileBytes)}';
      } else if (sourcePath != null && sourcePath.isNotEmpty) {
        savedPath = sourcePath;
      }
    }

    // Attempt optional Cloudinary upload via backend for cloud URL sync
    String? cloudUrl;
    if (fileBytes != null || (savedPath.isNotEmpty && !savedPath.startsWith('data:'))) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing document with Cloudinary secure storage...'), duration: Duration(seconds: 2)));
        }
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token') ?? '';
        
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConstants.apiBaseUrl}/api/v1/patient/prescriptions/upload'),
        );
        if (token.isNotEmpty) {
          request.headers.addAll({'Authorization': 'Bearer $token'});
        }

        final ext = p.extension(originalName).replaceAll('.', '').toLowerCase();
        final contentType = ext == 'pdf'
            ? MediaType('application', 'pdf')
            : MediaType('image', ext == 'png' ? 'png' : 'jpeg');

        Uint8List bytesToUpload = fileBytes ?? await File(savedPath).readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytesToUpload,
          filename: originalName,
          contentType: contentType,
        ));

        final resStream = await request.send().timeout(const Duration(seconds: 12));
        final res = await http.Response.fromStream(resStream);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          cloudUrl = data['secure_url'] ?? data['url'] ?? data['cloudinaryUrl'];
        }
      } catch (_) {
        // Continue peacefully if offline or upload times out; local storage ensures file availability
      }
    }

    await _service.addDocument(
      folderId: _folder.id,
      title: titleCtrl.text.trim().isEmpty ? originalName : titleCtrl.text.trim(),
      fileType: fileType,
      filePath: savedPath,
      cloudUrl: cloudUrl,
      fileSize: fileSize,
      notes: notesCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(cloudUrl != null ? 'Document uploaded & backed up to Cloudinary!' : 'Document saved securely in your Health Vault!'),
      ));
      _loadDocs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _folder.color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(_folder.iconData, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _folder.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(_folder.iconData, size: 64, color: color),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No documents in this folder yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap "Upload Document" below to add reports or prescriptions',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showUploadSheet,
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                        label: const Text('Add First Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDocs,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = _docs[index];
                      final isPdf = doc.isPdf;

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DocumentViewerScreen(document: doc, folderColor: color),
                                ),
                              );
                            },
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.image,
                                color: isPdf ? Colors.red : Colors.blue,
                                size: 26,
                              ),
                            ),
                            title: Text(
                              doc.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        doc.fileType.toUpperCase(),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      doc.formattedSize,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${DateFormat('MMM d, yyyy').format(doc.uploadDate)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                if (doc.notes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    doc.notes,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              onSelected: (val) async {
                                if (val == 'view') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DocumentViewerScreen(document: doc, folderColor: color),
                                    ),
                                  );
                                } else if (val == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Document?'),
                                      content: Text('Are you sure you want to remove "${doc.title}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _service.deleteDocument(doc.id);
                                    _loadDocs();
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('Open & Preview')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
