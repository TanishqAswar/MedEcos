import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'patient_details_screen.dart';

class PatientLookupScreen extends StatefulWidget {
  const PatientLookupScreen({super.key});

  @override
  State<PatientLookupScreen> createState() => _PatientLookupScreenState();
}

class _PatientLookupScreenState extends State<PatientLookupScreen> {
  final TextEditingController _idController = TextEditingController();

  void _navigateToDetails(String patientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patientId: patientId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Lookup")),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.medical_information, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                "Find Patient",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Enter ID or scan QR code",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: "Patient ID",
                  hintText: "e.g. PAT-1024",
                  prefixIcon: Icon(Icons.person_search),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) _navigateToDetails(value);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                   if (_idController.text.isNotEmpty) _navigateToDetails(_idController.text);
                },
                child: const Text("Search"),
              ),
              const SizedBox(height: 24),
              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("OR", style: TextStyle(color: Colors.grey))), Expanded(child: Divider())]),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  // Open Scanner (Placeholder for strict instructions)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR Scanner taking you to patient details...")));
                  // Simulation
                  _navigateToDetails("QR-SCANNED-USER");
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Scan QR Code"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
