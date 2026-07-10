import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/auth/login_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Silently ignore if .env is missing (e.g., in production where --dart-define is used)
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  runApp(MyApp(initialToken: token));
}

class MyApp extends StatefulWidget {
  final String? initialToken;

  const MyApp({super.key, this.initialToken});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _updater = ShorebirdUpdater();

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    // Only attempt OTA updates in release mode (Shorebird is a no-op in debug)
    if (!kReleaseMode) return;

    try {
      final status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        // Download silently in background; will apply on next cold start
        await _updater.update();
      }
    } catch (_) {
      // Network unavailable or update check failed — continue normally
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedEcos App',
      theme: AppTheme.lightTheme,
      home: widget.initialToken != null && widget.initialToken!.isNotEmpty
          ? const DashboardScreen()
          : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
