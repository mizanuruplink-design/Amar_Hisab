import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 1)
class BudgetModel {
  @HiveField(0)
  String id;
  @HiveField(1)
  String category;
  @HiveField(2)
  double budgetAmount;
  @HiveField(3)
  double spentAmount;
  @HiveField(4)
  String period;
  @HiveField(5)
  String month;
  @HiveField(6)
  bool isActive;

  BudgetModel({
    required this.id,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.period,
    required this.month,
    required this.isActive,
  });

  double get remainingAmount => budgetAmount - spentAmount;
  double get spentPercentage => budgetAmount == 0 ? 0 : (spentAmount / budgetAmount) * 100;
  bool get isOverBudget => spentAmount > budgetAmount;
  String get statusText {
    if (isOverBudget) return 'অতিরিক্ত খরচ';
    if (spentPercentage >= 80) return 'সতর্কতা';
    if (spentPercentage >= 50) return 'অর্ধেক ব্যবহৃত';
    return 'নিরাপদ';
  }
}