import 'package:flutter/material.dart';
import 'add_reminder_form.dart';
import '/models/reminder_model.dart';
import '/widgets/reminder_card.dart';

class RemindersListScreen extends StatefulWidget {
  const RemindersListScreen({super.key});

  @override
  State<RemindersListScreen> createState() => _RemindersListScreenState();
}

class _RemindersListScreenState extends State<RemindersListScreen> {
  List<Reminder> reminders = [];
  int _selectedIndex = 1; // Reminders is the middle tab (index 1)

  void _addReminder(Reminder reminder) {
    setState(() {
      reminders.add(reminder);
    });
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation logic placeholder
    if (index == 0) {
      // Navigate to Home Screen
      // Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else if (index == 2) {
      // Navigate to Profile Screen
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pet Reminders",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFFE74D3D),
        elevation: 4,
      ),
      body: reminders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              "No reminders yet 🐾",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          return ReminderCard(reminder: reminders[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newReminder = await showDialog(
            context: context,
            builder: (context) => const AddReminderForm(),
          );
          if (newReminder != null) {
            _addReminder(newReminder);
          }
        },
        backgroundColor: const Color(0xFFE74D3D),
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // 🌟 BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xFFE74D3D),
          unselectedItemColor: Colors.grey[500],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: '', // Hidden label
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active_outlined),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets), // 🐾 Modern paw icon
              label: '',
            ),
          ],
        ),
      ),

    );
  }
}
