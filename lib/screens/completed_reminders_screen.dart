import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reminder_model.dart';
import '../services/reminder_storage.dart';

class CompletedRemindersScreen extends StatefulWidget {
  const CompletedRemindersScreen({super.key});

  @override
  State<CompletedRemindersScreen> createState() =>
      _CompletedRemindersScreenState();
}

class _CompletedRemindersScreenState extends State<CompletedRemindersScreen> {
  List<Reminder> _completedReminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ReminderStorage.loadCompletedReminders();
    setState(() {
      _completedReminders = list;
      _loading = false;
    });
  }

  Future<void> _deleteCompleted(Reminder r) async {
    await ReminderStorage.removeReminder(r.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Deleted from archive"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completed Reminders"),
        backgroundColor: Colors.green.shade600,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _completedReminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No completed reminders yet!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completed reminders will appear here',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _completedReminders.length,
                    itemBuilder: (context, index) {
                      final r = _completedReminders[index];
                      final formattedDateTime =
                          DateFormat('MMM dd, yyyy hh:mm a').format(r.dateTime);
                      final completedAt = r.completedAt != null
                          ? DateFormat('MMM dd, yyyy').format(r.completedAt!)
                          : 'Unknown';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: const Icon(Icons.check_circle,
                                color: Colors.green),
                          ),
                          title: Text(
                            r.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Was due: $formattedDateTime\nCompleted: $completedAt",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCompleted(r),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
