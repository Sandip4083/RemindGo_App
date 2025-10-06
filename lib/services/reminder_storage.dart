import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_model.dart';

class ReminderStorage {
  static const String boxName = 'reminders';

  static Future<Box<Reminder>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Reminder>(boxName);
    } else {
      return await Hive.openBox<Reminder>(boxName);
    }
  }

  static Future<String?> _getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_email');
  }

  static Future<void> addReminder(Reminder reminder) async {
    try {
      final box = await _openBox();
      final key = reminder.id.toString();
      await box.put(key, reminder);
    } catch (e, st) {
      print('❌ addReminder ERROR: $e\n$st');
      rethrow;
    }
  }

  static Future<List<Reminder>> loadReminders() async {
    try {
      final box = await _openBox();
      final currentUser = await _getCurrentUserEmail();

      if (currentUser == null) {
        return [];
      }

      // Filter reminders by current user email
      return box.values
          .cast<Reminder>()
          .where((r) => r.userEmail == currentUser)
          .toList();
    } catch (e, st) {
      print('❌ loadReminders ERROR: $e\n$st');
      return [];
    }
  }

  static Future<void> removeReminder(int id) async {
    try {
      final box = await _openBox();
      final key = id.toString();
      await box.delete(key);
    } catch (e, st) {
      print('❌ removeReminder ERROR: $e\n$st');
    }
  }

  static Future<void> markAsCompleted(int id) async {
    final box = await _openBox();
    final key = id.toString();
    final reminder = box.get(key);
    if (reminder != null) {
      reminder.isCompleted = true;
      reminder.completedAt = DateTime.now();
      await box.put(key, reminder);
    }
  }

  static Future<List<Reminder>> loadCompletedReminders() async {
    final reminders = await loadReminders();
    return reminders.where((r) => r.isCompleted).toList();
  }

  static Future<Map<String, int>> getUserStats([String? userEmail]) async {
    final currentUser = userEmail ?? await _getCurrentUserEmail();

    if (currentUser == null) {
      return {
        'total': 0,
        'completed': 0,
        'active': 0,
        'today': 0,
        'high': 0,
      };
    }

    final box = await _openBox();

    // Filter all reminders by current user
    final userReminders = box.values
        .cast<Reminder>()
        .where((r) => r.userEmail == currentUser)
        .toList();

    final total = userReminders.length;
    final completed = userReminders.where((r) => r.isCompleted).length;
    final active = total - completed;

    final now = DateTime.now();
    final today = userReminders
        .where((r) =>
            !r.isCompleted &&
            r.dateTime.year == now.year &&
            r.dateTime.month == now.month &&
            r.dateTime.day == now.day)
        .length;

    final high = userReminders
        .where((r) => !r.isCompleted && r.priority == "High")
        .length;

    return {
      'total': total,
      'completed': completed,
      'active': active,
      'today': today,
      'high': high,
    };
  }
}
