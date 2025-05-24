import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../../analytics/models/weight_record.dart';
import '../../analytics/weight_graph.dart';
import '../../reminders/screens/add_reminder_form.dart';
import '../../reminders/models/reminder_model.dart';

class PetDetailsScreen extends StatefulWidget {
  final String petId;

  const PetDetailsScreen({super.key, required this.petId});

  @override
  _PetDetailsScreenState createState() => _PetDetailsScreenState();
}

// Helper method to get month name from month number
String _getMonthName(int month) {
  const monthNames = [
    '', // 0 index not used
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  if (month < 1 || month > 12) return '';
  return monthNames[month];
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  final _weightController = TextEditingController();
  final _weightDateController = TextEditingController();

  Future<void> _selectDate(
    BuildContext context, {
    bool forWeight = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      setState(() {
        if (forWeight) {
          _weightDateController.text = picked.toString().substring(0, 10);
        }
      });
    }
  }

  void _addWeightRecord() async {
    if (_weightController.text.isEmpty || _weightDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter weight and date')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final weightRecord = WeightRecord(
          id: '',
          userId: user.uid,
          petId: widget.petId,
          weight: double.parse(_weightController.text.trim()),
          date: DateTime.parse(_weightDateController.text.trim()),
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('weight_records')
            .add(weightRecord.toFirestore());

        _weightController.clear();
        _weightDateController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight record added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add weight record: $e')),
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _weightDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe74d3d),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('pets').doc(widget.petId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            print('Error loading pet details: ${snapshot.error}');
            return const Center(child: Text('Error loading pet details'));
          }

          final pet = Pet.fromFirestore(
            snapshot.data!.data() as Map<String, dynamic>,
            widget.petId,
          );

          return SafeArea(
            child: Column(
              children: [
                // Header with pet image and back button
                Stack(
                  children: [
                    // Pet image covering top part
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: (pet.imageUrl != null && pet.imageUrl!.isNotEmpty)
                          ? Image.memory(
                              base64Decode(pet.imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'assets/default_pet.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/default_pet.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                    // Back button
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    // Options button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.more_horiz, size: 20),
                          onPressed: () {
                            // Show options menu
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Rest of the content with scrollable area
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pet name and breed
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pet.species,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Pet stats (without male part as requested)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Weight stat in the Row
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('weight_records')
                                      .where('petId', isEqualTo: widget.petId)
                                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return _buildStatItem('', '...', Icons.scale_outlined);
                                    }

                                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                      return _buildStatItem('', '0 kg', Icons.scale_outlined);
                                    }

                                    try {
                                      final weightRecords = snapshot.data!.docs.map((doc) {
                                        return WeightRecord.fromFirestore(
                                          doc.data() as Map<String, dynamic>,
                                          doc.id,
                                        );
                                      }).toList();

                                      weightRecords.sort((a, b) => b.date.compareTo(a.date));
                                      final latestWeight = weightRecords.first.weight;

                                      return _buildStatItem('', '$latestWeight kg', Icons.scale_outlined);
                                    } catch (e) {
                                      print('Error processing weight records: $e');
                                      return _buildStatItem('', '0 kg', Icons.scale_outlined);
                                    }
                                  },
                                ),

                                // Age
                                _buildStatItem('', '${pet.age} years', Icons.cake_outlined),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Records section (replacing Upcoming Visits)
                            Text(
                              'Records',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('records')
                                  .where('petId', isEqualTo: widget.petId)
                                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Text('Error loading records');
                                }
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final records = snapshot.data!.docs;

                                if (records.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20.0),
                                      child: Text('No reminders'),
                                    ),
                                  );
                                }

                                return Column(
                                  children: records.map((doc) {
                                    final record = Record.fromFirestore(
                                      doc.data() as Map<String, dynamic>,
                                      doc.id,
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF6F7C4),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.pets,
                                                color: Colors.amber,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    record.type,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    record.details,
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Colors.black54,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${record.date.day.toString().padLeft(2, '0')} ${_getMonthName(record.date.month)}',
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 14,
                                                      color: Colors.black54,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}',
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),

                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFe74d3d),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                AddReminderForm.showAddReminderDialog(context, widget.petId);
                              },
                              child: const Text('Add Reminder'),
                            ),

                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFe74d3d),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color(0xFFe74d3d),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                _showAddWeightDialog(context);
                              },
                              child: const Text('Add Weight Record'),
                            ),

                            const SizedBox(height: 24),
                            Text(
                              'Weight History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 200,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('weight_records')
                                    .where('petId', isEqualTo: widget.petId)
                                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    print('Error loading weight records: ${snapshot.error}');
                                    return const Center(
                                      child: Text('Error loading weight data'),
                                    );
                                  }
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final weightRecords = snapshot.data!.docs.map((doc) {
                                    return WeightRecord.fromFirestore(
                                      doc.data() as Map<String, dynamic>,
                                      doc.id,
                                    );
                                  }).toList();

                                  if (weightRecords.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No weight records available',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }

                                  return WeightGraph(
                                    weightRecords: weightRecords,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.amber, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (label.isNotEmpty)
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
      ],
    );
  }

  void _showAddWeightDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Weight Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightDateController,
              decoration: InputDecoration(
                labelText: 'Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, forWeight: true),
                ),
              ),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addWeightRecord();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe74d3d),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}