import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/medecos_loader.dart';

class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  State<AdminVerificationsScreen> createState() => _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _verifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentFilter = 'pending'; // 'pending', 'verified', 'rejected', 'all'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      const filters = ['pending', 'verified', 'rejected', 'all'];
      if (_tabController.index < filters.length) {
        setState(() {
          _currentFilter = filters[_tabController.index];
        });
        _fetchVerifications();
      }
    });
    _fetchVerifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchVerifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/admin/verifications?status=$_currentFilter'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _verifications = data;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch verification requests (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateVerificationStatus(String userId, String newStatus, {String? notes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      // Show loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: MedEcosLoader(size: 40)),
      );

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/admin/verify/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': newStatus,
          'notes': notes,
        }),
      );

      Navigator.pop(context); // Dismiss loader

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Status updated successfully'),
            backgroundColor: newStatus == 'verified' ? Colors.green : Colors.red,
          ),
        );
        _fetchVerifications();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['message'] ?? 'Update failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReviewModal(Map<String, dynamic> practitioner) {
    final aiVerification = practitioner['aiVerification'] ?? {};
    final humanVerification = practitioner['humanVerification'] ?? {};
    final docs = practitioner['verificationDocuments'] as List<dynamic>? ?? [];
    final role = practitioner['role'] ?? 'Practitioner';
    final TextEditingController notesController = TextEditingController(
      text: humanVerification['notes'] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.getPrimaryForRole(role).withOpacity(0.15),
              child: Icon(Icons.shield, color: AppColors.getPrimaryForRole(role)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(practitioner['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('$role Application Review', style: TextStyle(fontSize: 13, color: AppColors.getPrimaryForRole(role))),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact & Location info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(practitioner['email'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (practitioner['speciality'] != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.medical_services, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Speciality: ${practitioner['speciality']}', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ],
                      if (practitioner['address'] != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Address: ${practitioner['address']}', style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // AI Verification Assessment Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade300, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.teal, size: 22),
                          const SizedBox(width: 8),
                          const Text('Gemini AI Assessment Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: aiVerification['status'] == 'verified' ? Colors.green.shade100 : Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              aiVerification['status']?.toString().toUpperCase() ?? 'PENDING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: aiVerification['status'] == 'verified' ? Colors.green.shade800 : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Confidence Score:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                Text('${aiVerification['confidenceScore'] ?? 0}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Document Type Detected:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                Text(aiVerification['documentTypeDetected'] ?? 'License / Credentials', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('AI Notes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                      const SizedBox(height: 4),
                      Text(aiVerification['notes'] ?? 'No notes recorded.', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Uploaded Documents
                const Text('Uploaded Verification Documents:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (docs.isEmpty)
                  const Text('No documents uploaded online (seeded/legacy account or missing file).', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                else
                  ...docs.map((doc) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.description, color: Colors.blue),
                      title: Text(doc['originalName'] ?? 'Verification Document', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text('Uploaded: ${doc['uploadedAt']?.toString().split('T').first ?? 'Recent'}', style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.blue),
                        tooltip: 'View Document',
                        onPressed: () async {
                          final url = doc['url'];
                          if (url != null && url.toString().isNotEmpty) {
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                      ),
                    ),
                  )),
                const SizedBox(height: 18),

                // Human Admin Decision & Notes
                const Text('Human Admin Decision (Holds Higher Authority):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Admin Review Notes / Reason for Approval or Rejection',
                    hintText: 'e.g. Verified license against Medical Council directory. Approved.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateVerificationStatus(practitioner['_id'], 'rejected', notes: notesController.text.isNotEmpty ? notesController.text : 'Application rejected by Admin.');
            },
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            label: const Text('Reject Application', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateVerificationStatus(practitioner['_id'], 'verified', notes: notesController.text.isNotEmpty ? notesController.text : 'Application verified and approved by Admin.');
            },
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text('Approve & Verify (Activate)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header / Banner
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.adminPrimary, AppColors.adminPrimary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Practitioner Credential Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('AI + Human two-tier gate verification for Doctors, Pharmacists, and Pathologists', style: TextStyle(fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchVerifications,
                      tooltip: 'Refresh List',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Pending Review'),
                    Tab(text: 'Verified & Active'),
                    Tab(text: 'Rejected'),
                    Tab(text: 'All Practitioners'),
                  ],
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: MedEcosLoader())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _fetchVerifications, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _verifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('No practitioners found in "$_currentFilter" status.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: _verifications.length,
                            itemBuilder: (context, index) {
                              final p = _verifications[index];
                              final role = p['role'] ?? 'Practitioner';
                              final isVerified = p['isVerified'] == true;
                              final aiStatus = p['aiVerification']?['status'] ?? 'pending';
                              final humanStatus = p['humanVerification']?['status'] ?? (isVerified ? 'verified' : 'pending');
                              final aiScore = p['aiVerification']?['confidenceScore'] ?? 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Role Avatar
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: AppColors.getPrimaryForRole(role).withOpacity(0.15),
                                        child: Icon(
                                          role == 'Doctor'
                                              ? Icons.medical_services
                                              : role == 'Pharmacist'
                                                  ? Icons.local_pharmacy
                                                  : Icons.biotech,
                                          color: AppColors.getPrimaryForRole(role),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Basic Info
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(p['username'] ?? 'Practitioner', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.getPrimaryForRole(role).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(role, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getPrimaryForRole(role))),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(p['email'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                            if (p['speciality'] != null)
                                              Text('Speciality: ${p['speciality']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),

                                      // Status Badges
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            // AI Status Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: aiStatus == 'verified' ? Colors.teal.shade50 : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: aiStatus == 'verified' ? Colors.teal.shade300 : Colors.grey.shade400),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.auto_awesome, size: 14, color: Colors.teal),
                                                      const SizedBox(width: 4),
                                                      Text('AI: ${aiStatus.toString().toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                                                    ],
                                                  ),
                                                  Text('Score: $aiScore%', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Human Admin Status Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isVerified ? Colors.green.shade50 : humanStatus == 'rejected' ? Colors.red.shade50 : Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: isVerified ? Colors.green : humanStatus == 'rejected' ? Colors.red : Colors.amber.shade700),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(isVerified ? Icons.check_circle : humanStatus == 'rejected' ? Icons.cancel : Icons.hourglass_top, size: 14, color: isVerified ? Colors.green : humanStatus == 'rejected' ? Colors.red : Colors.amber.shade800),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isVerified ? 'ADMIN: VERIFIED' : 'ADMIN: ${humanStatus.toString().toUpperCase()}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: isVerified ? Colors.green.shade800 : humanStatus == 'rejected' ? Colors.red.shade800 : Colors.amber.shade900,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(isVerified ? 'Holds higher authority' : 'Pending review', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Review Button
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.adminPrimary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        ),
                                        onPressed: () => _showReviewModal(p),
                                        icon: const Icon(Icons.rate_review, color: Colors.white, size: 18),
                                        label: const Text('Review Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
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
