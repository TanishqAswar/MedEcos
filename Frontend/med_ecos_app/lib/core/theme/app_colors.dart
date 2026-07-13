import 'package:flutter/material.dart';

class AppColors {
  // Default / Patient (Green / Teal)
  static const Color primary = Color(0xFF009688); // Teal
  static const Color primaryLight = Color(0xFFB2DFDB);
  static const Color primaryDark = Color(0xFF00796B);
  static const Color accent = Color(0xFF26A69A);
  static const Color secondary = Color(0xFF26A69A);

  // 🌿 Patient Role Palette
  static const Color patientPrimary = Color(0xFF009688);
  static const Color patientLight = Color(0xFFE0F2F1);

  // 🩺 Doctor Role Palette (Clinical Royal Blue)
  static const Color doctorPrimary = Color(0xFF1565C0);
  static const Color doctorLight = Color(0xFFE3F2FD);

  // 💊 Pharmacist Role Palette (Pharmacy Violet / Indigo)
  static const Color pharmaPrimary = Color(0xFF6A1B9A);
  static const Color pharmaLight = Color(0xFFF3E5F5);

  // 🔬 Pathologist / Lab Tester Role Palette (Diagnostic Rose / Crimson)
  static const Color pathoPrimary = Color(0xFFC2185B);
  static const Color pathoLight = Color(0xFFFCE4EC);

  static const Color background = Color(0xFFF5F5F5); // Light Grey
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFE0F2F1); // Very light teal

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFFA000);

  /// Get the signature Primary color for a given user role
  static Color getPrimaryForRole(String? role) {
    if (role == null) return patientPrimary;
    switch (role.toLowerCase()) {
      case 'doctor':
        return doctorPrimary;
      case 'pharmacist':
      case 'pharma':
        return pharmaPrimary;
      case 'pathologist':
      case 'lab_tester':
      case 'labtester':
      case 'patho':
        return pathoPrimary;
      case 'patient':
      default:
        return patientPrimary;
    }
  }

  /// Get the soft light surface variant color for a given user role
  static Color getLightForRole(String? role) {
    if (role == null) return patientLight;
    switch (role.toLowerCase()) {
      case 'doctor':
        return doctorLight;
      case 'pharmacist':
      case 'pharma':
        return pharmaLight;
      case 'pathologist':
      case 'lab_tester':
      case 'labtester':
      case 'patho':
        return pathoLight;
      case 'patient':
      default:
        return patientLight;
    }
  }
}

