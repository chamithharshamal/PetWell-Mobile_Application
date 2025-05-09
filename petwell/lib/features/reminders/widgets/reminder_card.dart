import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class ReminderCard extends StatefulWidget {
  final Reminder reminder;

  const ReminderCard({super.key, required this.reminder});

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  bool isDone = false;

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        "${widget.reminder.dateTime.day.toString().padLeft(2, '0')}/"
        "${widget.reminder.dateTime.month.toString().padLeft(2, '0')}/"
        "${widget.reminder.dateTime.year}";
    String formattedTime =
        "${widget.reminder.dateTime.hour.toString().padLeft(2, '0')}:"
        "${widget.reminder.dateTime.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDone ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        leading: Checkbox(
          value: isDone,
          activeColor: Color(0xFFE74D3D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onChanged: (value) {
            setState(() {
              isDone = value!;
            });
          },
        ),
        title: Text(
          widget.reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: isDone ? Colors.grey : Colors.black,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 20, color: Color(0xFFE74D3D)),
              SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5C5C5C),
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.access_time_rounded,
                  size: 20, color: Color(0xFFE74D3D)),
              SizedBox(width: 8),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5C5C5C),
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.notifications_active_rounded,
            color: Color(0xFFE74D3D)),
      ),
    );
  }
}


