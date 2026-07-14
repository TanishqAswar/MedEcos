import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/widgets/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../support/screens/about_us_screen.dart';
import '../../../core/utils/abha_formatter.dart';
import '../../core/utils/constants.dart';
import '../../core/widgets/medecos_loader.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _abhaController = TextEditingController();
  final _specialityController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedRole = 'Patient';
  String? _selectedGender;
  bool _isLoading = false;
  bool _isLocating = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  Future<void> _signup() async {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = 'Invalid email format';
      });
      return;
    }

    if (!_isEmailVerified) {
      setState(() {
        _errorMessage = 'Please verify your email address using the "Verify Gmail" button before signing up.';
      });
      return;
    }

    if (_selectedRole == 'Doctor' || _selectedRole == 'Pathologist') {
      if (_latController.text.isEmpty || _lngController.text.isEmpty || _addressController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Location and Address are mandatory for ${_selectedRole}s.';
        });
        return;
      }
      final lat = double.tryParse(_latController.text);
      final lng = double.tryParse(_lngController.text);
      if (lat == null || lng == null) {
        setState(() {
          _errorMessage = 'Invalid latitude or longitude values.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> body = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': _selectedRole,
      };

      if (_selectedRole == 'Patient') {
        body['abhaId'] = _abhaController.text;
        if (_ageController.text.isNotEmpty) body['age'] = int.tryParse(_ageController.text);
        if (_selectedGender != null) body['gender'] = _selectedGender;
      } else if (_selectedRole == 'Doctor' || _selectedRole == 'Pathologist') {
        body['location'] = {
          'lat': double.tryParse(_latController.text) ?? 0.0,
          'lng': double.tryParse(_lngController.text) ?? 0.0,
        };
        body['address'] = _addressController.text;
        if (_selectedRole == 'Doctor') {
          body['speciality'] = _specialityController.text;
        }
      }

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
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
          _errorMessage = data['message'] ?? 'Signup failed';
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

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _errorMessage = 'Location services are disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _errorMessage = 'Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage = 'Location permissions are permanently denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Could not detect location: $e');
    } finally {
      setState(() => _isLocating = false);
    }
  }

  bool _isEmailVerified = false;
  String? _emailTransactionId;
  final _emailOtpController = TextEditingController();
  bool _sendingEmailOtp = false;

  Future<void> _sendEmailOtp() async {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address first';
      });
      return;
    }
    setState(() {
      _sendingEmailOtp = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/email/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'purpose': 'Account Registration'
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _emailTransactionId = data['transactionId'];
          if (data['devOtp'] != null) {
            _emailOtpController.text = data['devOtp'].toString();
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['devOtp'] != null 
                  ? 'Cloud SMTP blocked: Auto-filled fallback OTP (${data['devOtp']})'
                  : 'Verification code sent to your Gmail address! Check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to send OTP to email';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _sendingEmailOtp = false;
      });
    }
  }

  Future<void> _verifyEmailOtp() async {
    if (_emailOtpController.text.isEmpty || _emailTransactionId == null) return;
    setState(() {
      _sendingEmailOtp = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/email/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'transactionId': _emailTransactionId,
          'otp': _emailOtpController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _isEmailVerified = true;
          _emailTransactionId = null;
          _errorMessage = null;
        });
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
        _sendingEmailOtp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutUsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset('assets/Icon.jpeg', height: 32, width: 32),
                ),
                const SizedBox(width: 12),
                const Text('MedEcos Registration'),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
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
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  readOnly: _isEmailVerified,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isEmailVerified
                        ? const Icon(Icons.verified, color: Colors.green)
                        : TextButton.icon(
                            onPressed: _sendingEmailOtp ? null : _sendEmailOtp,
                            icon: const Icon(Icons.mail_outline, size: 18),
                            label: _sendingEmailOtp
                                ? const MedEcosLoader(size: 20)
                                : const Text('Verify Gmail'),
                          ),
                  ),
                ),
                if (_emailTransactionId != null && !_isEmailVerified) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailOtpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Enter 6-digit Gmail OTP',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _sendingEmailOtp ? null : _verifyEmailOtp,
                        child: _sendingEmailOtp
                            ? const MedEcosLoader(size: 20)
                            : const Text('Verify Code'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Patient', 'Doctor', 'Pharmacist', 'Pathologist'].map((role) {
                    return DropdownMenuItem(value: role, child: Text(role.replaceAll('_', ' ')));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedRole = val!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedRole == 'Patient') ...[
                  TextField(
                    controller: _abhaController,
                    inputFormatters: [AbhaInputFormatter()],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ABHA ID (e.g. 1111-2222-3333-4444)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender *',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Male', 'Female', 'Other'].map((gender) {
                            return DropdownMenuItem(value: gender, child: Text(gender));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedGender = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (_selectedRole == 'Doctor' || _selectedRole == 'Pathologist') ...[
                  if (_selectedRole == 'Doctor') ...[
                    TextField(
                      controller: _specialityController,
                      decoration: const InputDecoration(
                        labelText: 'Type of Doctor (e.g. Cardiologist)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Clinic / Lab Address *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Latitude *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Longitude *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLocating ? null : _detectLocation,
                          icon: _isLocating
                              ? const MedEcosLoader(size: 20)
                              : const Icon(Icons.my_location),
                          label: Text(_isLocating ? 'Detecting...' : 'Use My Location'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final LatLng? picked = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                            );
                            if (picked != null) {
                              setState(() {
                                _latController.text = picked.latitude.toString();
                                _lngController.text = picked.longitude.toString();
                              });
                            }
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Choose from Map'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
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
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                      ? const MedEcosLoader(size: 24) 
                      : const Text('Sign Up'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Already have an account? Login'),
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
