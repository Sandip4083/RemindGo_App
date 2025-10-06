import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:remindgo/models/reminder_model.dart';
import 'package:remindgo/screens/home_screen.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    Hive.registerAdapter(ReminderAdapter());
    await Hive.openBox<Reminder>('reminders');
  });

  tearDownAll(() async {
    // Clean up after tests
    await Hive.close();
  });

  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    // Wrap with MaterialApp for testing
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Wait for the widget to build
    await tester.pumpAndSettle();

    // Verify app loads
    expect(find.text('RemindGo'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
