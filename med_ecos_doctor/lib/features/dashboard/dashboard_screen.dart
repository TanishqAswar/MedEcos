import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/sidebar.dart';
import 'widgets/header.dart';
import 'widgets/circular_stat_card.dart';
import 'widgets/donut_chart_widget.dart';
import 'widgets/today_appointments_widget.dart';
import 'widgets/next_patient_details_widget.dart';
import 'widgets/patient_review_widget.dart';
import 'widgets/appointment_requests_widget.dart';
import 'widgets/calendar_widget.dart';
import 'services/dashboard_data_service.dart';
import '../prescription/screens/prescription_list_screen.dart';
import '../patient/screens/patient_lookup_screen.dart';
import 'screens/appointments_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const PrescriptionListScreen();
      case 2:
        return const PatientLookupScreen();
      case 3:
        return const AppointmentsScreen();
      case 4:
        return const Center(child: Text("Settings Placeholder"));
      default:
        return const Center(child: Text("Coming Soon"));
    }
  }

  Widget _buildDashboardOverview() {
    return Column(
      children: [
        const Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dashboard",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 24),
                // Top Stat Cards Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        Expanded(
                          child: CircularStatCard(
                            title: "Total Patient",
                            value: "2000+",
                            subtitle: "Till Today",
                            icon: Icons.people,
                            iconBackgroundColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: CircularStatCard(
                            title: "Today Patient",
                            value: "068",
                            subtitle: "21 Dec-2021",
                            icon: Icons.people_outline,
                            iconBackgroundColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: CircularStatCard(
                            title: "Today Appintments",
                            value: "085",
                            subtitle: "21 Dec-2021",
                            icon: Icons.event_note,
                            iconBackgroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Main Dashboard Grid - 3 Columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column - Donut Chart & Patient Review
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          DonutChartWidget(
                            data: DashboardDataService.getPatientSummary(),
                          ),
                          const SizedBox(height: 24),
                          PatientReviewWidget(
                            reviews: DashboardDataService.getPatientReviews(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Middle Column - Today's Appointments & Requests
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          TodayAppointmentsWidget(
                            appointments: DashboardDataService.getTodayAppointments(),
                          ),
                          const SizedBox(height: 24),
                          AppointmentRequestsWidget(
                            requests: DashboardDataService.getAppointmentRequests(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column - Next Patient & Calendar
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          NextPatientDetailsWidget(
                            patient: DashboardDataService.getNextPatient(),
                          ),
                          const SizedBox(height: 24),
                          const CalendarWidget(),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 250, 
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          ),
          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}
