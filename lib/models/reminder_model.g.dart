// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 0;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      id: fields[0] as int,
      title: fields[1] as String,
      dateTime: fields[2] as DateTime,
      preNotificationId: fields[3] as int,
      mainNotificationId: fields[4] as int,
      preAlertMinutes: fields[5] as int,
      category: fields[6] as String? ?? "General",
      priority: fields[7] as String? ?? "Medium",
      userEmail: fields[8] as String? ?? "",
      isCompleted: fields[9] as bool? ?? false,
      completedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(11) // ✅ Changed from 6 to 11
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.preNotificationId)
      ..writeByte(4)
      ..write(obj.mainNotificationId)
      ..writeByte(5)
      ..write(obj.preAlertMinutes)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.userEmail)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
