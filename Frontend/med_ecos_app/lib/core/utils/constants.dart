class AppConstants {
  // Use localhost for local development since the start_all.sh exposes the backend on port 5000.
  // Change to 'https://medecos-backend.onrender.com' for production deployments.
  static const String apiBaseUrl = 'https://medecos-backend.onrender.com';

  /// Ensures a doctor's name cleanly starts with exactly one 'Dr.' prefix
  /// and strips out redundant prefixes such as 'Dr. Dr.', 'Dr. Doctor', 'Doctor', etc.
  static String formatDoctorName(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty || rawName.trim().toLowerCase() == 'unknown') {
      return 'Dr. Unknown';
    }
    String clean = rawName.trim();
    while (true) {
      final lower = clean.toLowerCase();
      if (lower.startsWith('dr. ')) {
        clean = clean.substring(4).trim();
      } else if (lower.startsWith('dr ')) {
        clean = clean.substring(3).trim();
      } else if (lower.startsWith('dr.')) {
        clean = clean.substring(3).trim();
      } else if (lower.startsWith('doctor. ')) {
        clean = clean.substring(8).trim();
      } else if (lower.startsWith('doctor ')) {
        clean = clean.substring(7).trim();
      } else if (lower.startsWith('doctor.')) {
        clean = clean.substring(7).trim();
      } else {
        break;
      }
    }
    if (clean.isEmpty) return 'Dr. Unknown';
    return 'Dr. $clean';
  }
}
