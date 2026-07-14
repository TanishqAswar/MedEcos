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

  IconData get iconData {
    return IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  }

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
