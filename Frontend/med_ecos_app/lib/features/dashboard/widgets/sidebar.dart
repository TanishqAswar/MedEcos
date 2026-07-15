import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';
import '../../support/screens/contact_us_screen.dart';
import '../../support/screens/about_us_screen.dart';
import '../../../core/services/api_service.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;
  final String userRole;
  final String userName;
  final VoidCallback? onClose;
  final bool isDesktop;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const Sidebar({
    super.key, 
    required this.onItemSelected, 
    required this.selectedIndex,
    required this.userRole,
    required this.userName,
    this.onClose,
    this.isDesktop = false,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final rolePrimary = AppColors.getPrimaryForRole(userRole);
    final roleLight = AppColors.getLightForRole(userRole);

    List<Widget> items = [];
    
    if (userRole == 'Patient') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.receipt_long, label: "Prescriptions", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.calendar_today, label: "Appointments", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.history, label: "History", isSelected: selectedIndex == 3, onTap: () => onItemSelected(3), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.science, label: "Lab Orders", isSelected: selectedIndex == 4, onTap: () => onItemSelected(4), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.folder, label: "Health Vault", isSelected: selectedIndex == 6, onTap: () => onItemSelected(6), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
      ];
    } else if (userRole == 'Doctor') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.assignment, label: "Prescriptions", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.people, label: "Patients", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.calendar_month, label: "Appointments", isSelected: selectedIndex == 3, onTap: () => onItemSelected(3), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.folder, label: "Health Vault", isSelected: selectedIndex == 5, onTap: () => onItemSelected(5), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
      ];
    } else if (userRole == 'Pharmacist') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.assignment, label: "Prescriptions", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.people, label: "Patients", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.inventory_2, label: "Inventory", isSelected: selectedIndex == 3, onTap: () => onItemSelected(3), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.point_of_sale, label: "Billing / POS", isSelected: selectedIndex == 4, onTap: () => onItemSelected(4), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.folder, label: "Health Vault", isSelected: selectedIndex == 6, onTap: () => onItemSelected(6), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
      ];
    } else if (userRole == 'Pathologist' || userRole == 'LabTester') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.people, label: "Patients", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.science, label: "Lab Orders", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
        _NavItem(icon: Icons.folder, label: "Health Vault", isSelected: selectedIndex == 4, onTap: () => onItemSelected(4), rolePrimary: rolePrimary, roleLight: roleLight, isCollapsed: isDesktop && isCollapsed),
      ];
    } else {
      items = [];
    }

    int profileIndex = 0;
    if (userRole == 'Patient') profileIndex = 5;
    else if (userRole == 'Doctor') profileIndex = 4;
    else if (userRole == 'Pharmacist') profileIndex = 5;
    else if (userRole == 'Pathologist' || userRole == 'LabTester') profileIndex = 3;
    final isProfileSelected = selectedIndex == profileIndex;

    // ─── 1. Desktop Collapsed Mini-Rail Mode ───
    if (isDesktop && isCollapsed) {
      return Container(
        width: 74,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              if (onToggleCollapse != null)
                IconButton(
                  icon: Icon(Icons.chevron_right, color: rolePrimary, size: 26),
                  onPressed: onToggleCollapse,
                  tooltip: 'Expand Sidebar',
                ),
              const SizedBox(height: 8),
              Tooltip(
                message: 'MedEcos — About Us',
                child: InkWell(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset("assets/Icon.jpeg", height: 36, width: 36, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                child: Divider(color: Colors.grey.shade200, height: 1),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: items,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Divider(color: Colors.grey.shade200, height: 1),
              ),
              const SizedBox(height: 12),
              Tooltip(
                message: '$userName ($userRole)',
                child: InkWell(
                  onTap: () => onItemSelected(profileIndex),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isProfileSelected ? rolePrimary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: roleLight,
                      child: Icon(Icons.person, color: rolePrimary, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Tooltip(
                message: 'Contact Us & FAQs',
                child: IconButton(
                  icon: const Icon(Icons.help_outline, color: AppColors.textSecondary, size: 22),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Tooltip(
                message: 'Logout',
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                  onPressed: () => _performLogout(context),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    // ─── 2. Desktop Expanded Mode ───
    if (isDesktop && !isCollapsed) {
      return Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Sleek Desktop Header with Logo, Title, and Collapse Toggle
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset("assets/Icon.jpeg", height: 44, width: 44, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "MedEcos",
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: rolePrimary,
                                          fontSize: 20,
                                        ),
                                  ),
                                  Text(
                                    "Connected Healthcare",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onToggleCollapse != null)
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: rolePrimary, size: 26),
                        onPressed: onToggleCollapse,
                        tooltip: 'Collapse Sidebar',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      ...items,
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(color: Colors.grey.shade200, height: 24),
                      ),
                      // Profile Card
                      InkWell(
                        onTap: () => onItemSelected(profileIndex),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isProfileSelected ? roleLight : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isProfileSelected ? rolePrimary.withOpacity(0.5) : Colors.grey.shade200,
                            ),
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
                      ),
                      const SizedBox(height: 8),
                      _NavItem(
                        icon: Icons.help_outline,
                        label: "Contact Us & FAQs",
                        isSelected: false,
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                          );
                        },
                        rolePrimary: rolePrimary,
                        roleLight: roleLight,
                      ),
                      const SizedBox(height: 2),
                      _NavItem(
                        icon: Icons.logout, 
                        label: "Logout", 
                        isSelected: false,
                        onTap: () => _performLogout(context),
                        rolePrimary: rolePrimary,
                        roleLight: roleLight,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ─── 3. Mobile Drawer Mode (Default) ───
    return Container(
      width: 280,
      color: Colors.white,
      child: SafeArea(
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
            // Logo Area (Clickable -> About Us)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (onClose != null) {
                    onClose!();
                  } else if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.of(context).pop();
                  }
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Column(
                    children: [
                      Image.asset("assets/Icon.jpeg", height: 65, width: 65, fit: BoxFit.contain),
                      const SizedBox(height: 8),
                      Text(
                        "MedEcos",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: rolePrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    ...items,
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => onItemSelected(profileIndex),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    ),
                    const SizedBox(height: 10),
                    _NavItem(
                      icon: Icons.help,
                      label: "Contact Us & FAQs",
                      isSelected: false,
                      onTap: () {
                        if (onClose != null) {
                          onClose!();
                        } else if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                          Navigator.of(context).pop();
                        }
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    _NavItem(
                      icon: Icons.logout, 
                      label: "Logout", 
                      isSelected: false,
                      onTap: () => _performLogout(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    ApiService().clearCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color rolePrimary;
  final Color roleLight;
  final bool isCollapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.rolePrimary = AppColors.primary,
    this.roleLight = AppColors.surfaceVariant,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Tooltip(
          message: label,
          preferBelow: false,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? roleLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? rolePrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? roleLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          dense: true,
          leading: Icon(
            icon,
            size: 22,
            color: isSelected ? rolePrimary : AppColors.textSecondary,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14,
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

