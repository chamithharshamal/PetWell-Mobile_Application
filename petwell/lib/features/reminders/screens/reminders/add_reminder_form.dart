import 'package:flutter/material.dart';
import '/models/reminder_model.dart';

class AddReminderForm extends StatefulWidget {
  const AddReminderForm({super.key});

  @override
  State<AddReminderForm> createState() => _AddReminderFormState();
}

class _AddReminderFormState extends State<AddReminderForm> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  DateTime selectedDateTime = DateTime.now();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Reminder newReminder = Reminder(title: title, dateTime: selectedDateTime);
      Navigator.pop(context, newReminder);
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFE74D3D),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFFE74D3D)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteTextColor: Color(0xFFE74D3D),
                dialHandColor: Color(0xFFE74D3D),
                dialBackgroundColor: Colors.red[50],
              ),
              colorScheme: ColorScheme.light(
                primary: Color(0xFFE74D3D),
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted =
        "${selectedDateTime.day.toString().padLeft(2, '0')}/"
        "${selectedDateTime.month.toString().padLeft(2, '0')}/"
        "${selectedDateTime.year} @ "
        "${selectedDateTime.hour.toString().padLeft(2, '0')}:"
        "${selectedDateTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: Text("Add Reminder"),
        backgroundColor: Color(0xFFE74D3D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Color(0xFFFDF5F0),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "📝 Set New Reminder",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE74D3D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Reminder Title",
                        hintText: "Eg: Vet appointment",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(fontSize: 16),
                      onSaved: (value) => title = value!,
                      validator: (value) =>
                      value!.isEmpty ? "Please enter a title" : null,
                    ),
                    SizedBox(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_month_rounded,
                          color: Color(0xFFE74D3D)),
                      title: Text(
                        "Date & Time",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dateFormatted,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: _pickDateTime,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE74D3D),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: TextStyle(fontSize: 14),
                        ),
                        child: Text("Pick"),
                      ),
                    ),
                    SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: Icon(Icons.check),
                        label: Text("Save Reminder"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE74D3D),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}