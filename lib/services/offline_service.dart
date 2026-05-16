import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';

class OfflineService {
  static const String _boxName = 'offline_transactions';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Future<void> saveOffline(TransactionModel tx) async {
    final box = Hive.box(_boxName);
    await box.put(tx.id, tx.toMap());
  }

  static List<TransactionModel> getOfflineTransactions() {
    final box = Hive.box(_boxName);
    List<TransactionModel> list = [];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        list.add(TransactionModel(
          id: data['id'] ?? key.toString(),
          amount: (data['amount'] ?? 0).toDouble(),
          note: data['note'] ?? '',
          type: data['type'] ?? '',
          date: data['date'] ?? '',
          category: data['category'] ?? '',
          isArchived: data['isArchived'] ?? false,
        ));
      }
    }
    return list;
  }

  static Future<void> clearOffline() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }

  static Future<void> deleteOffline(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }
}