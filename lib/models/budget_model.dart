class BudgetModel {
  final String id;
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final String period; // 'monthly', 'weekly', 'yearly'
  final String month; // '2026-05'
  final bool isActive;

  BudgetModel({
    required this.id,
    required this.category,
    required this.budgetAmount,
    this.spentAmount = 0,
    required this.period,
    required this.month,
    this.isActive = true,
  });

  double get remainingAmount => budgetAmount - spentAmount;

  double get spentPercentage {
    if (budgetAmount == 0) return 0;
    return (spentAmount / budgetAmount) * 100;
  }

  bool get isOverBudget => spentAmount > budgetAmount;

  String get statusText {
    if (isOverBudget) return 'অতিরিক্ত খরচ';
    if (spentPercentage >= 80) return 'সতর্কতা';
    if (spentPercentage >= 50) return 'অর্ধেক ব্যবহৃত';
    return 'নিরাপদ';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
      'period': period,
      'month': month,
      'isActive': isActive,
    };
  }

  factory BudgetModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return BudgetModel(
      id: id,
      category: map['category'] ?? 'other',
      budgetAmount: (map['budgetAmount'] ?? 0).toDouble(),
      spentAmount: (map['spentAmount'] ?? 0).toDouble(),
      period: map['period'] ?? 'monthly',
      month: map['month'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}