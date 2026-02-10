import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/database_service.dart';
import '../widgets/add_medicine_dialog.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final DatabaseService _db = DatabaseService();
  List<Medicine> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final list = await _db.getMedicines();
    setState(() {
      _medicines = list;
      _loading = false;
    });
  }

  void _addMedicine() async {
    await showDialog(
      context: context,
      builder: (context) => const AddMedicineDialog(),
    );
    _loadMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicines')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _medicines.length,
              itemBuilder: (context, index) {
                final med = _medicines[index];
                return ListTile(
                  title: Text(med.name),
                  subtitle: Text('${med.dosage} • ${med.frequency}x daily'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _db.deleteMedicine(med.id);
                      _loadMedicines();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedicine,
        child: const Icon(Icons.add),
      ),
    );
  }
}
