import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../patient/screens/patient_lookup_screen.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Area
          Image.asset("assets/Icon.jpeg", height: 80, width: 80),
          const SizedBox(height: 16),
          Text(
            "MedEcos",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 48),
          // Navigation Items
          _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: true),
          _NavItem(icon: Icons.calendar_month, label: "Appointments"),
          _NavItem(icon: Icons.people, label: "Patients"),
          _NavItem(icon: Icons.assignment, label: "Prescriptions"),
          _NavItem(icon: Icons.settings, label: "Settings"),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (label == "Patients" || label == "Prescriptions") {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientLookupScreen()));
          }
        },
      ),
    );
  }
}
