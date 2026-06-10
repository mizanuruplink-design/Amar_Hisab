import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 3)   // Use a unique typeId (0,1,2 are already used)
class NoteModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  String date;

  @HiveField(4)
  String? reminderTime;

  @HiveField(5)
  int colorValue;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.reminderTime,
    required this.colorValue,
  });
}