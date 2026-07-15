import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/theme/app_colors.dart';

void showRearrangeMedicinesBottomSheet(BuildContext context, {required List<Medicine> medicines, required VoidCallback onUpdate}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RearrangeMedicinesSheet(medicines: medicines, onUpdate: onUpdate),
  );
}

class _RearrangeMedicinesSheet extends StatefulWidget {
  final List<Medicine> medicines;
  final VoidCallback onUpdate;

  const _RearrangeMedicinesSheet({required this.medicines, required this.onUpdate});

  @override
  State<_RearrangeMedicinesSheet> createState() => _RearrangeMedicinesSheetState();
}

class _RearrangeMedicinesSheetState extends State<_RearrangeMedicinesSheet> {
  String _sortMode = 'custom';
  List<Medicine> _currentList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStateAndSort();
  }

  Future<void> _loadStateAndSort() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('medicine_sort_mode') ?? 'custom';
    final customOrder = prefs.getStringList('medicine_custom_order') ?? [];

    // Make unique by name
    final Map<String, Medicine> uniqueMap = {};
    for (var m in widget.medicines) {
      final key = m.name.toLowerCase().trim();
      uniqueMap.putIfAbsent(key, () => m);
    }
    List<Medicine> list = uniqueMap.values.toList();

    _applySortToList(list, mode, customOrder);

    if (mounted) {
      setState(() {
        _sortMode = mode;
        _currentList = list;
        _loading = false;
      });
    }
  }

  void _applySortToList(List<Medicine> list, String mode, List<String> customOrder) {
    list.sort((a, b) {
      if (mode == 'custom' && customOrder.isNotEmpty) {
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

  void _onModeChanged(String mode) {
    setState(() {
      _sortMode = mode;
      if (mode != 'custom') {
        _applySortToList(_currentList, mode, []);
      }
    });
  }

  Future<void> _saveOrderAndClose() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medicine_sort_mode', _sortMode);
    final namesOrder = _currentList.map((m) => m.name.toLowerCase().trim()).toList();
    await prefs.setStringList('medicine_custom_order', namesOrder);
    if (mounted) {
      Navigator.pop(context);
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.swap_vert, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    "Rearrange Medicine Order",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Choose a sorting mode or drag & drop items to customize the order across your reminders and active medicines list.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip("🔀 Drag & Drop (Custom)", 'custom'),
                const SizedBox(width: 8),
                _buildSortChip("⏰ By Date / Time", 'time'),
                const SizedBox(width: 8),
                _buildSortChip("🔤 By Name (A-Z)", 'name'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_currentList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  "No active medicines available to reorder.",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            )
          else
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _currentList.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = _currentList.removeAt(oldIndex);
                    _currentList.insert(newIndex, item);
                    _sortMode = 'custom'; // Automatically activate custom order mode on drag
                  });
                },
                itemBuilder: (ctx, index) {
                  final med = _currentList[index];
                  final isCustom = med.doctorName.toLowerCase().contains('my reminders') || med.doctorName.toLowerCase().contains('personal') || med.doctorName.toLowerCase().contains('self');
                  return Card(
                    key: ValueKey(med.id + index.toString()),
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isCustom ? Colors.blue.shade200 : Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: isCustom ? Colors.blue.shade50 : AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          isCustom ? Icons.alarm : Icons.medication,
                          color: isCustom ? Colors.blue.shade700 : AppColors.primary,
                        ),
                      ),
                      title: Text(
                        med.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            isCustom ? 'Added by: You (Reminders)' : 'Prescribed by: ${med.doctorName}',
                            style: TextStyle(fontSize: 12.5, color: isCustom ? Colors.blue.shade700 : AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          if (med.dosage.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              med.dosage,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "#${index + 1}",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.drag_handle, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('medicine_sort_mode');
                    await prefs.remove('medicine_custom_order');
                    _loadStateAndSort();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Reset Default", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saveOrderAndClose,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Save & Apply Order", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortMode == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelColor: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
      checkmarkColor: AppColors.primary,
      onSelected: (_) => _onModeChanged(value),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
      ),
    );
  }
}
