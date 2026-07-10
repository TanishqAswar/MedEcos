import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class AppUpdater {
  static final _updater = ShorebirdUpdater();

  static Future<void> checkForUpdate() async {
    if (!kReleaseMode) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final isAvailable = await _updater.isAvailable();
      if (!isAvailable) return;

      final status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await _updater.update();
      }
    } catch (_) {
      // Network unavailable or update check failed — continue normally
    }
  }
}
