class RecurringTransactionModel {
  final String id;
  final String note;
  final double amount;
  final String type; // 'Income' or 'Expense'
  final String category;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? lastProcessed;
  final DateTime nextDueDate;

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note': note,
      'amount': amount,
      'type': type,
      'category': category,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'lastProcessed': lastProcessed?.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
    };
  }

  factory RecurringTransactionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return RecurringTransactionModel(
      id: id,
      note: map['note'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'Expense',
      category: map['category'] ?? 'other',
      frequency: map['frequency'] ?? 'monthly',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
      isActive: map['isActive'] ?? true,
      lastProcessed: map['lastProcessed'] != null ? DateTime.tryParse(map['lastProcessed']) : null,
      nextDueDate: DateTime.tryParse(map['nextDueDate'] ?? '') ?? DateTime.now(),
    );
  }

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