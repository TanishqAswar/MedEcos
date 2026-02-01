import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/sidebar.dart';
import 'widgets/header.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          const SizedBox(width: 250, child: Sidebar()),
          // Main Content
          Expanded(
            child: Column(
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
                        // Stats Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                StatCard(title: "Appointments Today", value: "12", icon: Icons.calendar_today, color: Colors.blue),
                                StatCard(title: "Pending Reports", value: "5", icon: Icons.assignment_late, color: Colors.orange),
                                StatCard(title: "Total Patients", value: "1,240", icon: Icons.people, color: Colors.teal),
                                StatCard(title: "Weekly Engagement", value: "+12%", icon: Icons.trending_up, color: Colors.green),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Placeholder for Chart or other content
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text("Engagement Chart Placeholder", style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
