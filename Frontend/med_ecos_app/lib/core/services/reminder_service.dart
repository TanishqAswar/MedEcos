import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import '../utils/medicine_utils.dart';
import '../models/medicine_model.dart';

class MedicineDose {
  final String medicineId; // Could be prescription ID + medicine Name
  final String medicineName;
  final String timingLabel; // e.g. "Morning", "Evening"
  final DateTime expectedTime;
  final String context; // e.g. "Before Food"
  final String instruction;
  final String durationLabel; // e.g. "5 Days course" or "Day 2 of 5"
  final String dosage;
  final String frequencyType; // "DAILY", "WEEKLY", "AS_NEEDED"
  final List<String> selectedDays; // e.g. ["Mon", "Wed"]
  final String conditionTag; // e.g. "During Stress"
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
    this.frequencyType = 'DAILY',
    this.selectedDays = const [],
    this.conditionTag = '',
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

    // First collect active custom medicines so we can skip prescriptions that have been customized/overridden
    final remoteCustomMeds = profile['customMedicines'] as List<dynamic>? ?? [];
    final Map<String, Map<String, dynamic>> combinedCustom = {};
    for (var m in remoteCustomMeds) {
      if (m is Map) {
        final id = m['id']?.toString() ?? m['name']?.toString() ?? '';
        final nameKey = m['name']?.toString().toLowerCase().trim() ?? id;
        if (id.isNotEmpty && !deletedReminders.contains(id.toLowerCase()) && !deletedReminders.contains(nameKey)) {
          combinedCustom[nameKey] = Map<String, dynamic>.from(m);
        }
      }
    }
    for (var m in localCustomMeds) {
      if (m is Map) {
        final id = m['id']?.toString() ?? m['name']?.toString() ?? '';
        final nameKey = m['name']?.toString().toLowerCase().trim() ?? id;
        if (id.isNotEmpty && !deletedReminders.contains(id.toLowerCase()) && !deletedReminders.contains(nameKey)) {
          combinedCustom[nameKey] = Map<String, dynamic>.from(m);
        }
      }
    }

