import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/medicine_model.dart';
import '../models/meal_time_model.dart';
import 'preferences_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final PreferencesService _prefs = PreferencesService();

  Future<void> scheduleMedicineReminders(Medicine medicine) async {
    final mealTimes = await _prefs.getAllMealTimes();

    int id = medicine.id.hashCode; // Simple ID generation

    for (var timing in medicine.timings) {
      MealTime mealTime;
      switch (timing.mealRef) {
        case MealType.breakfast:
          mealTime = mealTimes[PreferencesService.keyBreakfast]!;
          break;
        case MealType.lunch:
          mealTime = mealTimes[PreferencesService.keyLunch]!;
          break;
        case MealType.snack:
          mealTime = mealTimes[PreferencesService.keySnack]!;
          break;
        case MealType.dinner:
          mealTime = mealTimes[PreferencesService.keyDinner]!;
          break;
      }

      // Calculate notification time
      final now = DateTime.now();
      var scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        mealTime.hour,
        mealTime.minute,
      ).add(Duration(minutes: timing.offsetMinutes));

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id + timing.mealRef.index, // Unique ID per timing
        'Medicine Reminder',
        'Time to take ${medicine.name} (${medicine.dosage})',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine Reminders',
            channelDescription: 'Reminders to take your medicine',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    }
  }
  
  Future<void> cancelNotifications(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
