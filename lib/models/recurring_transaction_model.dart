import 'package:hive/hive.dart';

part 'recurring_transaction_model.g.dart';

@HiveType(typeId: 2)
class RecurringTransactionModel {
  @HiveField(0)
  String id;
  @HiveField(1)
  String note;
  @HiveField(2)
  double amount;
  @HiveField(3)
  String type;
  @HiveField(4)
  String category;
  @HiveField(5)
  String frequency;
  @HiveField(6)
  DateTime startDate;
  @HiveField(7)
  DateTime? endDate;
  @HiveField(8)
  bool isActive;
  @HiveField(9)
  DateTime? lastProcessed;
  @HiveField(10)
  DateTime nextDueDate;

  RecurringTransactionModel({
    required this.id,
    required this.note,
    required this.amount,
    required this.type,
    required this.category,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.lastProcessed,
    DateTime? nextDueDate,
  }) : nextDueDate = nextDueDate ?? startDate;

  DateTime calculateNextDueDate() {
    DateTime next = nextDueDate;
    switch (frequency) {
      case 'daily':
        next = next.add(const Duration(days: 1));
        break;
      case 'weekly':
        next = next.add(const Duration(days: 7));
        break;
      case 'monthly':
        next = DateTime(next.year, next.month + 1, next.day);
        break;
      case 'yearly':
        next = DateTime(next.year + 1, next.month, next.day);
        break;
    }
    return next;
  }

  bool get isDue => DateTime.now().isAfter(nextDueDate) || DateTime.now().day == nextDueDate.day;
}