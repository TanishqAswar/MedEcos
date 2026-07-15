import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import '../utils/medicine_utils.dart';

class MedicineDose {
  final String medicineId; // Could be prescription ID + medicine Name
  final String medicineName;
  final String timingLabel; // e.g. "Morning", "Evening"
  final DateTime expectedTime;
  final String context; // e.g. "Before Food"
  final String instruction;
  final String durationLabel; // e.g. "5 Days course" or "Day 2 of 5"
  final String dosage;
  String status; // "PENDING", "TAKEN", "SKIPPED"

  MedicineDose({
    required this.medicineId,
    required this.medicineName,
    required this.timingLabel,
    required this.expectedTime,
    required this.context,
    required this.instruction,
    this.durationLabel = 'Ongoing course',
    this.dosage = '1 Unit',
    this.status = 'PENDING',
  });
}

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  Future<Map<String, dynamic>> _getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return {};
  }

  DateTime _parseTimeWithOffset(String timeString, String contextStr) {
    // timeString e.g. "08:00 AM"
    final now = DateTime.now();
    try {
      final format = DateFormat("hh:mm a");
      final parsedTime = format.parse(timeString);
      
      var expectedTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      
      // Apply offset
      final cLower = contextStr.toLowerCase();
      if (cLower.contains('before')) {
        expectedTime = expectedTime.subtract(const Duration(minutes: 30));
      } else if (cLower.contains('after')) {
        expectedTime = expectedTime.add(const Duration(minutes: 30));
      }
      return expectedTime;
    } catch (e) {
      return now;
    }
  }

  Future<List<MedicineDose>> getTodaysReminders() async {
    final profile = await _getProfile();
    final routine = profile['routine'] ?? {};
    
    final morningTime = routine['morning']?.toString() ?? '08:00 AM';
    final afternoonTime = routine['afternoon']?.toString() ?? '01:00 PM';
    final eveningTime = routine['evening']?.toString() ?? '05:00 PM';
    final nightTime = routine['night']?.toString() ?? '09:00 PM';

    final prefs = await SharedPreferences.getInstance();
    final localCustomJson = prefs.getString('custom_reminder_medicines');
    List<dynamic> localCustomMeds = [];
    if (localCustomJson != null) {
      try { localCustomMeds = jsonDecode(localCustomJson); } catch (_) {}
    }

    final localDelJson = prefs.getString('deleted_reminder_medicines');
    List<String> deletedReminders = [];
    if (localDelJson != null) {
      try {
        final List<dynamic> delList = jsonDecode(localDelJson);
        deletedReminders = delList.map((e) => e.toString().toLowerCase().trim()).toList();
      } catch (_) {}
    }
    final remoteDel = profile['deletedReminders'] as List<dynamic>? ?? [];
    for (var d in remoteDel) {
      final key = d.toString().toLowerCase().trim();
      if (!deletedReminders.contains(key)) deletedReminders.add(key);
    }

    final api = ApiService();
    await api.loadData();
    final prescriptions = api.prescriptions;

    List<MedicineDose> todayDoses = [];

    for (var p in prescriptions) {
      for (var med in p.medicines) {
        final name = med['name'] ?? 'Unknown';
        final duration = med['duration'] ?? '';
        final timing = med['timing'] ?? ''; // e.g. "Morning, Evening"
        final ctx = med['context'] ?? '';
        final inst = med['instruction'] ?? '';

        if (MedicineUtils.isActiveMedicine(p.date, duration)) {
          var timingsList = timing.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          
          if (timingsList.isEmpty) {
            final dosageStr = (med['frequency']?.isNotEmpty == true) ? med['frequency']! : (med['dosage'] ?? '');
            final parts = dosageStr.split('-');
            if (parts.isNotEmpty) {
              if (parts[0].trim() != '0' && parts[0].trim().isNotEmpty) timingsList.add('Morning');
              if (parts.length >= 2 && parts[1].trim() != '0' && parts[1].trim().isNotEmpty) timingsList.add('Afternoon');
              if (parts.length >= 3 && parts[2].trim() != '0' && parts[2].trim().isNotEmpty) timingsList.add('Evening');
              if (parts.length >= 4 && parts[3].trim() != '0' && parts[3].trim().isNotEmpty) timingsList.add('Night');
            } else {
              timingsList.add('Morning');
            }
          }
          
          for (var t in timingsList) {
            String baseTimeStr = morningTime;
            if (t.toLowerCase() == 'afternoon') baseTimeStr = afternoonTime;
            if (t.toLowerCase() == 'evening') baseTimeStr = eveningTime;
            if (t.toLowerCase() == 'night') baseTimeStr = nightTime;

            final expectedTime = _parseTimeWithOffset(baseTimeStr, ctx);
            
            todayDoses.add(MedicineDose(
              medicineId: "${p.id}_$name",
              medicineName: name,
              timingLabel: t,
              expectedTime: expectedTime,
              context: ctx,
              instruction: inst,
              durationLabel: duration.isNotEmpty ? duration : 'Ongoing course',
              dosage: med['dosage']?.toString() ?? med['frequency']?.toString() ?? '1 Unit',
            ));
          }
        }
      }
    }

    // Merge custom medicines from backend profile and local storage
    final remoteCustomMeds = profile['customMedicines'] as List<dynamic>? ?? [];
    final Map<String, Map<String, dynamic>> combinedCustom = {};
    for (var m in remoteCustomMeds) {
      if (m is Map) {
        final id = m['id']?.toString() ?? m['name']?.toString() ?? '';
        final nameKey = m['name']?.toString().toLowerCase().trim() ?? id;
        if (id.isNotEmpty) combinedCustom[nameKey] = Map<String, dynamic>.from(m);
      }
    }
    for (var m in localCustomMeds) {
      if (m is Map) {
        final id = m['id']?.toString() ?? m['name']?.toString() ?? '';
        final nameKey = m['name']?.toString().toLowerCase().trim() ?? id;
        if (id.isNotEmpty) combinedCustom[nameKey] = Map<String, dynamic>.from(m);
      }
    }

    final now = DateTime.now();
    final todayDay = DateTime(now.year, now.month, now.day);

    for (var c in combinedCustom.values) {
      final name = c['name']?.toString() ?? 'Unknown';
      final timing = c['timing']?.toString() ?? 'Morning';
      final ctx = c['context']?.toString() ?? 'After Food';
      final inst = c['instruction']?.toString() ?? '1 Unit';
      final id = c['id']?.toString() ?? "custom_$name";
      final durationDays = int.tryParse(c['durationDays']?.toString() ?? '0') ?? 0;
      final startStr = c['startDate']?.toString() ?? '';

      String durationLabel = 'Ongoing course';
      if (durationDays > 0 && startStr.isNotEmpty) {
        try {
          final startDt = DateTime.parse(startStr).toLocal();
          final startDay = DateTime(startDt.year, startDt.month, startDt.day);
          var diffDays = todayDay.difference(startDay).inDays;
          if (diffDays < 0 && todayDay.difference(startDay).inHours.abs() <= 48) {
            diffDays = 0; // Just added today or across timezone border
          }
          if (diffDays < 0 || diffDays >= durationDays) {
            continue; // Course expired or hasn't started yet
          }
          durationLabel = "Day ${diffDays + 1} of $durationDays";
        } catch (_) {
          durationLabel = "$durationDays Days course";
        }
      } else if (durationDays > 0) {
        durationLabel = "$durationDays Days course";
      }

      var timingsList = timing.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (timingsList.isEmpty) timingsList.add('Morning');

      for (var t in timingsList) {
        String baseTimeStr = morningTime;
        if (t.toLowerCase() == 'afternoon') baseTimeStr = afternoonTime;
        if (t.toLowerCase() == 'evening') baseTimeStr = eveningTime;
        if (t.toLowerCase() == 'night') baseTimeStr = nightTime;

        final expectedTime = _parseTimeWithOffset(baseTimeStr, ctx);

        todayDoses.add(MedicineDose(
          medicineId: id,
          medicineName: name,
          timingLabel: t,
          expectedTime: expectedTime,
          context: ctx,
          instruction: inst,
          durationLabel: durationLabel,
          dosage: c['dosage']?.toString() ?? '1 Unit',
        ));
      }
    }

    final activeCustomNames = combinedCustom.values
        .map((e) => e['name']?.toString().toLowerCase().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet();

    // Filter out deleted / removed reminders unless they are currently active custom medicines
    todayDoses = todayDoses.where((dose) {
      final nameKey = dose.medicineName.toLowerCase().trim();
      final idKey = dose.medicineId.toLowerCase().trim();
      if (activeCustomNames.contains(nameKey)) return true;
      return !deletedReminders.contains(nameKey) && !deletedReminders.contains(idKey);
    }).toList();

    // Now cross-reference with today's history
    final history = await api.getMedicineHistory();
    
    final todayStart = DateTime(now.year, now.month, now.day);
    
    for (var dose in todayDoses) {
      bool foundLog = false;
      for (var h in history) {
        if (h['medicineName'] == dose.medicineName) {
          final logTime = DateTime.parse(h['takenTime']).toLocal();
          if (logTime.year == todayStart.year && logTime.month == todayStart.month && logTime.day == todayStart.day) {
            final diff = logTime.difference(dose.expectedTime).inHours.abs();
            if (diff <= 4) {
               dose.status = h['status'] ?? 'TAKEN';
               foundLog = true;
               break;
            }
          }
        }
      }

      if (!foundLog) {
        if (now.isAfter(dose.expectedTime.add(const Duration(hours: 1)))) {
          dose.status = 'MISSED';
        }
      }
    }

    todayDoses.sort((a, b) {
       final statusWeightA = _getStatusWeight(a.status);
       final statusWeightB = _getStatusWeight(b.status);
       if (statusWeightA != statusWeightB) {
         return statusWeightA.compareTo(statusWeightB);
       }
       return a.expectedTime.compareTo(b.expectedTime);
    });

    return todayDoses;
  }

  int _getStatusWeight(String status) {
    switch (status) {
      case 'MISSED': return 0;
      case 'PENDING': return 1;
      default: return 2;
    }
  }

  Future<void> logDose(MedicineDose dose, String status) async {
    await ApiService().logMedicineHistory(dose.medicineId, dose.medicineName, dose.expectedTime, status);
  }

  Future<void> addCustomMedicine({
    required String name,
    required String timing,
    required String context,
    required String instruction,
    String dosage = '1 Unit',
    int durationDays = 0,
    String? startDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final localJson = prefs.getString('custom_reminder_medicines');
    List<dynamic> list = [];
    if (localJson != null) {
      try { list = jsonDecode(localJson); } catch (_) {}
    }
    final newMed = {
      'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
      'name': name.trim(),
      'timing': timing,
      'context': context,
      'instruction': instruction,
      'dosage': dosage,
      'durationDays': durationDays,
      'startDate': startDate ?? DateTime.now().toIso8601String(),
    };
    list.add(newMed);
    await prefs.setString('custom_reminder_medicines', jsonEncode(list));

    final localDelJson = prefs.getString('deleted_reminder_medicines');
    if (localDelJson != null) {
      try {
        List<dynamic> delList = jsonDecode(localDelJson);
        delList.removeWhere((e) => e.toString().toLowerCase().trim() == name.trim().toLowerCase());
        await prefs.setString('deleted_reminder_medicines', jsonEncode(delList));
      } catch (_) {}
    }

    try {
      final token = prefs.getString('jwt_token') ?? '';
      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/patient/medicines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(newMed),
      );
    } catch (_) {}
  }

  Future<void> updateReminderMedicine({
    required String medicineId,
    required String oldName,
    required String newName,
    required String timing,
    required String context,
    required String instruction,
    String dosage = '1 Unit',
    int durationDays = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final localJson = prefs.getString('custom_reminder_medicines');
    List<dynamic> list = [];
    if (localJson != null) {
      try { list = jsonDecode(localJson); } catch (_) {}
    }

    int index = list.indexWhere((m) => m['id'] == medicineId || (m['name']?.toString().toLowerCase().trim() == oldName.toLowerCase().trim()));
    if (index != -1) {
      list[index] = {
        'id': list[index]['id'] ?? medicineId,
        'name': newName.trim(),
        'timing': timing,
        'context': context,
        'instruction': instruction,
        'dosage': dosage,
        'durationDays': durationDays,
        'startDate': list[index]['startDate'] ?? DateTime.now().toIso8601String(),
      };
      await prefs.setString('custom_reminder_medicines', jsonEncode(list));
    } else {
      await deleteReminderMedicine(medicineId, oldName);
      await addCustomMedicine(
        name: newName,
        timing: timing,
        context: context,
        instruction: instruction,
        dosage: dosage,
        durationDays: durationDays,
      );
    }
  }

  Future<void> deleteReminderMedicine(String medicineId, String medicineName) async {
    final prefs = await SharedPreferences.getInstance();
    
    final localJson = prefs.getString('custom_reminder_medicines');
    if (localJson != null) {
      try {
        List<dynamic> list = jsonDecode(localJson);
        list.removeWhere((m) => m['id'] == medicineId || (m['name']?.toString().toLowerCase().trim() == medicineName.toLowerCase().trim()));
        await prefs.setString('custom_reminder_medicines', jsonEncode(list));
      } catch (_) {}
    }

    final localDelJson = prefs.getString('deleted_reminder_medicines');
    List<dynamic> delList = [];
    if (localDelJson != null) {
      try { delList = jsonDecode(localDelJson); } catch (_) {}
    }
    final nameKey = medicineName.toLowerCase().trim();
    if (!delList.contains(medicineId)) delList.add(medicineId);
    if (!delList.contains(nameKey)) delList.add(nameKey);
    await prefs.setString('deleted_reminder_medicines', jsonEncode(delList));

    try {
      final token = prefs.getString('jwt_token') ?? '';
      await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/patient/medicines/$medicineId?name=${Uri.encodeComponent(medicineName)}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
  }
}
