import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/reminder_storage.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _selectedDateTime;
  int _preAlertMinutes = 30;
  String _category = "General";
  String _priority = "Medium";

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    final selectedTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (selectedTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a future time!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedDateTime = selectedTime;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select date & time"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final dateTime = _selectedDateTime!;

    final existingReminders = await ReminderStorage.loadReminders();
    final duplicate = existingReminders.any((r) =>
        r.title.toLowerCase() == title.toLowerCase() &&
        r.dateTime.isAtSameMomentAs(dateTime));

    if (duplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reminder already exists!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final preId = NotificationService.generateId();
    final mainId = NotificationService.generateId();

    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('current_user_email') ?? '';

    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      dateTime: dateTime,
      preNotificationId: preId,
      mainNotificationId: mainId,
      preAlertMinutes: _preAlertMinutes,
      category: _category,
      priority: _priority,
      userEmail: currentUser,
    );

    await ReminderStorage.addReminder(reminder);

    await NotificationService.schedulePreAndMain(
      preId: preId,
      mainId: mainId,
      title: title,
      mainTime: dateTime,
      preAlertMinutes: _preAlertMinutes,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reminder saved successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  String _calculateTimeUntil(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) return "Time has passed";

    if (difference.inDays > 0) {
      return "in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}";
    } else if (difference.inHours > 0) {
      return "in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}";
    } else if (difference.inMinutes > 0) {
      return "in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}";
    } else {
      return "very soon";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Reminder"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  hintText: "e.g., Team meeting, Doctor appointment",
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50.withOpacity(0.3),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.access_time, color: Colors.blue),
                  ),
                  title: Text(
                    _selectedDateTime == null
                        ? "No date & time selected"
                        : DateFormat.yMMMd()
                            .add_jm()
                            .format(_selectedDateTime!),
                    style: TextStyle(
                      fontWeight: _selectedDateTime == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: _selectedDateTime != null
                      ? Text(
                          _calculateTimeUntil(_selectedDateTime!),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _pickDateTime,
                    child: const Text(
                      "Pick",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: "General", child: Text("General")),
                  DropdownMenuItem(value: "Work", child: Text("Work")),
                  DropdownMenuItem(value: "Personal", child: Text("Personal")),
                  DropdownMenuItem(value: "Health", child: Text("Health")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (v) => setState(() => _category = v ?? "General"),
                decoration: InputDecoration(
                  labelText: "Category",
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _priority,
                items: const [
                  DropdownMenuItem(value: "Low", child: Text("Low Priority")),
                  DropdownMenuItem(
                      value: "Medium", child: Text("Medium Priority")),
                  DropdownMenuItem(value: "High", child: Text("High Priority")),
                ],
                onChanged: (v) => setState(() => _priority = v ?? "Medium"),
                decoration: InputDecoration(
                  labelText: "Priority",
                  prefixIcon: const Icon(Icons.priority_high),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: [5, 10, 30, 60].contains(_preAlertMinutes)
                    ? _preAlertMinutes
                    : 30,
                items: const [
                  DropdownMenuItem(
                    value: 5,
                    child: Text("5 minutes before"),
                  ),
                  DropdownMenuItem(
                    value: 10,
                    child: Text("10 minutes before"),
                  ),
                  DropdownMenuItem(
                    value: 30,
                    child: Text("30 minutes before"),
                  ),
                  DropdownMenuItem(
                    value: 60,
                    child: Text("1 hour before"),
                  ),
                ],
                onChanged: (v) => setState(() => _preAlertMinutes = v ?? 30),
                decoration: InputDecoration(
                  labelText: "Pre-alert time",
                  prefixIcon: const Icon(Icons.alarm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "You'll receive two notifications:\n"
                        "1. Pre-alert before the reminder\n"
                        "2. Main alert at the exact time",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _save,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Save Reminder",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
