import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';

class HealthVaultService {
  static const String _foldersKey = 'health_vault_folders_v1';
  static const String _docsKey = 'health_vault_documents_v1';

  static final List<FolderModel> _defaultFolders = [
    FolderModel(
      id: 'f_prescriptions',
      name: 'Prescriptions & Doses',
      iconCodePoint: Icons.description.codePoint,
      colorHex: '#2A75D3',
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    FolderModel(
      id: 'f_labs',
      name: 'Lab Reports & Blood Tests',
      iconCodePoint: Icons.biotech.codePoint,
      colorHex: '#10B981',
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    FolderModel(
      id: 'f_bills',
      name: 'Discharge Summaries & Bills',
      iconCodePoint: Icons.local_hospital.codePoint,
      colorHex: '#F59E0B',
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    FolderModel(
      id: 'f_insurance',
      name: 'Insurance & ID Cards',
      iconCodePoint: Icons.security.codePoint,
      colorHex: '#8B5CF6',
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    FolderModel(
      id: 'f_personal',
      name: 'Personal & Miscellaneous',
      iconCodePoint: Icons.folder_special.codePoint,
      colorHex: '#64748B',
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  Future<List<FolderModel>> getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawFolders = prefs.getString(_foldersKey);

    if (rawFolders == null || rawFolders.isEmpty) {
      await _saveFolders(_defaultFolders);
      return _defaultFolders;
    }

    try {
      final List<dynamic> list = jsonDecode(rawFolders);
      final folders = list.map((m) => FolderModel.fromMap(m as Map<String, dynamic>)).toList();
      if (folders.isEmpty) {
        await _saveFolders(_defaultFolders);
        return _defaultFolders;
      }
      return folders;
    } catch (_) {
      await _saveFolders(_defaultFolders);
      return _defaultFolders;
    }
  }

  Future<void> _saveFolders(List<FolderModel> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(folders.map((f) => f.toMap()).toList());
    await prefs.setString(_foldersKey, raw);
  }

  Future<FolderModel> createFolder({
    required String name,
    required int iconCodePoint,
    required String colorHex,
  }) async {
    final folders = await getFolders();
    final newFolder = FolderModel(
      id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Custom Folder' : name.trim(),
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      isDefault: false,
      createdAt: DateTime.now(),
    );
    folders.add(newFolder);
    await _saveFolders(folders);
    return newFolder;
  }

  Future<FolderModel?> updateFolder(FolderModel updated) async {
    final folders = await getFolders();
    final index = folders.indexWhere((f) => f.id == updated.id);
    if (index != -1) {
      folders[index] = updated;
      await _saveFolders(folders);
      return updated;
    }
    return null;
  }

  Future<bool> deleteFolder(String folderId) async {
    final folders = await getFolders();
    final target = folders.firstWhere((f) => f.id == folderId, orElse: () => _defaultFolders[0]);
    if (target.isDefault) {
      return false; // Prevent deleting core defaults
    }
    folders.removeWhere((f) => f.id == folderId);
    await _saveFolders(folders);

    // Also delete documents inside this folder
    final docs = await getDocuments();
    final toKeep = docs.where((d) => d.folderId != folderId).toList();
    await _saveDocuments(toKeep);
    return true;
  }

  Future<List<MedicalDocumentModel>> getDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawDocs = prefs.getString(_docsKey);
    if (rawDocs == null || rawDocs.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(rawDocs);
      return list.map((m) => MedicalDocumentModel.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MedicalDocumentModel>> getDocumentsByFolder(String folderId) async {
    final allDocs = await getDocuments();
    return allDocs.where((d) => d.folderId == folderId).toList();
  }

  Future<void> _saveDocuments(List<MedicalDocumentModel> docs) async {
    final prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(docs.map((d) => d.toMap()).toList());
    await prefs.setString(_docsKey, raw);
  }

  Future<MedicalDocumentModel> addDocument({
    required String folderId,
    required String title,
    required String fileType,
    required String filePath,
    String? cloudUrl,
    required int fileSize,
    String notes = '',
  }) async {
    final docs = await getDocuments();
    final newDoc = MedicalDocumentModel(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      folderId: folderId,
      title: title.trim().isEmpty ? 'Medical Document' : title.trim(),
      fileType: fileType,
      filePath: filePath,
      cloudUrl: cloudUrl,
      fileSize: fileSize,
      uploadDate: DateTime.now(),
      notes: notes,
    );
    docs.insert(0, newDoc);
    await _saveDocuments(docs);
    return newDoc;
  }

  Future<bool> deleteDocument(String docId) async {
    final docs = await getDocuments();
    final doc = docs.firstWhere((d) => d.id == docId, orElse: () => MedicalDocumentModel(id: '', folderId: '', title: '', fileType: '', filePath: '', fileSize: 0, uploadDate: DateTime.now()));
    if (doc.id.isEmpty) return false;

    // Remove local file if it exists and is not base64
    if (!doc.isBase64 && doc.filePath.isNotEmpty) {
      try {
        final file = File(doc.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    docs.removeWhere((d) => d.id == docId);
    await _saveDocuments(docs);
    return true;
  }
}
