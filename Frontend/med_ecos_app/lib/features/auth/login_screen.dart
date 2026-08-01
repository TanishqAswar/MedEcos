import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/screens/dashboard_screen.dart';
import 'signup_screen.dart';
import '../support/screens/about_us_screen.dart';
import '../../../core/utils/abha_formatter.dart';
import '../../core/utils/constants.dart';
import '../../core/widgets/medecos_loader.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────
//  LoginScreen
// ─────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── controllers ──────────────────────────────────────────────
  final _abhaController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── state ─────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  String? _transactionId;
  String? _emailTransactionId;
  bool _obscurePassword = true;
  bool _useEmailOtp = false;

  /// null  → patient landing (shows ABHA / email choice)
  /// 'abha' → patient ABHA flow
  /// 'email' → patient email flow
  /// 'Doctor' / 'Pharmacist' / 'Pathologist' → pro email flow
  String? _activeFlow;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _abhaController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────
  Color get _accentColor {
    switch (_activeFlow) {
      case 'Doctor':
        return AppColors.doctorPrimary;
      case 'Pharmacist':
        return AppColors.pharmaPrimary;
      case 'Pathologist':
        return AppColors.pathoPrimary;
      default:
        return AppColors.patientPrimary;
    }
  }

  Color get _accentLight {
    switch (_activeFlow) {
      case 'Doctor':
        return AppColors.doctorLight;
      case 'Pharmacist':
        return AppColors.pharmaLight;
      case 'Pathologist':
        return AppColors.pathoLight;
      default:
        return AppColors.patientLight;
    }
  }

  void _switchFlow(String? flow) {
    _fadeCtrl.forward(from: 0);
    setState(() {
      _activeFlow = flow;
      _errorMessage = null;
      _transactionId = null;
      _emailTransactionId = null;
      _useEmailOtp = false;
      _otpController.clear();
    });
  }

  // ── ABHA login ────────────────────────────────────────────────
  Future<void> _generateOtp() async {
    if (_abhaController.text.isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/abha/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'abhaId': _abhaController.text}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() => _transactionId = data['transactionId']);
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Failed to generate OTP');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _transactionId == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/abha/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'abhaId': _abhaController.text,
          'transactionId': _transactionId,
          'otp': _otpController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveAndNavigate(data, role: 'Patient');
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Email / Password login ────────────────────────────────────
  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() => _errorMessage = 'Invalid email format');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveAndNavigate(data, role: _activeFlow ?? 'Patient');
      } else if (response.statusCode == 403) {
        _showVerificationPendingDialog(data);
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Email OTP login ───────────────────────────────────────────
  Future<void> _generateEmailOtp() async {
    if (_emailController.text.isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/email/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text, 'purpose': 'Login Verification'}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() => _emailTransactionId = data['transactionId']);
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    if (_otpController.text.isEmpty || _emailTransactionId == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/email/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'transactionId': _emailTransactionId,
          'otp': _otpController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['isNewUser'] == true) {
          if (mounted) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
          }
          return;
        }
        await _saveAndNavigate(data, role: _activeFlow ?? 'Patient');
      } else if (response.statusCode == 403) {
        _showVerificationPendingDialog(data);
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Invalid verification code');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── shared helpers ────────────────────────────────────────────
  Future<void> _saveAndNavigate(Map<String, dynamic> data, {required String role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', data['token'] ?? '');
    await prefs.setString('user_id', data['_id'] ?? '');
    await prefs.setString('user_role', data['role'] ?? role);
    await prefs.setString('username', data['username'] ?? 'User');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _showVerificationPendingDialog(Map<String, dynamic> data) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.pending_actions, color: Colors.amber, size: 28),
          SizedBox(width: 10),
          Expanded(child: Text('Verification Pending',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['message'] ?? 'Your account verification is currently pending review.',
                style: TextStyle(color: Colors.grey.shade800)),
            if (data['verificationStatus'] != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Check: ${data['verificationStatus']['aiStatus']?.toString().toUpperCase() ?? 'COMPLETED'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Notes: ${data['verificationStatus']['aiNotes'] ?? 'Document analyzed.'}',
                        style: const TextStyle(fontSize: 12)),
                    const Divider(height: 16),
                    Text('Human Admin Review: ${data['verificationStatus']['humanStatus']?.toString().toUpperCase() ?? 'PENDING'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Note: Human Admin verification holds the highest value. You will receive full access once an Admin approves your credentials.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Understood', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _activeFlow != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => _switchFlow(null),
                color: _accentColor,
              )
            : null,
        title: InkWell(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AboutUsScreen())),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset('assets/Icon.jpeg', height: 30, width: 30),
                ),
                const SizedBox(width: 10),
                Text(
                  'MedEcos',
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _activeFlow == null
                  ? _buildLanding()
                  : _buildLoginFlow(),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  LANDING PAGE
  // ─────────────────────────────────────────────────────────────
  Widget _buildLanding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),

        // ── Hero ──────────────────────────────────────────────
        Center(
          child: InkWell(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutUsScreen())),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.patientPrimary.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('assets/Icon.jpeg', fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Welcome to MedEcos',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A3C34),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your integrated healthcare companion',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),

        // ── Patient section ───────────────────────────────────
        _sectionLabel('👤  Sign in as Patient'),
        const SizedBox(height: 12),

        _patientLoginCard(
          icon: Icons.credit_card_rounded,
          title: 'Login with ABHA ID',
          subtitle: 'Use your Ayushman Bharat Health Account',
          color: AppColors.patientPrimary,
          bgColor: AppColors.patientLight,
          onTap: () => _switchFlow('abha'),
        ),
        const SizedBox(height: 10),
        _patientLoginCard(
          icon: Icons.email_rounded,
          title: 'Login with Email',
          subtitle: 'Use your registered email & password or OTP',
          color: const Color(0xFF00897B),
          bgColor: const Color(0xFFE0F2F1),
          onTap: () => _switchFlow('email'),
        ),
        const SizedBox(height: 36),

        // ── Divider ───────────────────────────────────────────
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Healthcare Professionals',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 16),

        // ── Profession buttons ────────────────────────────────
        Row(children: [
          Expanded(
            child: _professionButton(
              role: 'Doctor',
              icon: Icons.local_hospital_rounded,
              color: AppColors.doctorPrimary,
              bgColor: AppColors.doctorLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _professionButton(
              role: 'Pharmacist',
              icon: Icons.medication_rounded,
              color: AppColors.pharmaPrimary,
              bgColor: AppColors.pharmaLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _professionButton(
              role: 'Pathologist',
              icon: Icons.biotech_rounded,
              color: AppColors.pathoPrimary,
              bgColor: AppColors.pathoLight,
            ),
          ),
        ]),
        const SizedBox(height: 36),

        // ── Sign-up link ──────────────────────────────────────
        Center(
          child: TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SignupScreen())),
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                        color: AppColors.patientPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF455A64),
              letterSpacing: 0.3),
        ),
      );

  Widget _patientLoginCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 15, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _professionButton({
    required String role,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _switchFlow(role),
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(role,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  LOGIN FLOW (after choosing a role/method)
  // ─────────────────────────────────────────────────────────────
  Widget _buildLoginFlow() {
    final isPro = (_activeFlow == 'Doctor' ||
        _activeFlow == 'Pharmacist' ||
        _activeFlow == 'Pathologist');
    final isAbha = _activeFlow == 'abha';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        // ── Header card ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentColor, _accentColor.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: _accentColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(_flowIcon(), color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_flowTitle(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(_flowSubtitle(),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Form body ─────────────────────────────────────────
        if (isAbha)
          _buildAbhaFlow()
        else if (isPro || _activeFlow == 'email')
          _buildEmailFlow(isPro: isPro),

        const SizedBox(height: 20),

        // ── Sign-up link ──────────────────────────────────────
        Center(
          child: TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SignupScreen())),
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                children: [
                  TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  IconData _flowIcon() {
    switch (_activeFlow) {
      case 'abha':
        return Icons.credit_card_rounded;
      case 'Doctor':
        return Icons.local_hospital_rounded;
      case 'Pharmacist':
        return Icons.medication_rounded;
      case 'Pathologist':
        return Icons.biotech_rounded;
      default:
        return Icons.email_rounded;
    }
  }

  String _flowTitle() {
    switch (_activeFlow) {
      case 'abha':
        return 'Patient — ABHA Login';
      case 'email':
        return 'Patient — Email Login';
      case 'Doctor':
        return 'Doctor Login';
      case 'Pharmacist':
        return 'Pharmacist Login';
      case 'Pathologist':
        return 'Pathologist Login';
      default:
        return 'Login';
    }
  }

  String _flowSubtitle() {
    switch (_activeFlow) {
      case 'abha':
        return 'Enter your 14-digit ABHA ID to receive OTP';
      case 'email':
        return 'Use your registered email to sign in';
      case 'Doctor':
      case 'Pharmacist':
      case 'Pathologist':
        return 'Professional portal — verified access only';
      default:
        return '';
    }
  }

  // ── ABHA flow ─────────────────────────────────────────────────
  Widget _buildAbhaFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_transactionId == null) ...[
          _styledTextField(
            controller: _abhaController,
            label: 'ABHA ID (e.g. 1111-2222-3333-4444)',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [AbhaInputFormatter()],
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _errorWidget(),
          _primaryButton(
            label: 'Send OTP',
            icon: Icons.send_rounded,
            onPressed: _isLoading ? null : _generateOtp,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.patientLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.patientPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'OTP sent for ABHA ID: ${_abhaController.text}',
                    style: const TextStyle(
                        color: AppColors.patientPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _styledTextField(
            controller: _otpController,
            label: 'Enter OTP',
            icon: Icons.lock_outline_rounded,
            keyboardType: TextInputType.number,
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _errorWidget(),
          _primaryButton(
            label: 'Verify & Login',
            icon: Icons.verified_user_rounded,
            onPressed: _isLoading ? null : _verifyOtp,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _transactionId = null;
                _otpController.clear();
              }),
              child: const Text('← Change ABHA ID'),
            ),
          ),
        ],
      ],
    );
  }

  // ── Email flow ────────────────────────────────────────────────
  Widget _buildEmailFlow({required bool isPro}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _styledTextField(
          controller: _emailController,
          label: '${isPro ? (_activeFlow ?? 'Professional') : 'Patient'} Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          accentColor: _accentColor,
        ),
        const SizedBox(height: 14),

        if (!_useEmailOtp) ...[
          _styledTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            accentColor: _accentColor,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _accentColor,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 20),
          _errorWidget(),
          _primaryButton(
            label: 'Login',
            icon: Icons.login_rounded,
            onPressed: _isLoading ? null : _loginWithEmail,
          ),
        ] else ...[
          if (_emailTransactionId == null) ...[
            const SizedBox(height: 8),
            _errorWidget(),
            _primaryButton(
              label: 'Send Verification Code',
              icon: Icons.mark_email_read_rounded,
              onPressed: _isLoading ? null : _generateEmailOtp,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: _accentColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Code sent to ${_emailController.text}',
                      style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _styledTextField(
              controller: _otpController,
              label: 'Enter 6-digit Verification Code',
              icon: Icons.security_rounded,
              keyboardType: TextInputType.number,
              accentColor: _accentColor,
            ),
            const SizedBox(height: 20),
            _errorWidget(),
            _primaryButton(
              label: 'Verify Code & Continue',
              icon: Icons.verified_user_rounded,
              onPressed: _isLoading ? null : _verifyEmailOtp,
            ),
          ],
        ],

        const SizedBox(height: 12),
        // Toggle password ↔ OTP
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() {
              _useEmailOtp = !_useEmailOtp;
              _errorMessage = null;
              _emailTransactionId = null;
              _otpController.clear();
            }),
            icon: Icon(_useEmailOtp ? Icons.lock_outline : Icons.mark_email_read_outlined,
                size: 17, color: _accentColor),
            label: Text(
              _useEmailOtp
                  ? 'Login with Password instead'
                  : 'Login with Email OTP instead',
              style: TextStyle(color: _accentColor, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────
  Widget _styledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    List<dynamic>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters?.cast() ?? [],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accentColor),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        floatingLabelStyle: TextStyle(color: accentColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _errorWidget() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEF9A9A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFD32F2F), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style:
                    const TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                    color: _accentColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5))
              ]
            : [],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: MedEcosLoader(size: 20))
            : Icon(icon, size: 20),
        label: _isLoading ? const Text('Please wait...') : Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
    );
  }
}
