import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'reminder_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Notification background tap payload: ${notificationResponse.payload}');
  if (notificationResponse.actionId == 'action_taken') {
    debugPrint('Dose marked as TAKEN via background action button');
  } else if (notificationResponse.actionId == 'action_snooze') {
    debugPrint('Dose snoozed via background action button');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  void _configureLocalTimezone() {
    tz.initializeTimeZones();
    try {
      final timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      try {
        final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
        String defaultLocation = 'UTC';
        if (offsetMinutes == 330) {
          defaultLocation = 'Asia/Kolkata';
        } else if (offsetMinutes == -300) {
          defaultLocation = 'America/New_York';
        } else if (offsetMinutes == -480) {
          defaultLocation = 'America/Los_Angeles';
        } else if (offsetMinutes == 0) {
          defaultLocation = 'UTC';
        }
        tz.setLocalLocation(tz.getLocation(defaultLocation));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    _configureLocalTimezone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification foreground tap: ${response.payload} actionId: ${response.actionId}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create custom high-priority notification channels on Android
    if (!kIsWeb && Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();

      // 1. Medicine Reminders Channel (Max Priority with Lights & Vibrations)
      const AndroidNotificationChannel medicineChannel = AndroidNotificationChannel(
        'med_ecos_urgent_reminders_channel',
        'Medicine Reminders',
        description: 'Scheduled alerts and dosage instructions with action buttons',
        importance: Importance.max,
        enableLights: true,
        enableVibration: true,
        ledColor: Color(0xFF009688),
      );

      // 2. Doctor Appointments Channel (High Priority)
      const AndroidNotificationChannel appointmentChannel = AndroidNotificationChannel(
        'med_ecos_appointments_channel',
        'Doctor Appointments',
        description: 'Upcoming consultations, telehealth links, and clinic schedules',
        importance: Importance.high,
        enableVibration: true,
      );

      // 3. Health Vault & Lab Reports Channel (Standard Priority)
      const AndroidNotificationChannel vaultChannel = AndroidNotificationChannel(
        'med_ecos_health_vault_channel',
        'Health Vault & Lab Reports',
        description: 'New prescriptions, CBC reports, and AI verification updates',
        importance: Importance.defaultImportance,
      );

      await androidImplementation?.createNotificationChannel(medicineChannel);
      await androidImplementation?.createNotificationChannel(appointmentChannel);
      await androidImplementation?.createNotificationChannel(vaultChannel);
    }

    _initialized = true;
  }

  /// Show an immediate test notification to verify sounds, vibration, and channels
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    await init();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'med_ecos_urgent_reminders_channel',
      'Medicine Reminders',
      channelDescription: 'Scheduled alerts and dosage instructions with action buttons',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF009688),
      enableLights: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_taken',
          '✅ Mark Taken',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'action_snooze',
          '💤 Snooze 15 Min',
          showsUserInterface: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      9999,
      '🔔 MedEcos Notifications Active!',
      'Your high-priority dosage reminders, actions, and sound alerts are working properly.',
      details,
      payload: 'test_notification_payload',
    );
  }

  /// Show an immediate notification (e.g. prescription issued or report ready)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'med_ecos_health_vault_channel',
    String channelName = 'Health Vault & Lab Reports',
    String? payload,
  }) async {
    if (kIsWeb) return;
    await init();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF009688),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule a local notification for a specific medicine dose with Action Buttons
  Future<void> scheduleMedicineReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool includeActions = true,
    String? payload,
  }) async {
    if (kIsWeb) return;
    await init();

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      return; // Do not schedule alarms in the past
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'med_ecos_urgent_reminders_channel',
      'Medicine Reminders',
      channelDescription: 'Scheduled alerts and dosage instructions with action buttons',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF009688),
      enableLights: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      actions: includeActions
          ? <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'action_taken',
                '✅ Mark Taken',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'action_snooze',
                '💤 Snooze 15 Min',
                showsUserInterface: true,
              ),
            ]
          : null,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      // Fallback if exact alarms are not permitted on certain devices
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (err) {
        debugPrint('Failed to schedule notification: $err');
      }
    }
  }

  /// Schedule Doctor Appointment reminders (30 minutes before and exact time)
  Future<void> scheduleAppointmentReminder({
    required int baseId,
    required String doctorName,
    required DateTime appointmentTime,
    String? clinicAddress,
  }) async {
    if (kIsWeb) return;
    await init();

    final now = DateTime.now();
    final thirtyMinBefore = appointmentTime.subtract(const Duration(minutes: 30));

    if (thirtyMinBefore.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        baseId,
        '⏰ Appointment in 30 Minutes: Dr. $doctorName',
        clinicAddress != null
            ? 'Get ready for your consultation at $clinicAddress.'
            : 'Your teleconsultation or clinic visit with Dr. $doctorName starts soon.',
        tz.TZDateTime.from(thirtyMinBefore, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'med_ecos_appointments_channel',
            'Doctor Appointments',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF009688),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (appointmentTime.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        baseId + 1,
        '🏥 Appointment Starting Now: Dr. $doctorName',
        'It is time for your scheduled consultation with Dr. $doctorName.',
        tz.TZDateTime.from(appointmentTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'med_ecos_appointments_channel',
            'Doctor Appointments',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF009688),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Synchronize and schedule alarms + follow-up escalation alerts for pending doses of the day
  Future<void> syncTodayReminders(List<MedicineDose> doses) async {
    if (kIsWeb) return;
    await init();

    await _notificationsPlugin.cancelAll();

    int notifId = 1000;
    for (final dose in doses) {
      if (dose.status == 'PENDING') {
        notifId++;
        final title = '⏰ Medicine Reminder: ${dose.medicineName}';
        final body = 'Time to take ${dose.medicineName} (${dose.timingLabel} • ${dose.context}). ${dose.instruction}';
        
        // 1. Primary dosage reminder at exact expectedTime with Action Buttons
        await scheduleMedicineReminder(
          id: notifId,
          title: title,
          body: body,
          scheduledTime: dose.expectedTime,
          includeActions: true,
          payload: 'dose_${dose.medicineName}_${dose.timingLabel}',
        );

        // 2. Escalation / Follow-up check-in 30 minutes later in case patient forgot
        final followUpTime = dose.expectedTime.add(const Duration(minutes: 30));
        if (followUpTime.isAfter(DateTime.now())) {
          await scheduleMedicineReminder(
            id: notifId + 5000,
            title: '⚠️ Missed Dose Check: ${dose.medicineName}',
            body: 'Did you take ${dose.medicineName}? Tap to mark as taken or snooze if postponed.',
            scheduledTime: followUpTime,
            includeActions: true,
            payload: 'followup_${dose.medicineName}_${dose.timingLabel}',
          );
        }
      }
    }
  }

  /// Snooze a reminder by 15 minutes with action buttons
  Future<void> snoozeMedicineReminder(MedicineDose dose, {int minutes = 15}) async {
    if (kIsWeb) return;
    await init();

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final notifId = 2000 + dose.medicineName.hashCode.abs() % 1000;
    final title = '⏰ Snoozed Reminder: ${dose.medicineName}';
    final body = 'Reminder to take ${dose.medicineName} (${dose.timingLabel} • ${dose.context}). ${dose.instruction}';

    await scheduleMedicineReminder(
      id: notifId,
      title: title,
      body: body,
      scheduledTime: snoozeTime,
      includeActions: true,
      payload: 'snoozed_${dose.medicineName}_${dose.timingLabel}',
    );
  }
}
