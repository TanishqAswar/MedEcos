import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../models/document_model.dart';

class DocumentViewerScreen extends StatelessWidget {
  final MedicalDocumentModel document;
  final Color folderColor;

  const DocumentViewerScreen({
    super.key,
    required this.document,
    this.folderColor = AppColors.primary,
  });

  Future<Uint8List?> _getDocumentBytes() async {
    if (document.isBase64) {
      return document.base64Bytes;
    }
    if (document.filePath.isNotEmpty) {
      try {
        final file = File(document.filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (_) {}
    }
    if (document.cloudUrl != null && document.cloudUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(document.cloudUrl!));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${document.fileType.toUpperCase()} • ${DateFormat('MMM d, yyyy').format(document.uploadDate)}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share / Download',
            onPressed: () async {
              final bytes = await _getDocumentBytes();
              if (bytes != null) {
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: document.title.replaceAll(' ', '_') + (document.isPdf ? '.pdf' : '.jpg'),
                );
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not available locally for sharing.')));
                }
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Uint8List?>(
        future: _getDocumentBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Document file could not be loaded.',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The file may have been moved or deleted from local storage.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (document.isPdf) {
            return PdfPreview(
              build: (format) async => bytes,
              useActions: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: '${document.title}.pdf',
              scrollViewDecoration: const BoxDecoration(color: Colors.black),
            );
          } else {
            // Photo view
            return Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, _, __) => const Center(
                        child: Text('Failed to render image preview.', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                if (document.notes.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Doctor Notes / Comments:', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(document.notes, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }
        },
      ),
    );
  }
}
