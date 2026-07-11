import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/screens/dashboard_screen.dart';
import 'signup_screen.dart';
import '../../../core/utils/abha_formatter.dart';
import '../../core/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _abhaController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _transactionId;

  Future<void> _generateOtp() async {
    if (_abhaController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/abha/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'abhaId': _abhaController.text}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _transactionId = data['transactionId'];
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to generate OTP';
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

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _transactionId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_id', data['_id']);
        await prefs.setString('user_role', data['role']);
        await prefs.setString('username', data['username'] ?? 'User');
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Invalid OTP';
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

  String _selectedRole = 'Patient';
  bool _isEmailLogin = false; // Default to email login
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = 'Invalid email format';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_id', data['_id']);
        await prefs.setString('user_role', data['role']);
        await prefs.setString('username', data['username'] ?? 'User');
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Invalid credentials';
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

  bool _useEmailOtp = false;
  String? _emailTransactionId;

  Future<void> _generateEmailOtp() async {
    if (_emailController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/email/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'purpose': 'Login Verification'
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _emailTransactionId = data['transactionId'];
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to send Gmail OTP';
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

  Future<void> _verifyEmailOtp() async {
    if (_otpController.text.isEmpty || _emailTransactionId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          }
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token'] ?? '');
        await prefs.setString('user_id', data['_id'] ?? '');
        await prefs.setString('user_role', data['role'] ?? _selectedRole);
        await prefs.setString('username', data['username'] ?? 'User');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Invalid verification code';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/Icon.jpeg', height: 32, width: 32),
            ),
            const SizedBox(width: 12),
            const Text('MedEcos Login'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/Icon.jpeg',
                        height: 90,
                        width: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Role Selector
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: ['Patient', 'Doctor', 'Pharmacist', 'Pathologist'].map((role) {
                        final isSelected = _selectedRole == role;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(role),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedRole = role;
                                  _errorMessage = null;
                                  if (role != 'Patient') {
                                    _isEmailLogin = true;
                                  } else {
                                    _isEmailLogin = false;
                                  }
                                });
                              }
                            },
                            selectedColor: Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.blue.shade900 : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                  ),
                  const SizedBox(height: 24),
  
                  if (_isEmailLogin) ...[
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '$_selectedRole Email',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_useEmailOtp) ...[
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _loginWithEmail,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading 
                            ? const CircularProgressIndicator() 
                            : const Text('Login'),
                      ),
                    ] else ...[
                      if (_emailTransactionId == null) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateEmailOtp,
                          icon: const Icon(Icons.mail_outline),
                          label: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Send Verification Code via Gmail'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Verification code sent to Gmail address: ${_emailController.text}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Enter 6-digit Verification Code',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.security),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyEmailOtp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading 
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Verify Code & Continue'),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _useEmailOtp = !_useEmailOtp;
                          _errorMessage = null;
                        });
                      },
                      icon: Icon(_useEmailOtp ? Icons.lock : Icons.mark_email_read),
                      label: Text(_useEmailOtp ? 'Login with Password instead' : 'Login with Gmail OTP verification'),
                    ),
                    if (_selectedRole == 'Patient') ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEmailLogin = false;
                            _errorMessage = null;
                          });
                        },
                        child: const Text("Use ABHA ID instead"),
                      ),
                    ],
                  ] else ...[
                    if (_transactionId == null) ...[
                      TextField(
                        controller: _abhaController,
                        inputFormatters: [AbhaInputFormatter()],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ABHA ID (e.g. 1111-2222-3333-4444)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _generateOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading 
                            ? const CircularProgressIndicator() 
                            : const Text('Send OTP'),
                      ),
                    ] else ...[
                      Text(
                        'OTP sent to registered mobile for ${_abhaController.text}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _otpController,
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP (Try 123456)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading 
                            ? const CircularProgressIndicator() 
                            : const Text('Verify & Login'),
                      ),
                    ],
                    if (_selectedRole == 'Patient') ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEmailLogin = true;
                            _errorMessage = null;
                          });
                        },
                        child: const Text("Use Email instead"),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                    },
                    child: const Text("Don't have an account? Sign Up (Email & ABHA)"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
