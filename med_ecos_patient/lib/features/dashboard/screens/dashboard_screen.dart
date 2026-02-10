import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/database_service.dart';
import '../../../features/medicines/widgets/add_medicine_dialog.dart';
import '../../../features/medicines/screens/medicine_list_screen.dart';
import '../../../features/settings/screens/settings_screen.dart';
import '../../../features/history/screens/history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  List<Medicine> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await _db.getMedicines();
    setState(() {
      _medicines = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Find next medicine (logic simplified for demo: just pick first for now or random)
    // In real app, calculate closest time based on meal times.
    Medicine? nextMedicine;
    if (_medicines.isNotEmpty) {
      nextMedicine = _medicines.first; 
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MedEcos Patient'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _loadData(); // Reload in case meal times changed affecting schedule (visual only here)
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 20),
                    if (nextMedicine != null) _buildCurrentMedicineCard(nextMedicine),
                    if (nextMedicine == null) 
                      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No medicines scheduled"))),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Medicines',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () async {
                             await Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineListScreen()));
                             _loadData();
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._medicines.map((m) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(m.name[0])),
                        title: Text(m.name),
                        subtitle: Text('${m.dosage} • ${m.frequency}x daily'),
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const AddMedicineDialog(),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
    } else if (hour >= 17) {
      greeting = "Good Evening";
    }

    return Text(
      "$greeting, Patient",
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCurrentMedicineCard(Medicine medicine) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50, // Light blue bg
        border: Border.all(color: Colors.blue.shade900, width: 2), // Dark blue border
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Current Medicine",
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${medicine.name} ${medicine.dosage}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          // Displaying first timing for simplicity
          if (medicine.timings.isNotEmpty)
            Text("${medicine.timings[0].timeType.name} - ${medicine.timings[0].mealRef.name}"),
            
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
               // Log as taken
               _db.logMetadata(medicine.id, medicine.name, DateTime.now(), 'TAKEN');
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as taken')));
            },
            child: const Text("Mark as Taken"),
          )
        ],
      ),
    );
  }
}
