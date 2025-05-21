import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class AddReminderForm extends StatefulWidget {
  final String petId;

  const AddReminderForm({super.key, required this.petId});

  @override
  _AddReminderFormState createState() => _AddReminderFormState();

  static void showAddReminderDialog(BuildContext context, String petId) {
    final TextEditingController _typeController = TextEditingController();
    final TextEditingController _detailsController = TextEditingController();
    final TextEditingController _dateController = TextEditingController();
    final TextEditingController _timeController = TextEditingController();

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2026),
      );

      if (picked != null) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (pickedTime != null) {
          _dateController.text = picked.toString().substring(0, 10);
          _timeController.text =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
          return;
        }

        _dateController.text = picked.toString().substring(0, 10);
        _timeController.text = '';
      }
    }

    Future<void> _addRecord(BuildContext context) async {
      if (_typeController.text.isEmpty ||
          _detailsController.text.isEmpty ||
          _dateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DateTime recordDate = DateTime.parse(_dateController.text.trim());
          if (_timeController.text.isNotEmpty) {
            final timeParts = _timeController.text.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            recordDate = DateTime(
              recordDate.year,
              recordDate.month,
              recordDate.day,
              hour,
              minute,
            );
          }

          final record = Record(
            id: '',
            userId: user.uid,
            petId: petId,
            type: _typeController.text.trim(),
            details: _detailsController.text.trim(),
            date: recordDate,
            createdAt: DateTime.now(),
          );

          await FirebaseFirestore.instance
              .collection('records')
              .add(record.toFirestore());

          _typeController.clear();
          _detailsController.clear();
          _dateController.clear();
          _timeController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record added successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add record: $e')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        try {
          return AlertDialog(
            title: const Text('Add Reminder'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _typeController,
                      decoration: const InputDecoration(
                        labelText: 'Record Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailsController,
                      decoration: const InputDecoration(
                        labelText: 'Details',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              _timeController.text =
                              '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                            }
                          },
                        ),
                      ),
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _addRecord(context);
                  Navigator.pop(context);
                },
                child: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe74d3d),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error showing dialog: $e')),
          );
          return const SizedBox.shrink(); // Return an empty widget if error occurs
        }
      },
    ).whenComplete(() {
      _typeController.dispose();
      _detailsController.dispose();
      _dateController.dispose();
      _timeController.dispose();
    });
  }
}

class _AddReminderFormState extends State<AddReminderForm> {
  @override
  Widget build(BuildContext context) {
    // This widget isn't used directly; we use showAddReminderDialog instead
    return Container();
  }

  @override
  void dispose() {
    super.dispose();
  }
}