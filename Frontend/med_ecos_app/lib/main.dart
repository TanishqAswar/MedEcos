import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/updater/app_updater.dart';
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
  @override
  void initState() {
    super.initState();
    AppUpdater.checkForUpdate();
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
