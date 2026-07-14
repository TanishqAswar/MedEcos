import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';
import '../../support/screens/contact_us_screen.dart';
import '../../../core/services/api_service.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;
  final String userRole;
  final String userName;
  final VoidCallback? onClose;

  const Sidebar({
    super.key, 
    required this.onItemSelected, 
    required this.selectedIndex,
    required this.userRole,
    required this.userName,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final rolePrimary = AppColors.getPrimaryForRole(userRole);
    final roleLight = AppColors.getLightForRole(userRole);

    List<Widget> items = [];
    
    if (userRole == 'Patient') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.receipt_long, label: "Prescriptions", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.calendar_today, label: "Appointments", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.history, label: "History", isSelected: selectedIndex == 3, onTap: () => onItemSelected(3), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.science, label: "Lab Orders", isSelected: selectedIndex == 4, onTap: () => onItemSelected(4), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.folder_shared, label: "Health Vault", isSelected: selectedIndex == 6, onTap: () => onItemSelected(6), rolePrimary: rolePrimary, roleLight: roleLight),
        const Spacer(),
      ];
    } else if (userRole == 'Doctor') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.assignment, label: "Prescriptions", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.people, label: "Patients", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.calendar_month, label: "Appointments", isSelected: selectedIndex == 3, onTap: () => onItemSelected(3), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.folder_shared, label: "Health Vault", isSelected: selectedIndex == 5, onTap: () => onItemSelected(5), rolePrimary: rolePrimary, roleLight: roleLight),
        const Spacer(),
      ];
    } else if (userRole == 'Pharmacist') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.assignment, label: "Prescriptions", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.people, label: "Patients", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.inventory_2, label: "Inventory", isSelected: selectedIndex == 3, onTap: () => onItemSelected(3), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.point_of_sale, label: "Billing / POS", isSelected: selectedIndex == 4, onTap: () => onItemSelected(4), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.folder_shared, label: "Health Vault", isSelected: selectedIndex == 6, onTap: () => onItemSelected(6), rolePrimary: rolePrimary, roleLight: roleLight),
        const Spacer(),
      ];
    } else if (userRole == 'Pathologist' || userRole == 'LabTester') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.people, label: "Patients", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.science_outlined, label: "Lab Orders", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2), rolePrimary: rolePrimary, roleLight: roleLight),
        _NavItem(icon: Icons.folder_shared, label: "Health Vault", isSelected: selectedIndex == 4, onTap: () => onItemSelected(4), rolePrimary: rolePrimary, roleLight: roleLight),
        const Spacer(),
      ];
    } else {
      items = [const Spacer()];
    }

    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Close button for drawer mode
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    tooltip: 'Close Menu',
                  ),
              ],
            ),
          ),
          // Logo Area
          Image.asset("assets/Icon.jpeg", height: 80, width: 80, fit: BoxFit.contain),
          const SizedBox(height: 16),
          Text(
            "MedEcos",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rolePrimary,
                ),
          ),
          const SizedBox(height: 48),
          
          ...items,
          
          Builder(
            builder: (context) {
              int profileIndex = 0;
              if (userRole == 'Patient') profileIndex = 5;
              else if (userRole == 'Doctor') profileIndex = 4;
              else if (userRole == 'Pharmacist') profileIndex = 5;
              else if (userRole == 'Pathologist' || userRole == 'LabTester') profileIndex = 3;
              
              final isProfileSelected = selectedIndex == profileIndex;

              return InkWell(
                onTap: () => onItemSelected(profileIndex),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isProfileSelected ? roleLight : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isProfileSelected ? rolePrimary.withOpacity(0.5) : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: roleLight,
                        child: Icon(Icons.person, color: rolePrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 14,
                                color: isProfileSelected ? rolePrimary : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userRole,
                              style: TextStyle(
                                color: isProfileSelected ? AppColors.primary.withOpacity(0.7) : AppColors.textSecondary, 
                                fontSize: 12
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 10),
          _NavItem(
            icon: Icons.help_outline,
            label: "Contact Us & FAQs",
            isSelected: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _NavItem(
            icon: Icons.logout, 
            label: "Logout", 
            isSelected: false,
            onTap: () async {
              ApiService().clearCache();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color rolePrimary;
  final Color roleLight;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.rolePrimary = AppColors.primary,
    this.roleLight = AppColors.surfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? roleLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? rolePrimary : AppColors.textSecondary,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? rolePrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
