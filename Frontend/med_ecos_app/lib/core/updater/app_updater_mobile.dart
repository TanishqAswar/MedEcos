import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class AppUpdater {
  static final _updater = ShorebirdCodePush();

  static Future<void> checkForUpdate() async {
    if (!kReleaseMode) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final isAvailable = _updater.isShorebirdAvailable();
      if (!isAvailable) return;

      await _updater.downloadUpdateIfAvailable();
    } catch (_) {
      // Network unavailable or update check failed — continue normally
    }
  }
}
