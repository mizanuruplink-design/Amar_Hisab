class TransactionModel {
  String id;
  double amount;
  String type;
  String category;
  String date;
  String? note;
  String? refundDate;
  bool isPaid;
  bool isArchived;

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
  });

  // ডাটাবেসে সেভ করার জন্য Map-এ কনভার্ট (id সহ)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
      'note': note,
      'refundDate': refundDate,
      'isPaid': isPaid,
      'isArchived': isArchived,
    };
  }

  // ডাটাবেস থেকে ডাটা পড়ার জন্য Factory মেথড
  factory TransactionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return TransactionModel(
      id: id,
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount']?.toString() ?? '') ?? 0.0,
      type: map['type'] ?? 'Expense',
      category: map['category'] ?? 'General',
      date: map['date'] ?? '',
      note: map['note'],
      refundDate: map['refundDate'],
      isPaid: map['isPaid'] ?? false,
      isArchived: map['isArchived'] ?? false,
    );
  }
}