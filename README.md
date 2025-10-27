# RemindGo - Smart Reminder App

A powerful Flutter application for managing reminders with custom alarm tones, pre-alerts, and intelligent notification system. Never miss an important moment again!
![Remindgo_icon](https://github.com/user-attachments/assets/fe7e6ac7-7e83-4155-8b90-11a5a1d625f2)

## Features

### Core Reminder Features

- **Smart Scheduling**: Create reminders with precise date and time
- **Custom Alarm Tones**: Choose between default alarm or custom audio files from your device
- **Dual Notification System**:
  - Pre-alert notification (5, 10, 30, or 60 minutes before)
  - Main alarm notification at exact scheduled time
- **Priority System**: Categorize reminders as Low, Medium, or High priority
- **Categories**: Organize reminders into General, Work, Personal, Health, or Other
- **Completion Tracking**: Mark reminders as completed and view them in archive
- **Search & Filter**: Find reminders quickly with powerful search and filter options
- **Statistics Dashboard**: View comprehensive reminder statistics and insights

### User Management

- **Multi-User Support**: Each user has their own reminders and notes
- **Secure Authentication**: Email and password-based login system
- **Gmail Validation**: Strict Gmail address validation during registration
- **Profile Management**: Update profile, change password, and add profile picture

### Additional Features

- **Dark Mode**: Full dark theme support for comfortable viewing
- **Notification Control**: Enable/disable notifications from settings
- **Persistent Storage**: All data stored locally using Hive database
- **Exact Alarm Permission**: Ensures alarms fire at precise scheduled times
- **Full-Screen Alarms**: Important reminders display full-screen for maximum attention



## Installation

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/remindgo.git
cd remindgo
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Generate Hive adapters**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run the app**

```bash
flutter run
```

## Build Release APK

```bash
# Clean previous builds
flutter clean

# Build release APK
flutter build apk --release
```

The APK will be available at: `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── models/
│   ├── reminder_model.dart
│   └── reminder_model.g.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── add_reminder_screen.dart
│   ├── completed_reminders_screen.dart
│   ├── profile_screen.dart
│   ├── settings_screen.dart
│   └── stats_screen.dart
├── services/
│   ├── notification_service.dart
│   └── reminder_storage.dart
├── widgets/
│   └── reminder_card.dart
└── main.dart
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.3.3
  flutter_local_notifications: ^19.0.0
  timezone: ^0.10.1
  intl: ^0.20.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  image_picker: ^1.0.7
  permission_handler: ^11.0.1
  file_picker: ^8.1.4

dev_dependencies:
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  flutter_launcher_icons: ^0.13.1
```

## Permissions

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

## Key Features Explained

### Custom Alarm Tones

Users can select custom audio files from their device storage. The app properly handles file URIs and plays them during main alarm notifications with full volume and vibration, ensuring you never miss an important reminder.

### Dual Notification System

Each reminder includes two intelligent notifications:

1. **Pre-alert**: Gentle notification X minutes before the scheduled time (configurable: 5, 10, 30, or 60 minutes)
2. **Main alarm**: Full-volume alarm with vibration at the exact scheduled time with your chosen sound

### Smart Filtering

- **Today View**: See all reminders scheduled for today
- **Upcoming View**: View all future reminders
- **High Priority**: Quick access to urgent reminders
- **Category Filter**: Filter by General, Work, Personal, Health, or Other
- **Search**: Find any reminder instantly by title

### User-Specific Data

All reminders are filtered by logged-in user email, ensuring complete data privacy and separation in multi-user scenarios.

### Hive Database

Uses Hive for fast, lightweight local storage with type-safe models and adapters, ensuring your reminder data is always available offline.

## Troubleshooting

### Alarms Not Firing

1. Grant "Schedule Exact Alarm" permission in device settings
2. Disable battery optimization for the app
3. Ensure notifications are enabled in app settings

### Custom Audio Not Playing

1. Verify the audio file format is supported (MP3, WAV, etc.)
2. Check storage permissions are granted
3. Try selecting the file again from file picker

### Build Errors

```bash
# Clear build cache
flutter clean

# Regenerate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Get dependencies again
flutter pub get
```

## Version History

### v2.3.0 (Current)

- Fixed custom alarm tone playback issue
- Simplified alarm tone selection (Default Alarm & Custom Audio only)
- Improved notification reliability and volume control
- Enhanced alarm scheduling with exact timing
- Better user experience and interface improvements

### v2.2.0

- Added custom alarm tone selection feature
- Alarm tone preview functionality
- Multiple system alarm options

### v2.0.0

- User authentication and login system
- Multi-user support with data separation
- Profile management with picture upload
- Dark mode theme support

### v1.0.0

- Initial release
- Basic reminder creation and scheduling
- Notification system with pre-alerts
- Category and priority management

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

**Your Name**

- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

## Acknowledgments

- Flutter team for the amazing framework
- Contributors to all the open-source packages used
- Community for feedback and suggestions

## Support

If you like this project, please give it a ⭐ on GitHub!

For issues and feature requests, please use the [GitHub Issues](https://github.com/yourusername/remindgo/issues) page.

---

**Note**: This app requires Android 6.0 (API level 23) or higher for full functionality.
