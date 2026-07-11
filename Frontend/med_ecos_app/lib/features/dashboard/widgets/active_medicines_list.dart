import 'package:flutter/material.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/theme/app_colors.dart';

class ActiveMedicinesList extends StatelessWidget {
  final List<Medicine> medicines;
  final Future<void> Function(Medicine)? onRemove;

  const ActiveMedicinesList({
    super.key,
    required this.medicines,
    this.onRemove,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Active Medicines", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            final med = medicines[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: const Icon(Icons.medication, color: AppColors.primary),
                ),
                title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (med.dosage.isNotEmpty)
                      Text(med.dosage, style: const TextStyle(fontSize: 13)),
                    if (med.endDate != null)
                      Text(
                        'Until: ${med.endDate!.day}/${med.endDate!.month}/${med.endDate!.year}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      )
                    else
                      const Text('Ongoing', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ],
                ),
                trailing: onRemove != null
                    ? IconButton(
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
                            await onRemove!(med);
                          }
                        },
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}
