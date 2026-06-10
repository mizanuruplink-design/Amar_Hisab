import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/recurring_transaction_model.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  late Box<TransactionModel> _transactionBox;
  late Box<BudgetModel> _budgetBox;
  late Box<RecurringTransactionModel> _recurringBox;
  late Box _settingsBox;

  Future<void> init() async {
    _transactionBox = await Hive.openBox<TransactionModel>('transactions');
    _budgetBox = await Hive.openBox<BudgetModel>('budgets');
    _recurringBox = await Hive.openBox<RecurringTransactionModel>('recurring');
    _settingsBox = await Hive.openBox('settings');
  }

  // Expose boxes for ValueListenableBuilder
  Box<TransactionModel> get transactionsBox => _transactionBox;
  Box<BudgetModel> get budgetsBox => _budgetBox;
  Box<RecurringTransactionModel> get recurringBox => _recurringBox;

  // ---------- Transactions ----------
  Future<void> addTransaction(TransactionModel tx) async {
    print('➕ Adding transaction: ${tx.id} - ${tx.amount}');
    await _transactionBox.put(tx.id, tx);
    print('✅ Transaction saved – box size: ${_transactionBox.values.length}');
    if (tx.type.toLowerCase() == 'expense') {
      _updateBudgetSpent(tx);
    }
  }

  Future<void> deleteTransaction(String id) async => _transactionBox.delete(id);

  Future<void> archiveTransaction(String id, bool isArchived) async {
    final tx = _transactionBox.get(id);
    if (tx != null) {
      tx.isArchived = isArchived;
      await _transactionBox.put(tx.id, tx);
    }
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    final tx = _transactionBox.get(id);
    if (tx != null) {
      if (data.containsKey('amount')) tx.amount = data['amount'];
      if (data.containsKey('note')) tx.note = data['note'];
      if (data.containsKey('category')) tx.category = data['category'];
      if (data.containsKey('date')) tx.date = data['date'];
      if (data.containsKey('time')) tx.time = data['time'];
      if (data.containsKey('isPaid')) tx.isPaid = data['isPaid'];
      await _transactionBox.put(tx.id, tx);
    }
  }

  Future<void> updateReminder(String id, String? newNote, String newDate, String newTime) async {
    final tx = _transactionBox.get(id);
    if (tx != null && tx.type == 'Reminder') {
      if (newNote != null) tx.note = newNote;
      tx.date = newDate;
      tx.time = newTime;
      await _transactionBox.put(tx.id, tx);
    }
  }

  Future<void> updateReminderCompleted(String id, bool completed) async {
    final tx = _transactionBox.get(id);
    if (tx != null) {
      tx.isPaid = completed;
      await _transactionBox.put(tx.id, tx);
    }
  }

  // ---------- Budgets ----------
  Future<void> addBudget(BudgetModel budget) async => _budgetBox.put(budget.id, budget);

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    final b = _budgetBox.get(id);
    if (b != null) {
      if (data.containsKey('budgetAmount')) b.budgetAmount = data['budgetAmount'];
      if (data.containsKey('spentAmount')) b.spentAmount = data['spentAmount'];
      if (data.containsKey('isActive')) b.isActive = data['isActive'];
      await _budgetBox.put(b.id, b);
    }
  }

  Future<void> deleteBudget(String id) async => _budgetBox.delete(id);

  Future<Map<String, dynamic>> getBudgetSummary(String month) async {
    double totalBudget = 0, totalSpent = 0;
    for (var b in _budgetBox.values) {
      if (b.month == month) {
        totalBudget += b.budgetAmount;
        totalSpent += b.spentAmount;
      }
    }
    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'remaining': totalBudget - totalSpent,
      'percentage': totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0,
    };
  }

  void _updateBudgetSpent(TransactionModel tx) async {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    for (var b in _budgetBox.values) {
      if (b.category == tx.category && b.month == month && b.isActive) {
        b.spentAmount += tx.amount;
        await _budgetBox.put(b.id, b);
      }
    }
  }

  // ---------- Recurring ----------
  Future<void> addRecurringTransaction(RecurringTransactionModel rt) async =>
      _recurringBox.put(rt.id, rt);

  Future<void> updateRecurringTransaction(String id, Map<String, dynamic> data) async {
    final rt = _recurringBox.get(id);
    if (rt != null) {
      if (data.containsKey('isActive')) rt.isActive = data['isActive'];
      if (data.containsKey('nextDueDate')) {
        final value = data['nextDueDate'];
        if (value is DateTime) {
          rt.nextDueDate = value;
        } else if (value is String) {
          rt.nextDueDate = DateTime.parse(value);
        }
      }
      await _recurringBox.put(rt.id, rt);
    }
  }

  Future<void> deleteRecurringTransaction(String id) async => _recurringBox.delete(id);

  Future<void> processRecurringTransactions() async {
    final now = DateTime.now();
    for (var rt in _recurringBox.values) {
      if (rt.isActive && rt.nextDueDate.isBefore(now)) {
        final tx = TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: rt.amount,
          note: '🔄 ${rt.note}',
          type: rt.type,
          date: DateFormat('dd/MM/yyyy hh:mm a').format(now),
          category: rt.category,
        );
        await addTransaction(tx);
        rt.lastProcessed = now;
        rt.nextDueDate = rt.calculateNextDueDate();
        await _recurringBox.put(rt.id, rt);
      }
    }
  }
}