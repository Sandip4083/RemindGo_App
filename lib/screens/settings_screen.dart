import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _loading = true;
  String _selectedAlarmTone = 'Default Alarm';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _selectedAlarmTone =
          prefs.getString('alarm_tone_name') ?? 'Default Alarm';
      _loading = false;
    });
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _saveDarkModeSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  Future<void> _pickAlarmTone() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.music_note, color: Colors.blue),
            SizedBox(width: 8),
            Text('Select Alarm Tone'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              child: ListTile(
                leading: Radio<String>(
                  value: 'Default Alarm',
                  groupValue: _selectedAlarmTone,
                  onChanged: (val) => Navigator.pop(context, 'default'),
                ),
                title: const Text('Default Alarm'),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.blue),
                  onPressed: () async {
                    await NotificationService.playTestAlarm(null);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playing default alarm...'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                onTap: () => Navigator.pop(context, 'default'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Radio<String>(
                  value: 'Custom Audio',
                  groupValue: _selectedAlarmTone == 'Default Alarm'
                      ? ''
                      : 'Custom Audio',
                  onChanged: (val) => Navigator.pop(context, 'custom'),
                ),
                title: const Text('Custom Audio'),
                subtitle: _selectedAlarmTone != 'Default Alarm'
                    ? Text(_selectedAlarmTone,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                    : const Text('Choose from device',
                        style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.folder_open, color: Colors.blue),
                onTap: () => Navigator.pop(context, 'custom'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      if (selected == 'custom') {
        await _pickCustomAudioFile();
      } else {
        await _saveAlarmTone('', 'Default Alarm');
      }
    }
  }

  Future<void> _pickCustomAudioFile() async {
    try {
      final audioStatus = await Permission.audio.request();
      if (!audioStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Audio permission required!'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        String uri = filePath.startsWith('content://')
            ? filePath
            : filePath.startsWith('/')
                ? 'file://$filePath'
                : filePath;

        print("📁 Selected: $fileName");
        print("🔗 URI: $uri");

        await _saveAlarmTone(uri, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Custom tone: $fileName'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Test',
                textColor: Colors.white,
                onPressed: () async {
                  await NotificationService.playTestAlarm(uri);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAlarmTone(String uri, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_sound_uri', uri);
    await prefs.setString('alarm_tone_name', name);

    setState(() {
      _selectedAlarmTone = name;
    });

    print("💾 Saved: $name");
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blue.shade600,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Enable Notifications"),
                  subtitle: const Text("Turn notifications on/off"),
                  value: _notificationsEnabled,
                  activeColor: Colors.blue.shade600,
                  onChanged: (val) async {
                    setState(() => _notificationsEnabled = val);
                    await _saveNotificationSetting(val);
                    if (!val) {
                      await NotificationService.cancelAllNotifications();
                    }
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  subtitle: const Text("Enable dark theme"),
                  value: _darkMode,
                  activeColor: Colors.blue.shade600,
                  onChanged: (val) async {
                    setState(() => _darkMode = val);
                    await _saveDarkModeSetting(val);
                    widget.onThemeChanged?.call(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.music_note),
                  ),
                  title: const Text("Alarm Tone"),
                  subtitle: Text("Current: $_selectedAlarmTone"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.green),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final uri = prefs.getString('alarm_sound_uri');
                          await NotificationService.playTestAlarm(
                              uri?.isEmpty == true ? null : uri);
                        },
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: _pickAlarmTone,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.info)),
                  title: const Text("About"),
                  subtitle: const Text("App information"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "RemindGo",
                      applicationVersion: "2.4.0",
                      children: const [
                        Text("Custom alarm tones with audio permission\n"
                            "Main alarms play custom sounds\n"
                            "Pre-alerts use system notification sound")
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: isDarkMode
                ? Colors.blue.shade900.withOpacity(0.3)
                : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates,
                          color: isDarkMode
                              ? Colors.blue.shade200
                              : Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text("Important Tips:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• Grant Audio permission for custom sounds\n"
                    "• Test your alarm before setting reminders\n"
                    "• Main alarms = custom ringtone\n"
                    "• Pre-alerts = notification sound\n"
                    "• Enable exact alarm permission",
                    style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
