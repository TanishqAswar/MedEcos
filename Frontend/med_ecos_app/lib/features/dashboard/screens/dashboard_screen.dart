import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/medicine_model.dart';
import '../../video_call/screens/video_call_screen.dart';
import '../widgets/chatbot_widget.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/utils/medicine_utils.dart';
import '../../../core/services/notification_service.dart';

// Common Widgets
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/stat_card.dart';
import '../widgets/active_medicines_list.dart';

// Patient Screens
import '../../../features/medicines/screens/medicine_list_screen.dart';
import '../../../features/history/screens/history_screen.dart';
import '../../../features/doctors/screens/doctors_map_screen.dart';
import '../../../features/lab_tests/screens/patient_lab_orders_screen.dart';
import '../../prescriptions/screens/prescriptions_screen.dart';
import '../../../features/profile/screens/profile_screen.dart' as patient_profile;
import '../../../features/appointments/screens/appointments_screen.dart' as patient_appointments;

// Doctor Screens
import '../../../features/prescription/screens/doctor_prescription_list_screen.dart' as doctor_prescription;
import '../../../features/patient_lookup/screens/doctor_patient_lookup_screen.dart' as doctor_patient_lookup;
import '../../../features/appointments/screens/doctor_appointments_screen.dart';
import '../../../features/profile/screens/doctor_profile_screen.dart' as doctor_profile;

// Pharmacist Screens
import '../../../features/prescription/screens/pharmacist_prescription_list_screen.dart' as pharmacist_prescription;
import '../../../features/patient_lookup/screens/pharmacist_patient_lookup_screen.dart' as pharmacist_patient_lookup;
import '../../../features/dashboard/screens/inventory_screen.dart';
import '../../../features/billing/screens/pharmacist_billing_screen.dart';
import '../../../features/profile/screens/pharmacist_profile_screen.dart' as pharmacist_profile;