    for (var p in prescriptions) {
      for (var med in p.medicines) {
        final name = med['name'] ?? 'Unknown';
        final duration = med['duration'] ?? '';
        final timing = med['timing'] ?? ''; // e.g. "Morning, Evening"
        final ctx = med['context'] ?? '';
        final inst = med['instruction'] ?? '';

        if (MedicineUtils.isActiveMedicine(p.date, duration)) {
          final medIdKey = "${p.id}_$name".toLowerCase();
          final nameKey = name.toLowerCase().trim();
          if (deletedReminders.contains(medIdKey) || deletedReminders.contains(nameKey) || combinedCustom.containsKey(nameKey)) {
            continue;
          }
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

      final frequencyType = c['frequencyType']?.toString() ?? 'DAILY';
      final selectedDaysRaw = c['selectedDays'];
      List<String> selectedDays = [];
      if (selectedDaysRaw is List) {
        selectedDays = selectedDaysRaw.map((e) => e.toString()).toList();
      }
      final conditionTag = c['conditionTag']?.toString() ?? '';

      if (frequencyType == 'WEEKLY' && selectedDays.isNotEmpty) {
        const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final todayName = weekdayNames[todayDay.weekday - 1];
        if (!selectedDays.contains(todayName)) {
          continue;
        }
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
          frequencyType: frequencyType,
          selectedDays: selectedDays,
          conditionTag: conditionTag,
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

    await sortMedicineDoses(todayDoses);
    return todayDoses;
  }

  Future<void> sortMedicineDoses(List<MedicineDose> doses) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('medicine_sort_mode') ?? 'status';
    final customOrder = prefs.getStringList('medicine_custom_order') ?? [];

    doses.sort((a, b) {
      if ((mode == 'custom' || customOrder.isNotEmpty) && mode != 'name' && mode != 'time' && mode != 'status') {
        final indexA = customOrder.indexOf(a.medicineName.toLowerCase().trim());
        final indexB = customOrder.indexOf(b.medicineName.toLowerCase().trim());
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
      } else if (mode == 'name') {
        return a.medicineName.compareTo(b.medicineName);
      } else if (mode == 'time') {
        return a.expectedTime.compareTo(b.expectedTime);
      }
      // Default / fallback status weighting then time or custom index
      final statusWeightA = _getStatusWeight(a.status);
      final statusWeightB = _getStatusWeight(b.status);
      if (statusWeightA != statusWeightB) {
        return statusWeightA.compareTo(statusWeightB);
      }
      if (customOrder.isNotEmpty) {
        final indexA = customOrder.indexOf(a.medicineName.toLowerCase().trim());
        final indexB = customOrder.indexOf(b.medicineName.toLowerCase().trim());
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
      }
      return a.expectedTime.compareTo(b.expectedTime);
    });
  }

  Future<void> sortMedicineObjects(List<Medicine> meds) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('medicine_sort_mode') ?? 'custom';
    final customOrder = prefs.getStringList('medicine_custom_order') ?? [];

    meds.sort((a, b) {
      if ((mode == 'custom' || customOrder.isNotEmpty) && mode != 'name' && mode != 'time') {
        final indexA = customOrder.indexOf(a.name.toLowerCase().trim());
        final indexB = customOrder.indexOf(b.name.toLowerCase().trim());
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
      } else if (mode == 'name') {
        return a.name.compareTo(b.name);
      } else if (mode == 'time') {
        return a.startDate.compareTo(b.startDate);
      }
      return a.name.compareTo(b.name);
    });
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

  Future<List<Medicine>> getActiveCustomMedicineObjects() async {
    final prefs = await SharedPreferences.getInstance();
    final localJson = prefs.getString('custom_reminder_medicines');
    List<dynamic> localCustomMeds = [];
    if (localJson != null) {
      try { localCustomMeds = jsonDecode(localJson); } catch (_) {}
    }

    final localDelJson = prefs.getString('deleted_reminder_medicines');
    List<String> deletedReminders = [];
    if (localDelJson != null) {
      try {
        final delList = jsonDecode(localDelJson) as List<dynamic>;
        deletedReminders = delList.map((e) => e.toString().toLowerCase().trim()).toList();
      } catch (_) {}
    }

    final profile = await _getProfile();
    final remoteDel = profile['deletedReminders'] as List<dynamic>? ?? [];
    for (var d in remoteDel) {
      final key = d.toString().toLowerCase().trim();
      if (!deletedReminders.contains(key)) deletedReminders.add(key);
    }

    final remoteCustomMeds = profile['customMedicines'] as List<dynamic>? ?? [];
    final Map<String, Map<String, dynamic>> combinedCustom = {};
    for (var m in remoteCustomMeds) {
      if (m is Map) {
        final id = m['id']?.toString() ?? m['name']?.toString() ?? '';
        final nameKey = m['name']?.toString().toLowerCase().trim() ?? id;
        if (id.isNotEmpty && !deletedReminders.contains(id.toLowerCase()) && !deletedReminders.contains(nameKey)) {
          combinedCustom[nameKey] = Map<String, dynamic>.from(m);
        }
      }
    }
    for (var m in localCustomMeds) {
      if (m is Map) {
        final id = m['id']?.toString() ?? m['name']?.toString() ?? '';
        final nameKey = m['name']?.toString().toLowerCase().trim() ?? id;
        if (id.isNotEmpty && !deletedReminders.contains(id.toLowerCase()) && !deletedReminders.contains(nameKey)) {
          combinedCustom[nameKey] = Map<String, dynamic>.from(m);
        }
      }
    }

    List<Medicine> result = [];
    final now = DateTime.now();
    final todayDay = DateTime(now.year, now.month, now.day);

    for (var c in combinedCustom.values) {
      final name = c['name']?.toString() ?? 'Unknown';
      final id = c['id']?.toString() ?? "custom_$name";
      final timingStr = c['timing']?.toString() ?? 'Morning';
      final ctx = c['context']?.toString() ?? 'After Food';
      final durationDays = int.tryParse(c['durationDays']?.toString() ?? '0') ?? 0;
      final startStr = c['startDate']?.toString() ?? '';
      final dosage = c['dosage']?.toString() ?? '';

      DateTime startDate = DateTime.now();
      if (startStr.isNotEmpty) {
        try { startDate = DateTime.parse(startStr).toLocal(); } catch (_) {}
      }
      DateTime? endDate;
      String durText = 'Ongoing course';
      if (durationDays > 0) {
        endDate = startDate.add(Duration(days: durationDays));
        durText = '$durationDays Days course';
        final normalizedExp = DateTime(endDate.year, endDate.month, endDate.day);
        if (todayDay.compareTo(normalizedExp) > 0) {
          continue; // Expired course
        }
      }

      final dosageDisplay = dosage.isNotEmpty && dosage != '0' && dosage != 'None' ? dosage : '$timingStr • $ctx • $durText';

      result.add(Medicine(
        id: id,
        name: name,
        dosage: dosageDisplay,
        frequency: 1,
        timings: [],
        startDate: startDate,
        endDate: endDate,
        doctorName: 'My Reminders',
        prescriptionDate: DateFormat('MMM dd, yyyy').format(startDate),
        timingCategory: timingStr,
      ));
    }
    return result;
  }

  Future<void> addCustomMedicine({
    required String name,
    required String timing,
    required String context,
    required String instruction,
    String dosage = '1 Unit',
    int durationDays = 0,
    String? startDate,
    String frequencyType = 'DAILY',
    List<String> selectedDays = const [],
    String conditionTag = '',
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
      'frequencyType': frequencyType,
      'selectedDays': selectedDays,
      'conditionTag': conditionTag,
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
    String frequencyType = 'DAILY',
    List<String> selectedDays = const [],
    String conditionTag = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final localJson = prefs.getString('custom_reminder_medicines');
    List<dynamic> list = [];
    if (localJson != null) {
      try { list = jsonDecode(localJson); } catch (_) {}
    }

    int index = list.indexWhere((m) => m['id'] == medicineId || (m['name']?.toString().toLowerCase().trim() == oldName.toLowerCase().trim()));
    final newId = medicineId.startsWith('custom_') ? medicineId : 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final updatedData = {
      'id': index != -1 ? (list[index]['id'] ?? newId) : newId,
      'name': newName.trim(),
      'timing': timing,
      'context': context,
      'instruction': instruction,
      'dosage': dosage,
      'durationDays': durationDays,
      'startDate': index != -1 ? (list[index]['startDate'] ?? DateTime.now().toIso8601String()) : DateTime.now().toIso8601String(),
      'frequencyType': frequencyType,
      'selectedDays': selectedDays,
      'conditionTag': conditionTag,
    };

    if (index != -1) {
      list[index] = updatedData;
    } else {
      list.add(updatedData);
      final localDelJson = prefs.getString('deleted_reminder_medicines');
      List<dynamic> delList = [];
      if (localDelJson != null) {
        try { delList = jsonDecode(localDelJson); } catch (_) {}
      }
      if (!delList.contains(medicineId)) delList.add(medicineId);
      if (!delList.contains(oldName.toLowerCase().trim())) delList.add(oldName.toLowerCase().trim());
      await prefs.setString('deleted_reminder_medicines', jsonEncode(delList));
    }
    await prefs.setString('custom_reminder_medicines', jsonEncode(list));

    try {
      final token = prefs.getString('jwt_token') ?? '';
      await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/patient/medicines/$medicineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': newName.trim(),
          'oldName': oldName.trim(),
          'timing': timing,
          'context': context,
          'instruction': instruction,
          'dosage': dosage,
          'durationDays': durationDays,
          'frequencyType': frequencyType,
          'selectedDays': selectedDays,
          'conditionTag': conditionTag,
        }),
      );
    } catch (_) {}
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
