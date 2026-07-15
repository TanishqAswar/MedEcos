import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';

class ActiveMedicinesList extends StatelessWidget {
  final List<Medicine> medicines;
  final Future<void> Function(Medicine)? onRemove;
  final VoidCallback? onRearrange;

  const ActiveMedicinesList({
    super.key,
    required this.medicines,
    this.onRemove,
    this.onRearrange,
  });

  @override
  Widget build(BuildContext context) {
    if (medicines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Expanded(child: Text("No active medicines at the moment.", style: TextStyle(color: Colors.green))),
          ],
        ),
      );
    }

    // Group by Doctor Name
    final Map<String, List<Medicine>> grouped = {};
    for (var med in medicines) {
      final isCustom = med.doctorName.toLowerCase().contains('my reminders') || med.doctorName.toLowerCase().contains('personal') || med.doctorName.toLowerCase().contains('self');
      final key = isCustom ? 'My Reminders (Self Added)' : (med.doctorName.isNotEmpty ? AppConstants.formatDoctorName(med.doctorName) : 'Dr. Prescribed');
      grouped.putIfAbsent(key, () => []).add(med);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(child: Text("Active Medicines", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            if (onRearrange != null)
              TextButton.icon(
                onPressed: onRearrange,
                icon: const Icon(Icons.swap_vert, size: 18, color: AppColors.primary),
                label: const Text("Rearrange", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...grouped.entries.map((entry) {
          final doctorName = entry.key;
          final meds = entry.value;
          final dateStr = meds.first.prescriptionDate.isNotEmpty
              ? meds.first.prescriptionDate
              : '${meds.first.startDate.day}/${meds.first.startDate.month}/${meds.first.startDate.year}';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5FF), // Light blue container
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB3E5FC), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Tag & Date Tag Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(doctorName.contains('My Reminders') ? Icons.alarm : Icons.medical_services, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                doctorName.contains('My Reminders') ? 'Added by: You (Reminders)' : 'Prescribed by: $doctorName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: meds.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = meds.removeAt(oldIndex);
                    meds.insert(newIndex, item);

                    final prefs = await SharedPreferences.getInstance();
                    final customOrder = prefs.getStringList('medicine_custom_order') ?? [];
                    final draggedName = item.name.toLowerCase().trim();
                    customOrder.remove(draggedName);
                    if (newIndex < meds.length) {
                      final targetName = meds[newIndex].name.toLowerCase().trim();
                      final targetIdx = customOrder.indexOf(targetName);
                      if (targetIdx != -1) {
                        customOrder.insert(targetIdx, draggedName);
                      } else {
                        customOrder.add(draggedName);
                      }
                    } else {
                      customOrder.add(draggedName);
                    }
                    await prefs.setStringList('medicine_custom_order', customOrder);
                    await prefs.setString('medicine_sort_mode', 'custom');
                    if (onRearrange != null) {
                      onRearrange!();
                    }
                  },
                  itemBuilder: (ctx, idx) {
                    final med = meds[idx];
                    return Card(
                      key: ValueKey("${med.id}_$idx"),
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: const Icon(Icons.medication, color: AppColors.primary),
                        ),
                        title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  med.effectiveTiming,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  med.dosage.isNotEmpty ? med.dosage : '${med.frequency}x daily',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onRemove != null)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                tooltip: 'Remove from active',
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Remove Medicine'),
                                      content: Text('Remove "${med.name}" from your active medicines?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    onRemove!(med);
                                  }
                                },
                              ),
                            const Icon(Icons.drag_handle, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
