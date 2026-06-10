import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String type;

  @HiveField(3)
  String category;

  @HiveField(4)
  String date;

  @HiveField(5)
  String? note;

  @HiveField(6)
  String? refundDate;

  @HiveField(7)
  bool isPaid;

  @HiveField(8)
  bool isArchived;

  @HiveField(9)
  String? time;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.refundDate,
    this.isPaid = false,
    this.isArchived = false,
    this.time,
  });
}