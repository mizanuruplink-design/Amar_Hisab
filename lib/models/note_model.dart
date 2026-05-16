class NoteModel {
  String? id;
  String title;
  String content;
  String date;
  String? reminderTime; // মিটিং বা অ্যালার্মের সময়
  int colorValue; // নোটের কালার (যেমন: 0xFFFF8A80)

  NoteModel({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.reminderTime,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': date,
      'reminderTime': reminderTime,
      'colorValue': colorValue,
    };
  }
}