// Pathologist Screens
import '../../../features/patient_lookup/screens/pathologist_lookup_screen.dart' as pathologist_lookup;
import '../../../features/profile/screens/pathologist_profile_screen.dart' as pathologist_profile;
import '../../../features/lab_tests/screens/lab_orders_screen.dart';
import '../../../features/lab_tests/screens/lab_locations_map_screen.dart';
import '../../../core/utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userRole = 'Patient';
  String _userName = '';
  int _selectedIndex = 0;
  bool _loading = true;
  bool _sidebarOpen = true;

  // Patient Stats
  List<Medicine> _medicines = [];
  List<String> _labTests = [];
  int _activeMedicines = 0;
  int _totalPrescriptions = 0;
  List<dynamic> _patientLabOrders = [];
  List<MedicineDose> _todayDoses = [];

  // Doctor & Pharmacist Stats
  int _prescriptionsToday = 0;
  int _pendingOrders = 0;
  int _totalCustomers = 0;

  @override
  void initState() {
    super.initState();
    _loadRoleAndData();
  }

  Future<void> _loadRoleAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'Patient';
    final name = prefs.getString('username') ?? 'User';
    setState(() {
      _userRole = role;
      _userName = name;
    });

    if (role == 'Patient') {
      await _fetchPatientData();
    } else {
      await _fetchProStats();
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchPatientData() async {
    try {
      final List<dynamic> prescriptions = await ApiService().getPrescriptions();
      List<String> parsedLabTests = [];
      Map<String, Medicine> mergedMedicines = {};
      List<Medicine> activeMeds = [];

      for (var p in prescriptions.reversed) {
        final prescribeDate = DateTime.parse(p['date']);
        if (p['medicines'] != null) {
          for (var m in p['medicines']) {
            if (m is Map) {
              final nameKey = m['name']?.toString().toLowerCase().trim() ?? 'unknown';
              final durationStr = m['duration']?.toString() ?? 'Ongoing';
              final dosageStr = [m['frequency'], m['timing'], m['dosage']].firstWhere((val) => val != null && val.toString().trim().isNotEmpty, orElse: () => '')?.toString() ?? '';
              
              int days = 0;
              bool ongoing = false;
              if (durationStr == 'Ongoing' || durationStr.isEmpty) {
                ongoing = true;
              } else {
                final parts = durationStr.split(' ');
                if (parts.length >= 2) {
                  final value = int.tryParse(parts[0]) ?? 0;
                  final unit = parts[1].toLowerCase();
                  if (unit.contains('day')) days = value;
                  else if (unit.contains('week')) days = value * 7;
                  else if (unit.contains('month')) days = value * 30;
                }
              }

              if (!mergedMedicines.containsKey(nameKey)) {
                mergedMedicines[nameKey] = Medicine(
                  id: m['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: m['name']?.toString() ?? 'Unknown',
                  dosage: dosageStr,
                  frequency: 1,
                  timings: [],
                  startDate: prescribeDate,
                  endDate: ongoing ? null : prescribeDate.add(Duration(days: days)),
                );
              } else {
                final existing = mergedMedicines[nameKey]!;
                DateTime newStartDate = existing.startDate;
                DateTime? newEndDate;

                if (ongoing || existing.endDate == null) {
                  newEndDate = null;
                } else {
                  if (existing.endDate!.isBefore(prescribeDate)) {
                    newStartDate = prescribeDate;
                    newEndDate = prescribeDate.add(Duration(days: days));
                  } else {
                    newEndDate = existing.endDate!.add(Duration(days: days));
                  }
                }
                
                mergedMedicines[nameKey] = Medicine(
                  id: existing.id,
                  name: existing.name,
                  dosage: dosageStr,
                  frequency: 1,
                  timings: [],
                  startDate: newStartDate,
                  endDate: newEndDate,
                );
              }
            }
          }
        }
        if (p['labTests'] != null) {
          for (var t in p['labTests']) {
            parsedLabTests.add(t.toString());
          }
        }
      }

      for (var med in mergedMedicines.values) {
        if (med.endDate == null) {
          activeMeds.add(med);
        } else {
          final now = DateTime.now();
          final normalizedNow = DateTime(now.year, now.month, now.day);
          final normalizedExp = DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day);
          if (normalizedNow.compareTo(normalizedExp) <= 0) {
            activeMeds.add(med);
          }
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final ordersRes = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/patient/lab-test-orders'),
        headers: {'Authorization': 'Bearer $token'},
      );
      List<dynamic> labOrders = [];
      if (ordersRes.statusCode == 200) {
        labOrders = jsonDecode(ordersRes.body);
      }

      final doses = await ReminderService().getTodaysReminders();

      final stats = await ApiService().getDashboardStats();
      if (mounted) {
        setState(() {
          _medicines = mergedMedicines.values.toList();
          _labTests = parsedLabTests;
          _activeMedicines = activeMeds.map((m) => m.name.toLowerCase().trim()).toSet().length;
          _totalPrescriptions = prescriptions.length;
          _patientLabOrders = labOrders;
          _todayDoses = doses;
        });
        
        // Schedule notifications for active medicines
        final notificationService = NotificationService();
        for (var med in activeMeds) {
          notificationService.scheduleMedicineReminders(med);
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _fetchProStats() async {
    try {
      await ApiService().loadData(); // Ensure patients and prescriptions are loaded
      final stats = await ApiService().getDashboardStats();
      if (mounted) {
        setState(() {
          _prescriptionsToday = stats['prescriptionsToday'] ?? stats['appointmentsToday'] ?? 0;
          _pendingOrders = stats['pendingOrders'] ?? stats['pendingReports'] ?? 0;
          _totalCustomers = stats['totalCustomers'] ?? stats['totalPatients'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching pro stats: $e');
    }
  }

  Future<void> _removeMedicine(Medicine med) async {
    try {
      await ReminderService().deleteReminderMedicine(med.id, med.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${med.name} removed from active medicines'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        _fetchPatientData();
      }
    } catch (e) {
      debugPrint('Error removing medicine: $e');
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildContent() {
    if (_userRole == 'Patient') {
      switch (_selectedIndex) {
        case 0: return _buildPatientDashboard();
        case 1: return const PrescriptionsScreen();
        case 2: return const patient_appointments.AppointmentsScreen();
        case 3: return const HistoryScreen();
        case 4: return const PatientLabOrdersScreen();
        case 5: return const patient_profile.ProfileScreen();
        default: return const Center(child: Text("Coming Soon"));
      }
    } else if (_userRole == 'Doctor') {
      switch (_selectedIndex) {
        case 0: return _buildProDashboard();
        case 1: return const doctor_prescription.PrescriptionListScreen();
        case 2: return const doctor_patient_lookup.PatientLookupScreen();
        case 3: return const AppointmentsScreen();
        case 4: return const doctor_profile.ProfileScreen();
        default: return const Center(child: Text("Coming Soon"));
      }
    } else if (_userRole == 'Pharmacist') {
      switch (_selectedIndex) {
        case 0: return _buildProDashboard();
        case 1: return const pharmacist_prescription.PrescriptionListScreen();
        case 2: return const pharmacist_patient_lookup.PatientLookupScreen();
        case 3: return const InventoryScreen();
        case 4: return const PharmacistBillingScreen();
        case 5: return const pharmacist_profile.ProfileScreen();
        default: return const Center(child: Text("Coming Soon"));
      }
    } else if (_userRole == 'Pathologist') {
      switch (_selectedIndex) {
        case 0: return _buildProDashboard();
        case 1: return const pathologist_lookup.PathologistLookupScreen();
        case 2: return const LabOrdersScreen();
        case 3: return const pathologist_profile.ProfileScreen();
        default: return const Center(child: Text("Coming Soon"));
      }
    }
    return const Center(child: Text("Unknown Role"));
  }

  Widget _buildPatientDashboard() {
    return Column(
      children: [
        const Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Patient Dashboard", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Wrap(
                              spacing: 24, runSpacing: 24,
                              children: [
                                StatCard(title: "Active Meds", value: _activeMedicines.toString(), icon: Icons.healing, color: Colors.teal, onTap: () => _onItemSelected(3)),
                                StatCard(title: "Prescriptions", value: _totalPrescriptions.toString(), icon: Icons.receipt_long, color: Colors.green, onTap: () => _onItemSelected(1)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildFindDoctorsCard(),
                                const SizedBox(height: 16),
                                _buildFindLabsCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Wrap(
                            spacing: 24, runSpacing: 24,
                            children: [
                              StatCard(title: "Active Meds", value: _activeMedicines.toString(), icon: Icons.healing, color: Colors.teal, onTap: () => _onItemSelected(1)),
                              StatCard(title: "Prescriptions", value: _totalPrescriptions.toString(), icon: Icons.receipt_long, color: Colors.green, onTap: () => _onItemSelected(1)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildFindDoctorsCard(),
                          const SizedBox(height: 16),
                          _buildFindLabsCard(),
                        ],
                      );
                    }
                  }
                ),
                const SizedBox(height: 32),
                _buildTodaysReminders(),
                const SizedBox(height: 32),
                ActiveMedicinesList(
                  medicines: _medicines.where((med) => 
                    med.endDate == null || med.endDate!.isAfter(DateTime.now().subtract(const Duration(days: 1)))
                  ).toList(),
                  onRemove: _removeMedicine,
                ),
                const SizedBox(height: 32),
                _buildPreviousMedicinesAndLabTests(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousMedicinesAndLabTests() {
    final previousMedicines = _medicines.where((med) => 
      med.endDate != null && med.endDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Previous Medicines & Lab Tests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (previousMedicines.isEmpty && _labTests.isEmpty)
          const Text("No previous history found.")
        else ...[
          if (previousMedicines.isNotEmpty) ...[
            const Text("Medicines", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...previousMedicines.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.medication, color: Colors.white)),
                title: Text(m.name),
                subtitle: Text("Dosage: ${m.dosage}"),
              ),
            )),
            const SizedBox(height: 16),
          ],
          if (_labTests.isNotEmpty || _patientLabOrders.isNotEmpty) ...[
            const Text("Lab Tests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            // Tests from prescriptions
            ..._labTests.toSet().map((t) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.science, color: Colors.white)),
                title: Text(t),
                subtitle: const Text('Prescribed'),
              ),
            )),
            // Tests booked by patient
            ..._patientLabOrders.map((order) {
              final status = order['status'] ?? 'Pending';
              Color statusColor = Colors.orange;
              if (status == 'In_Progress') statusColor = Colors.blue;
              if (status == 'Completed') statusColor = Colors.green;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.deepOrangeAccent, child: Icon(Icons.biotech, color: Colors.white)),
                  title: Text(order['testName'] ?? 'Unknown Test'),
                  subtitle: Text("Lab: ${order['pathologistId']?['username'] ?? 'Unknown'}"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Text(status.replaceAll('_', ' '), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              );
            }),
          ],
        ],
      ],
    );
  }

  Widget _buildFindDoctorsCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorsMapScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Nearby Doctors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Verified doctors near you on map',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindLabsCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LabLocationsMapScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.science, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Nearby Labs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Book lab tests at verified labs near you',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Medicine Reminders",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddMedicineReminderDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Medicine"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.document_scanner, color: AppColors.primary),
                  tooltip: 'Scan Prescription',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MedicineListScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: _fetchPatientData,
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        if (_todayDoses.isEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                  SizedBox(width: 16),
                  Text("No medicine reminders for today!", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _todayDoses.length,
          itemBuilder: (context, index) {
            final dose = _todayDoses[index];
            final timeStr = "${dose.expectedTime.hour > 12 ? dose.expectedTime.hour - 12 : (dose.expectedTime.hour == 0 ? 12 : dose.expectedTime.hour)}:${dose.expectedTime.minute.toString().padLeft(2, '0')} ${dose.expectedTime.hour >= 12 ? 'PM' : 'AM'}";
            
            Color statusColor = Colors.grey;
            IconData statusIcon = Icons.access_time;
            
            if (dose.status == 'MISSED') {
              statusColor = Colors.red;
              statusIcon = Icons.warning;
            } else if (dose.status == 'TAKEN') {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
            } else if (dose.status == 'SKIPPED') {
              statusColor = Colors.orange;
              statusIcon = Icons.cancel;
            } else {
              statusColor = Colors.blue;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dose.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("$timeStr • ${dose.timingLabel} • ${dose.context} • ${dose.durationLabel}", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          if (dose.instruction.isNotEmpty && dose.instruction != 'None')
                            Text("Note: ${dose.instruction}", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (dose.status == 'PENDING' || dose.status == 'MISSED')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              setState(() { dose.status = 'SKIPPED'; });
                              await ReminderService().logDose(dose, 'SKIPPED');
                              _fetchPatientData();
                            },
                            child: const Text('Skip', style: TextStyle(color: Colors.orange)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              setState(() { dose.status = 'TAKEN'; });
                              await ReminderService().logDose(dose, 'TAKEN');
                              _fetchPatientData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Take'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete reminder',
                            onPressed: () => _confirmDeleteReminder(dose),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dose.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete reminder',
                            onPressed: () => _confirmDeleteReminder(dose),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmDeleteReminder(MedicineDose dose) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Reminder'),
        content: Text('Remove "${dose.medicineName}" from your medicine reminders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ReminderService().deleteReminderMedicine(dose.medicineId, dose.medicineName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${dose.medicineName} from reminders')),
        );
        _fetchPatientData();
      }
    }
  }

  void _showAddMedicineReminderDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 Tablet');
    final instructionCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String selectedTiming = 'Morning';
    String selectedContext = 'After Food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Medicine Reminder',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name *',
                        hintText: 'e.g. Paracetamol 500mg, Vitamin D3',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medication),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dosageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        hintText: 'e.g. 1 Tablet, 10 ml',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration in Days (Optional)',
                        hintText: 'e.g. 5, 10 (Leave empty or 0 for ongoing course)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Timing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Morning', 'Afternoon', 'Evening', 'Night'].map((t) {
                        final isSel = selectedTiming == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSel,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          onSelected: (selected) {
                            if (selected) setModalState(() => selectedTiming = t);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Context', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['After Food', 'Before Food', 'With Food'].map((c) {
                        final isSel = selectedContext == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: isSel,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          onSelected: (selected) {
                            if (selected) setModalState(() => selectedContext = c);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: instructionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Special Instruction (Optional)',
                        hintText: 'e.g. Take with warm water',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please enter a medicine name')),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          await ReminderService().addCustomMedicine(
                            name: name,
                            timing: selectedTiming,
                            context: selectedContext,
                            instruction: instructionCtrl.text.trim(),
                            dosage: dosageCtrl.text.trim(),
                            durationDays: int.tryParse(durationCtrl.text.trim()) ?? 0,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Reminder for $name added successfully!')),
                            );
                            _fetchPatientData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProDashboard() {
    return Column(
      children: [
        const Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back, ${_userRole == 'Doctor' ? 'Dr. ' : ''}$_userName!",
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Here is your overview for today. You have $_prescriptionsToday prescriptions/appointments scheduled.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _userRole == 'Doctor' ? Icons.local_hospital : Icons.local_pharmacy,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Stats Grid
                Text("Key Metrics", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24, runSpacing: 24,
                  children: [
                    StatCard(title: "Prescriptions Today", value: _prescriptionsToday.toString(), icon: Icons.receipt_long, color: Colors.blueAccent, onTap: () => _onItemSelected(1)),
                    StatCard(title: "Pending Action", value: _pendingOrders.toString(), icon: Icons.pending_actions, color: Colors.deepOrangeAccent, onTap: () => _onItemSelected(3)),
                    StatCard(title: "Total Customers/Patients", value: _totalCustomers.toString(), icon: Icons.people_alt, color: Colors.teal, onTap: () => _onItemSelected(2)),
                  ],
                ),
                
                const SizedBox(height: 40),

                // Quick Actions
                Text("Quick Actions", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildQuickActionBtn(
                      icon: Icons.person_search,
                      label: "Lookup Patient",
                      color: Colors.indigoAccent,
                      onTap: () => _onItemSelected(2),
                    ),
                    const SizedBox(width: 16),
                    _buildQuickActionBtn(
                      icon: Icons.list_alt,
                      label: "View Schedule",
                      color: Colors.purpleAccent,
                      onTap: () => _onItemSelected(3),
                    ),
                    const SizedBox(width: 16),
                    if (_userRole == 'Pharmacist')
                      _buildQuickActionBtn(
                        icon: Icons.inventory,
                        label: "Manage Inventory",
                        color: Colors.green,
                        onTap: () => _onItemSelected(3),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final isWide = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Row(
            children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _sidebarOpen ? 250 : 0,
            child: _sidebarOpen
                ? Sidebar(
                    onItemSelected: _onItemSelected,
                    selectedIndex: _selectedIndex,
                    userRole: _userRole,
                    userName: _userName,
                    onClose: () => setState(() => _sidebarOpen = false),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Column(
              children: [
                // Top bar with hamburger icon when sidebar is closed
                if (!_sidebarOpen)
                  Container(
                    height: 56,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: AppColors.primary),
                          onPressed: () => setState(() => _sidebarOpen = true),
                          tooltip: 'Open Menu',
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MedEcos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
      ChatbotWidget(
        userRole: _userRole,
        userName: _userName,
      ),
    ],
  ),
);
}
}
