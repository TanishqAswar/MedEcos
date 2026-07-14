import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class MedicalDocumentModel {
  final String id;
  final String folderId;
  final String title;
  final String fileType; // 'pdf' or 'image'
  final String filePath; // Local path or base64
  final String? cloudUrl; // Cloudinary CDN URL
  final int fileSize;
  final DateTime uploadDate;
  final String notes;

  const MedicalDocumentModel({
    required this.id,
    required this.folderId,
    required this.title,
    required this.fileType,
    required this.filePath,
    this.cloudUrl,
    required this.fileSize,
    required this.uploadDate,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'fileType': fileType,
      'filePath': filePath,
      'cloudUrl': cloudUrl,
      'fileSize': fileSize,
      'uploadDate': uploadDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory MedicalDocumentModel.fromMap(Map<String, dynamic> map) {
    return MedicalDocumentModel(
      id: map['id'] as String? ?? '',
      folderId: map['folderId'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Document',
      fileType: map['fileType'] as String? ?? 'pdf',
      filePath: map['filePath'] as String? ?? '',
      cloudUrl: map['cloudUrl'] as String?,
      fileSize: map['fileSize'] as int? ?? 0,
      uploadDate: map['uploadDate'] != null
          ? DateTime.tryParse(map['uploadDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes'] as String? ?? '',
    );
  }

  bool get isPdf => fileType.toLowerCase() == 'pdf';
  bool get isImage => fileType.toLowerCase() == 'image' || fileType.toLowerCase() == 'photo';

  String get formattedSize {
    if (fileSize <= 0) return 'Unknown size';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Returns true if filePath is a base64 string rather than a regular file path
  bool get isBase64 {
    return filePath.startsWith('data:') || (filePath.length > 500 && !filePath.contains('/') && !filePath.contains('\\'));
  }

  Uint8List? get base64Bytes {
    if (!isBase64) return null;
    try {
      String clean = filePath;
      if (clean.contains(',')) {
        clean = clean.split(',')[1];
      }
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }
}
