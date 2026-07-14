import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../services/health_vault_service.dart';
import 'folder_details_screen.dart';

class HealthVaultScreen extends StatefulWidget {
  const HealthVaultScreen({super.key});

  @override
  State<HealthVaultScreen> createState() => _HealthVaultScreenState();
}

class _HealthVaultScreenState extends State<HealthVaultScreen> {
  final HealthVaultService _service = HealthVaultService();
  List<FolderModel> _folders = [];
  List<MedicalDocumentModel> _allDocs = [];
  bool _loading = true;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Blue', 'hex': '#2A75D3', 'color': const Color(0xFF2A75D3)},
    {'name': 'Emerald', 'hex': '#10B981', 'color': const Color(0xFF10B981)},
    {'name': 'Amber', 'hex': '#F59E0B', 'color': const Color(0xFFF59E0B)},
    {'name': 'Purple', 'hex': '#8B5CF6', 'color': const Color(0xFF8B5CF6)},
    {'name': 'Teal', 'hex': '#14B8A6', 'color': const Color(0xFF14B8A6)},
    {'name': 'Rose', 'hex': '#F43F5E', 'color': const Color(0xFFF43F5E)},
    {'name': 'Indigo', 'hex': '#6366F1', 'color': const Color(0xFF6366F1)},
    {'name': 'Slate', 'hex': '#64748B', 'color': const Color(0xFF64748B)},
  ];

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'Folder', 'icon': Icons.folder},
    {'name': 'Prescription', 'icon': Icons.description},
    {'name': 'Lab Report', 'icon': Icons.biotech},
    {'name': 'Hospital / Clinic', 'icon': Icons.local_hospital},
    {'name': 'Insurance / ID', 'icon': Icons.security},
    {'name': 'Heart & Scans', 'icon': Icons.monitor_heart},
    {'name': 'Medicines', 'icon': Icons.medication},
    {'name': 'Family / Kids', 'icon': Icons.family_restroom},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final folders = await _service.getFolders();
    final docs = await _service.getDocuments();
    if (mounted) {
      setState(() {
        _folders = folders;
        _allDocs = docs;
        _loading = false;
      });
    }
  }

  int _getDocCount(String folderId) {
    return _allDocs.where((d) => d.folderId == folderId).length;
  }

  void _showCreateOrEditFolderDialog({FolderModel? existing}) {
    final TextEditingController nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedHex = existing?.colorHex ?? _colorOptions[0]['hex'] as String;
    int selectedIconPoint = existing?.iconCodePoint ?? Icons.folder.codePoint;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'Create New Folder' : 'Edit Folder', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Folder Name',
                    hintText: 'e.g. Cardiology Reports 2026',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(FolderModel.getIconData(selectedIconPoint), color: Color(int.parse('FF${selectedHex.replaceAll('#', '')}', radix: 16))),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Select Folder Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorOptions.map((opt) {
                    final color = opt['color'] as Color;
                    final hex = opt['hex'] as String;
                    final isSel = selectedHex == hex;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedHex = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.black, width: 3) : null,
                          boxShadow: isSel ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)] : [],
                        ),
                        child: isSel ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _iconOptions.map((opt) {
                    final icon = opt['icon'] as IconData;
                    final isSel = selectedIconPoint == icon.codePoint;
                    final color = Color(int.parse('FF${selectedHex.replaceAll('#', '')}', radix: 16));
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIconPoint = icon.codePoint),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSel ? color.withOpacity(0.15) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: isSel ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent),
                        ),
                        child: Icon(icon, color: isSel ? color : Colors.grey.shade700, size: 24),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                if (existing == null) {
                  await _service.createFolder(
                    name: nameCtrl.text.trim(),
                    iconCodePoint: selectedIconPoint,
                    colorHex: selectedHex,
                  );
                } else {
                  await _service.updateFolder(existing.copyWith(
                    name: nameCtrl.text.trim(),
                    iconCodePoint: selectedIconPoint,
                    colorHex: selectedHex,
                  ));
                }
                _loadData();
              },
              child: Text(existing == null ? 'Create Folder' : 'Save Changes', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFolders = _folders.where((f) {
      if (_searchQuery.isEmpty) return true;
      final matchFolder = f.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchDoc = _allDocs.any((d) => d.folderId == f.id && d.title.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchFolder || matchDoc;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Health Vault (Locker)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder, color: AppColors.primary),
            tooltip: 'New Folder',
            onPressed: () => _showCreateOrEditFolderDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrEditFolderDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Folder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Banner
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.folder_shared, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Your Medical Locker',
                                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_folders.length} Folders • ${_allDocs.length} Documents stored securely',
                                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Search Bar
                          TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search folders or document titles...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => setState(() => _searchQuery = ''))
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _searchQuery.isEmpty ? 'All Folders' : 'Search Results (${filteredFolders.length})',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              if (_searchQuery.isEmpty)
                                Text(
                                  'Tap folder to view or upload',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filteredFolders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No folders created yet.' : 'No folders or documents matching "$_searchQuery"',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.15,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final folder = filteredFolders[index];
                            final docCount = _getDocCount(folder.id);
                            final color = folder.color;

                            return InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => FolderDetailsScreen(folder: folder)),
                                );
                                _loadData();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(folder.iconData, color: color, size: 26),
                                        ),
                                        if (!folder.isDefault)
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                            onSelected: (val) async {
                                              if (val == 'edit') {
                                                _showCreateOrEditFolderDialog(existing: folder);
                                              } else if (val == 'delete') {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Delete Folder?'),
                                                    content: Text('Are you sure you want to delete "${folder.name}" and all $docCount documents stored inside?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await _service.deleteFolder(folder.id);
                                                  _loadData();
                                                }
                                              }
                                            },
                                            itemBuilder: (_) => [
                                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Rename')])),
                                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                                            ],
                                          ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          folder.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$docCount ${docCount == 1 ? 'document' : 'documents'}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: filteredFolders.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }
}
