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
  String period; // 'monthly', 'weekly', 'yearly'

  @HiveField(5)
  String month; // 'yyyy-MM'

  @HiveField(6)
  bool isActive;

  // ✅ নতুন ফিল্ড: 'Income' বা 'Expense'
  @HiveField(7)
  String? type;

  BudgetModel({
    required this.id,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.period,
    required this.month,
    required this.isActive,
    this.type = 'Expense', // ডিফল্ট Expense (ব্যাকওয়ার্ড কম্প্যাটিবিলিটি)
  });

  // ========== কম্পিউটেড প্রপার্টি ==========
  double get remainingAmount => budgetAmount - spentAmount;

  double get spentPercentage =>
      budgetAmount == 0 ? 0 : (spentAmount / budgetAmount) * 100;

  bool get isOverBudget => spentAmount > budgetAmount;

  String get statusText {
    if (isOverBudget) return 'অতিরিক্ত খরচ';
    if (spentPercentage >= 80) return 'সতর্কতা';
    if (spentPercentage >= 50) return 'অর্ধেক ব্যবহৃত';
    return 'নিরাপদ';
  }

  // ========== কনভেনিয়েন্স মেথড ==========
  /// কপি তৈরি করে নতুন মান দিয়ে আপডেট করুন (Hive update এর জন্য)
  BudgetModel copyWith({
    String? id,
    String? category,
    double? budgetAmount,
    double? spentAmount,
    String? period,
    String? month,
    bool? isActive,
    String? type,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      period: period ?? this.period,
      month: month ?? this.month,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
    );
  }

  // ========== JSON সাপোর্ট (ব্যাকআপ/রিস্টোরের জন্য) ==========
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
      'period': period,
      'month': month,
      'isActive': isActive,
      'type': type,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      category: json['category'] as String,
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      period: json['period'] as String,
      month: json['month'] as String,
      isActive: json['isActive'] as bool? ?? true,
      type: json['type'] as String? ?? 'Expense',
    );
  }
}