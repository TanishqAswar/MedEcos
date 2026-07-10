import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/abha_formatter.dart';
import 'lab_tests_list_screen.dart';

class PathologistLookupScreen extends StatefulWidget {
  const PathologistLookupScreen({super.key});

  @override
  State<PathologistLookupScreen> createState() => _PathologistLookupScreenState();
}

class _PathologistLookupScreenState extends State<PathologistLookupScreen> {
  final TextEditingController _abhaController = TextEditingController();
  bool _isLoading = false;
  List<String> _mostVisited = [];

  @override
  void initState() {
    super.initState();
    _loadMostVisited();
  }

  Future<void> _loadMostVisited() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('pathologist_most_visited');
    if (jsonStr != null) {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final List<MapEntry<String, dynamic>> sorted = data.entries.toList()
        ..sort((a, b) => (b.value as int).compareTo(a.value as int));
      setState(() {
        _mostVisited = sorted.take(5).map((e) => e.key).toList();
      });
    }
  }

  Future<void> _recordVisit(String abhaId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('pathologist_most_visited');
    Map<String, dynamic> data = {};
    if (jsonStr != null) {
      data = jsonDecode(jsonStr);
    }
    data[abhaId] = (data[abhaId] ?? 0) + 1;
    await prefs.setString('pathologist_most_visited', jsonEncode(data));
    _loadMostVisited();
  }

  void _lookupPatient(String abhaId) {
    if (abhaId.isEmpty) return;
    
    // Format ABHA ID if needed (assuming they might type without dashes)
    String formattedAbha = abhaId;
    if (abhaId.length == 14 && !abhaId.contains('-')) {
      formattedAbha = "${abhaId.substring(0,4)}-${abhaId.substring(4,8)}-${abhaId.substring(8,12)}-${abhaId.substring(12,14)}";
    }

    _recordVisit(formattedAbha);

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => LabTestsListScreen(abhaId: formattedAbha)
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Patient Lookup",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Search for a patient using their ABHA ID to view their pending lab tests.",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isWide ? _buildWideLayout(context) : _buildMobileLayout(context),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: _buildSearchCard(context)),
        Expanded(flex: 1, child: _buildRecentList(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchCard(context),
          SizedBox(height: 400, child: _buildRecentList(context)),
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
                const SizedBox(height: 24),
                TextField(
                  controller: _abhaController,
                  inputFormatters: [AbhaInputFormatter()],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ABHA ID',
                    hintText: 'e.g. 1111-2222-3333-4444',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  onSubmitted: _lookupPatient,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _lookupPatient(_abhaController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Lookup Patient", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Most Visited Customers",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_mostVisited.isEmpty)
            const Text("No recent customers yet.", style: TextStyle(color: AppColors.textSecondary))
          else
            Expanded(
              child: ListView.separated(
                itemCount: _mostVisited.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final abhaId = _mostVisited[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text("ABHA: $abhaId", style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _lookupPatient(abhaId),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
