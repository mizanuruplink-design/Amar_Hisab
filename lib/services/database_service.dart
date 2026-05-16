import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/recurring_transaction_model.dart';
import 'offline_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    // Listen to auth changes to reset cached streams
    _auth.authStateChanges().listen((user) {
      _resetCachedStreams();
    });
  }

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Cached broadcast streams
  Stream<DatabaseEvent>? _cachedTransactionsStream;
  Stream<DatabaseEvent>? _cachedBudgetsStream;
  Stream<DatabaseEvent>? _cachedRecurringStream;
  Stream<DatabaseEvent>? _cachedNotesStream;

  void _resetCachedStreams() {
    _cachedTransactionsStream = null;
    _cachedBudgetsStream = null;
    _cachedRecurringStream = null;
    _cachedNotesStream = null;
  }

  // --------------- Internet check ---------------
  Future<bool> _isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
  Future<bool> checkInternet() async => _isOnline();

  Stream<bool> get connectionStatus {
    return FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false)
        .asBroadcastStream();   // ✅ important for multiple listeners
  }

  // --------------- Transactions ---------------
  Future<void> addTransaction(TransactionModel tx) async {
    final online = await _isOnline();
    if (online && _uid != null) {
      await _db.child('users/$_uid/transactions/${tx.id}').set(tx.toMap());
      if (tx.type == 'Expense') {
        _updateBudgetSpentAmount(tx);
      }
    } else {
      await OfflineService.saveOffline(tx);
      print('📱 Saved offline: ${tx.note}');
    }
  }

  Stream<DatabaseEvent> getTransactions() {
    if (_uid == null) return const Stream.empty();
    _cachedTransactionsStream ??= _db
        .child('users/$_uid/transactions')
        .onValue
        .asBroadcastStream();
    return _cachedTransactionsStream!;
  }

  Future<void> deleteTransaction(String id) async {
    if (_uid != null) {
      await _db.child('users/$_uid/transactions/$id').remove();
    }
  }

  Future<void> archiveTransaction(String id) async {
    if (_uid != null) {
      await _db.child('users/$_uid/transactions/$id').update({'isArchived': true});
    }
  }

  Future<void> unarchiveTransaction(String id) async {
    if (_uid != null) {
      await _db.child('users/$_uid/transactions/$id').update({'isArchived': false});
    }
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    if (_uid != null) {
      await _db.child('users/$_uid/transactions/$id').update(data);
    }
  }

  Future<void> updateReminderTime(String id, String time) async {
    if (_uid != null) {
      await _db.child('users/$_uid/transactions/$id').update({'time': time});
    }
  }

  // --------------- Sync ---------------
  Future<int> syncOfflineToOnline() async {
    final online = await _isOnline();
    if (!online || _uid == null) return 0;
    final list = OfflineService.getOfflineTransactions();
    int count = 0;
    for (var tx in list) {
      try {
        await _db.child('users/$_uid/transactions/${tx.id}').set(tx.toMap());
        await OfflineService.deleteOffline(tx.id);
        count++;
      } catch (e) {
        print('Sync failed: $e');
      }
    }
    return count;
  }

  List<TransactionModel> getOfflineTransactions() {
    return OfflineService.getOfflineTransactions();
  }

  // --------------- Budget ---------------
  Future<void> addBudget(BudgetModel budget) async {
    if (_uid != null) {
      await _db.child('users/$_uid/budgets/${budget.id}').set(budget.toMap());
    }
  }

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    if (_uid != null) await _db.child('users/$_uid/budgets/$id').update(data);
  }

  Future<void> deleteBudget(String id) async {
    if (_uid != null) await _db.child('users/$_uid/budgets/$id').remove();
  }

  Stream<DatabaseEvent> getBudgets() {
    if (_uid == null) return const Stream.empty();
    _cachedBudgetsStream ??= _db
        .child('users/$_uid/budgets')
        .onValue
        .asBroadcastStream();
    return _cachedBudgetsStream!;
  }

  Future<void> _updateBudgetSpentAmount(TransactionModel tx) async {
    if (_uid == null) return;
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final snap = await _db.child('users/$_uid/budgets').get();
    if (snap.exists) {
      final budgets = Map<String, dynamic>.from(snap.value as Map);
      budgets.forEach((key, val) {
        final budget = Map<String, dynamic>.from(val);
        if (budget['category'] == tx.category &&
            budget['month'] == month &&
            (budget['isActive'] == true || budget['isActive'] == null)) {
          final spent = (budget['spentAmount'] ?? 0).toDouble();
          _db.child('users/$_uid/budgets/$key').update({
            'spentAmount': spent + tx.amount,
          });
        }
      });
    }
  }

  Future<Map<String, dynamic>> getBudgetSummary(String month) async {
    double totalBudget = 0, totalSpent = 0;
    if (_uid != null) {
      final snap = await _db.child('users/$_uid/budgets').get();
      if (snap.exists) {
        final budgets = Map<String, dynamic>.from(snap.value as Map);
        budgets.forEach((key, val) {
          final b = Map<String, dynamic>.from(val);
          if (b['month'] == month) {
            totalBudget += (b['budgetAmount'] ?? 0).toDouble();
            totalSpent += (b['spentAmount'] ?? 0).toDouble();
          }
        });
      }
    }
    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'remaining': totalBudget - totalSpent,
      'percentage': totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0,
    };
  }

  // --------------- Recurring Transactions ---------------
  Future<void> addRecurringTransaction(RecurringTransactionModel rt) async {
    if (_uid != null) {
      await _db.child('users/$_uid/recurring/${rt.id}').set(rt.toMap());
    }
  }

  Stream<DatabaseEvent> getRecurringTransactions() {
    if (_uid == null) return const Stream.empty();
    _cachedRecurringStream ??= _db
        .child('users/$_uid/recurring')
        .onValue
        .asBroadcastStream();
    return _cachedRecurringStream!;
  }

  Future<void> updateRecurringTransaction(String id, Map<String, dynamic> data) async {
    if (_uid != null) {
      await _db.child('users/$_uid/recurring/$id').update(data);
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    if (_uid != null) {
      await _db.child('users/$_uid/recurring/$id').remove();
    }
  }

  Future<void> processRecurringTransactions() async {
    if (_uid == null) return;
    final snap = await _db.child('users/$_uid/recurring').get();
    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(snap.value as Map);
    for (var entry in data.entries) {
      final rtData = Map<String, dynamic>.from(entry.value);
      final rt = RecurringTransactionModel.fromMap(entry.key.toString(), rtData);
      if (rt.isActive && rt.isDue) {
        final tx = TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: rt.amount,
          note: '🔄 ${rt.note}',
          type: rt.type,
          date: DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()),
          category: rt.category,
          isArchived: false,
        );
        await addTransaction(tx);
        final newNext = rt.calculateNextDueDate();
        await _db.child('users/$_uid/recurring/${rt.id}').update({
          'lastProcessed': DateTime.now().toIso8601String(),
          'nextDueDate': newNext.toIso8601String(),
        });
      }
    }
  }

  // --------------- Notes ---------------
  Future<void> saveNote({required String title, required String content, String? reminderDateTime, required int colorValue}) async {
    if (_uid != null) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await _db.child('users/$_uid/notes/$id').set({
        'id': id, 'title': title, 'content': content,
        'reminderTime': reminderDateTime, 'colorValue': colorValue,
        'createdAt': DateTime.now().toString(),
      });
    }
  }

  Stream<DatabaseEvent> getNotes() {
    if (_uid == null) return const Stream.empty();
    _cachedNotesStream ??= _db
        .child('users/$_uid/notes')
        .onValue
        .asBroadcastStream();
    return _cachedNotesStream!;
  }

  Future<void> deleteNote(String noteKey) async {
    if (_uid != null) await _db.child('users/$_uid/notes/$noteKey').remove();
  }
}