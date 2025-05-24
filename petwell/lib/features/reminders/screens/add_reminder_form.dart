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
    final TextEditingController typeController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();

    Future<void> selectDate(BuildContext context) async {
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
          dateController.text = picked.toString().substring(0, 10);
          timeController.text =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
          return;
        }

        dateController.text = picked.toString().substring(0, 10);
        timeController.text = '';
      }
    }

    Future<void> addRecord(BuildContext context) async {
      if (typeController.text.isEmpty ||
          detailsController.text.isEmpty ||
          dateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DateTime recordDate = DateTime.parse(dateController.text.trim());
          if (timeController.text.isNotEmpty) {
            final timeParts = timeController.text.split(':');
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
            type: typeController.text.trim(),
            details: detailsController.text.trim(),
            date: recordDate,
            createdAt: DateTime.now(),
          );

          await FirebaseFirestore.instance
              .collection('records')
              .add(record.toFirestore());

          typeController.clear();
          detailsController.clear();
          dateController.clear();
          timeController.clear();

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
                      controller: typeController,
                      decoration: const InputDecoration(
                        labelText: 'Record Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailsController,
                      decoration: const InputDecoration(
                        labelText: 'Details',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => selectDate(context),
                        ),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: timeController,
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
                              timeController.text =
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
                  addRecord(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe74d3d),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
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
      typeController.dispose();
      detailsController.dispose();
      dateController.dispose();
      timeController.dispose();
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