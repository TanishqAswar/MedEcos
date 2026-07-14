import 'package:flutter/material.dart';

class FolderModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final String colorHex;
  final bool isDefault;
  final DateTime createdAt;

  const FolderModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorHex,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Untitled Folder',
      iconCodePoint: map['iconCodePoint'] as int? ?? Icons.folder.codePoint,
      colorHex: map['colorHex'] as String? ?? '#2A75D3',
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Color get color {
    try {
      String hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF2A75D3);
    }
  }

  static IconData getIconData(int codePoint) {
    if (codePoint == Icons.folder.codePoint) return Icons.folder;
    if (codePoint == Icons.description.codePoint) return Icons.description;
    if (codePoint == Icons.biotech.codePoint) return Icons.biotech;
    if (codePoint == Icons.local_hospital.codePoint) return Icons.local_hospital;
    if (codePoint == Icons.security.codePoint) return Icons.security;
    if (codePoint == Icons.monitor_heart.codePoint) return Icons.monitor_heart;
    if (codePoint == Icons.medication.codePoint) return Icons.medication;
    if (codePoint == Icons.family_restroom.codePoint) return Icons.family_restroom;
    if (codePoint == Icons.folder_shared.codePoint) return Icons.folder_shared;
    if (codePoint == Icons.receipt_long.codePoint) return Icons.receipt_long;
    if (codePoint == Icons.healing.codePoint) return Icons.healing;
    if (codePoint == Icons.science.codePoint) return Icons.science;
    return Icons.folder;
  }

  IconData get iconData => getIconData(iconCodePoint);

  FolderModel copyWith({
    String? name,
    int? iconCodePoint,
    String? colorHex,
  }) {
    return FolderModel(
      id: id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault,
      createdAt: createdAt,
    );
  }
}
