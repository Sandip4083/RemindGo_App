import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/reminder_storage.dart';
import 'add_reminder_screen.dart';
import 'completed_reminders_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  bool _loading = true;

  String _searchQuery = "";
  String _filter = "All";
  String _categoryFilter = "All";

  String _userName = "John Doe";
  String _userEmail = "johndoe@example.com";
  String? _userImage;

  final List<String> _categories = [
    'All',
    'General',
    'Work',
    'Personal',
    'Health',
    'Other'
  ];
  final List<String> _filters = ['All', 'Today', 'Upcoming', 'High Priority'];

  @override
  void initState() {
    super.initState();
    _load();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('profile_name') ?? "John Doe";
      _userEmail = prefs.getString('profile_email') ?? "johndoe@example.com";
      _userImage = prefs.getString('profile_image');
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ReminderStorage.loadReminders();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    setState(() {
      _reminders = list;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    DateTime now = DateTime.now();
    List<Reminder> filtered = _reminders.where((r) => !r.isCompleted).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (r) => r.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_categoryFilter != "All") {
      filtered = filtered.where((r) => r.category == _categoryFilter).toList();
    }

    if (_filter == "Today") {
      filtered = filtered
          .where((r) =>
              r.dateTime.year == now.year &&
              r.dateTime.month == now.month &&
              r.dateTime.day == now.day)
          .toList();
    } else if (_filter == "Upcoming") {
      filtered = filtered.where((r) => r.dateTime.isAfter(now)).toList();
    } else if (_filter == "High Priority") {
      filtered = filtered.where((r) => r.priority == 'High').toList();
    }

    setState(() {
      _filteredReminders = filtered;
    });
  }

  Future<void> _delete(Reminder r) async {
    await NotificationService.cancelMultiple([
      r.preNotificationId,
      r.mainNotificationId,
    ]);
    await ReminderStorage.removeReminder(r.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reminder deleted successfully"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markComplete(Reminder r) async {
    await NotificationService.cancelMultiple([
      r.preNotificationId,
      r.mainNotificationId,
    ]);
    await ReminderStorage.markAsCompleted(r.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reminder marked as completed!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _edit(Reminder r) async {
    final titleController = TextEditingController(text: r.title);
    DateTime selectedDate = r.dateTime;
    int preAlert =
        [5, 10, 30, 60].contains(r.preAlertMinutes) ? r.preAlertMinutes : 30;

    // ✅ FIX: Validate category and priority before using in dropdown
    String category =
        ['General', 'Work', 'Personal', 'Health', 'Other'].contains(r.category)
            ? r.category
            : 'General';

    String priority =
        ['Low', 'Medium', 'High'].contains(r.priority) ? r.priority : 'Medium';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Edit Reminder"),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Title",
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat.yMMMd().add_jm().format(selectedDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: const Text("Change Date & Time"),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    // ✅ FIXED: Added "General" to dropdown
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                      items: ['General', 'Work', 'Personal', 'Health', 'Other']
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: InputDecoration(
                        labelText: "Priority",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => priority = val);
                      },
                      items: ['Low', 'Medium', 'High']
                          .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<int>(
                      value: preAlert,
                      decoration: InputDecoration(
                        labelText: "Pre-alert time",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => preAlert = val);
                      },
                      items: const [
                        DropdownMenuItem(
                            value: 5, child: Text("5 minutes before")),
                        DropdownMenuItem(
                            value: 10, child: Text("10 minutes before")),
                        DropdownMenuItem(
                            value: 30, child: Text("30 minutes before")),
                        DropdownMenuItem(
                            value: 60, child: Text("1 hour before")),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await NotificationService.cancelMultiple([
        r.preNotificationId,
        r.mainNotificationId,
      ]);

      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('current_user_email') ?? '';

      final updated = Reminder(
        id: r.id,
        title: titleController.text,
        dateTime: selectedDate,
        preNotificationId: r.preNotificationId,
        mainNotificationId: r.mainNotificationId,
        preAlertMinutes: preAlert,
        userEmail: currentUser,
        category: category,
        priority: priority,
      );

      await ReminderStorage.addReminder(updated);

      await NotificationService.schedulePreAndMain(
        preId: updated.preNotificationId,
        mainId: updated.mainNotificationId,
        title: updated.title,
        mainTime: updated.dateTime,
        preAlertMinutes: updated.preAlertMinutes,
      );

      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reminder updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _handleLogout() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text("Logout"),
          ],
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logged out successfully")),
                );
              }
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search reminders...",
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ..._filters.map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(f, _getIconForFilter(f)),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ..._categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(c),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredReminders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note,
                              size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No reminders found!',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey)),
                          const SizedBox(height: 8),
                          const Text('Tap + to add your first reminder',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12, top: 12, bottom: 80),
                        itemCount: _filteredReminders.length,
                        itemBuilder: (context, index) {
                          final r = _filteredReminders[index];
                          final formattedDateTime =
                              DateFormat('MMM dd, yyyy hh:mm a')
                                  .format(r.dateTime);

                          Color priorityColor = Colors.grey;
                          IconData priorityIcon = Icons.flag_outlined;
                          if (r.priority == 'High') {
                            priorityColor = Colors.red;
                            priorityIcon = Icons.priority_high;
                          } else if (r.priority == 'Medium') {
                            priorityColor = Colors.orange;
                            priorityIcon = Icons.flag;
                          } else {
                            priorityColor = Colors.blue;
                            priorityIcon = Icons.flag_outlined;
                          }

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: priorityColor.withOpacity(0.2),
                                child: Icon(priorityIcon, color: priorityColor),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(r.category),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      r.category,
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  "$formattedDateTime\nPre-alert: ${r.preAlertMinutes} min | ${r.priority} Priority",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'complete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Mark Complete'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'complete') {
                                    _markComplete(r);
                                  } else if (value == 'edit') {
                                    _edit(r);
                                  } else if (value == 'delete') {
                                    _delete(r);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'General':
        return Colors.grey;
      case 'Work':
        return Colors.blue;
      case 'Personal':
        return Colors.purple;
      case 'Health':
        return Colors.green;
      case 'Other':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForFilter(String filter) {
    switch (filter) {
      case 'All':
        return Icons.list;
      case 'Today':
        return Icons.today;
      case 'Upcoming':
        return Icons.upcoming;
      case 'High Priority':
        return Icons.priority_high;
      default:
        return Icons.filter_list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RemindGo'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    _userImage != null ? FileImage(File(_userImage!)) : null,
                child: _userImage == null
                    ? Icon(Icons.person, size: 40, color: Colors.blue.shade600)
                    : null,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text("Profile"),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                _loadUserProfile();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.archive, color: Colors.blue),
              title: const Text("Completed Reminders"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CompletedRemindersScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blue),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      onThemeChanged: widget.onThemeChanged,
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: _buildRemindersList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddReminderScreen()),
          );
          if (changed == true) await _load();
        },
        label: const Text("Add Reminder"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final bool selected = _filter == label;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: selected ? Colors.white : Colors.blue),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      selectedColor: Colors.blue.shade600,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.blue),
      onSelected: (val) {
        setState(() {
          _filter = label;
        });
        _applyFilters();
      },
    );
  }

  Widget _buildCategoryChip(String category) {
    final bool selected = _categoryFilter == category;
    return ChoiceChip(
      label: Text(category),
      selected: selected,
      selectedColor: _getCategoryColor(category),
      labelStyle:
          TextStyle(color: selected ? Colors.white : Colors.grey.shade700),
      onSelected: (val) {
        setState(() {
          _categoryFilter = category;
        });
        _applyFilters();
      },
    );
  }
}
