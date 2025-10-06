import 'package:hive/hive.dart';

part 'reminder_model.g.dart';

@HiveType(typeId: 0)
class Reminder extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime dateTime;

  @HiveField(3)
  int preNotificationId;

  @HiveField(4)
  int mainNotificationId;

  @HiveField(5)
  int preAlertMinutes;

  @HiveField(6)
  String category;

  @HiveField(7)
  String priority;

  @HiveField(8)
  String userEmail;

  @HiveField(9)
  bool isCompleted;

  @HiveField(10)
  DateTime? completedAt;

  Reminder({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.preNotificationId,
    required this.mainNotificationId,
    required this.preAlertMinutes,
    this.category = "General",
    this.priority = "Medium",
    this.userEmail = "",
    this.isCompleted = false,
    this.completedAt,
  });
}
