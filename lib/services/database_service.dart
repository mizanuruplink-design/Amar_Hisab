import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/recurring_transaction_model.dart';
import 'offline_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    _auth.authStateChanges().listen((user) {
      _resetCachedStreams();
      if (user != null) {
        Future.delayed(const Duration(seconds: 2), () {
          processRecurringTransactions();
        });
      }
    });
  }

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Cached broadcast streams (legacy)
  Stream<DatabaseEvent>? _cachedTransactionsStream;
  Stream<DatabaseEvent>? _cachedBudgetsStream;
  Stream<DatabaseEvent>? _cachedRecurringStream;
  Stream<DatabaseEvent>? _cachedNotesStream;

  // BehaviorSubjects for caching
  BehaviorSubject<List<TransactionModel>>? _transactionsSubject;
  bool _isTransactionListenerSet = false;

  BehaviorSubject<List<BudgetModel>>? _budgetsSubject;
  bool _isBudgetListenerSet = false;

  BehaviorSubject<List<RecurringTransactionModel>>? _recurringSubject;
  bool _isRecurringListenerSet = false;

  // --- Public cached streams ---
  Stream<List<TransactionModel>> get transactionsStream {
    if (_uid == null) return Stream.empty();
    _transactionsSubject ??= BehaviorSubject<List<TransactionModel>>();
    _ensureTransactionListener();
    return _transactionsSubject!.stream;
  }

  Stream<List<BudgetModel>> get budgetsStream {
    if (_uid == null) return Stream.empty();
    _budgetsSubject ??= BehaviorSubject<List<BudgetModel>>();
    _ensureBudgetListener();
    return _budgetsSubject!.stream;
  }

  Stream<List<RecurringTransactionModel>> get recurringStream {
    if (_uid == null) return Stream.empty();
    _recurringSubject ??= BehaviorSubject<List<RecurringTransactionModel>>();
    _ensureRecurringListener();
    return _recurringSubject!.stream;
  }

  // --- Private listeners ---
  void _ensureTransactionListener() {
    if (_isTransactionListenerSet) return;
    _isTransactionListenerSet = true;
    _cachedTransactionsStream ??= _db
        .child('users/$_uid/transactions')
        .limitToLast(100)
        .onValue
        .asBroadcastStream();
    _cachedTransactionsStream!.listen((event) {
      final parsed = _parseTransactions(event);
      if (!_transactionsSubject!.isClosed) {
        _transactionsSubject!.add(parsed);
      }
    });
  }

  void _ensureBudgetListener() {
    if (_isBudgetListenerSet) return;
    _isBudgetListenerSet = true;
    _cachedBudgetsStream ??= _db
        .child('users/$_uid/budgets')
        .onValue
        .asBroadcastStream();
    _cachedBudgetsStream!.listen((event) {
      final parsed = _parseBudgets(event);
      if (!_budgetsSubject!.isClosed) {
        _budgetsSubject!.add(parsed);
      }
    });
  }

  void _ensureRecurringListener() {
    if (_isRecurringListenerSet) return;
    _isRecurringListenerSet = true;
    _cachedRecurringStream ??= _db
        .child('users/$_uid/recurring')
        .limitToLast(100)
        .onValue
        .asBroadcastStream();
    _cachedRecurringStream!.listen((event) {
      final parsed = _parseRecurring(event);
      if (!_recurringSubject!.isClosed) {
        _recurringSubject!.add(parsed);
      }
    });
  }

  // --- Parsers ---
  List<TransactionModel> _parseTransactions(DatabaseEvent event) {
    final list = <TransactionModel>[];
    if (event.snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      data.forEach((key, value) {
        if (value != null) {
          list.add(TransactionModel.fromMap(
            key.toString(),
            Map<String, dynamic>.from(value as Map),
          ));
        }
      });
    }
    return list;
  }

  List<BudgetModel> _parseBudgets(DatabaseEvent event) {
    final list = <BudgetModel>[];
    if (event.snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      data.forEach((key, value) {
        if (value != null) {
          list.add(BudgetModel.fromMap(
            key.toString(),
            Map<String, dynamic>.from(value as Map),
          ));
        }
      });
    }
    return list;
  }

  List<RecurringTransactionModel> _parseRecurring(DatabaseEvent event) {
    final list = <RecurringTransactionModel>[];
    if (event.snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      data.forEach((key, value) {
        if (value != null) {
          list.add(RecurringTransactionModel.fromMap(
            key.toString(),
            Map<String, dynamic>.from(value as Map),
          ));
        }
      });
    }
    list.sort((a, b) => b.nextDueDate.compareTo(a.nextDueDate));
    return list;
  }

  void _resetCachedStreams() {
    _cachedTransactionsStream = null;
    _cachedBudgetsStream = null;
    _cachedRecurringStream = null;
    _cachedNotesStream = null;

    if (_transactionsSubject != null && !_transactionsSubject!.isClosed) {
      _transactionsSubject!.close();
    }
    if (_budgetsSubject != null && !_budgetsSubject!.isClosed) {
      _budgetsSubject!.close();
    }
    if (_recurringSubject != null && !_recurringSubject!.isClosed) {
      _recurringSubject!.close();
    }

    _transactionsSubject = null;
    _budgetsSubject = null;
    _recurringSubject = null;

    _isTransactionListenerSet = false;
    _isBudgetListenerSet = false;
    _isRecurringListenerSet = false;
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
        .asBroadcastStream();
  }

  // --------------- Transactions ---------------
  Future<void> addTransaction(TransactionModel tx) async {
    if (_uid != null) {
      await _db.child('users/$_uid/transactions/${tx.id}').set(tx.toMap());
      if (tx.type?.toLowerCase() == 'expense') {
        _updateBudgetSpentAmount(tx);
      }
    } else {
      await OfflineService.saveOffline(tx);
      print('📱 Saved local offline backup: ${tx.note}');
    }
  }

  // Legacy stream (kept for compatibility)
  Stream<DatabaseEvent> getTransactions() {
    if (_uid == null) return const Stream.empty();
    _cachedTransactionsStream ??= _db
        .child('users/$_uid/transactions')
        .limitToLast(100)
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

  // --------------- One‑time fetch (for export/stats) ---------------
  Future<List<TransactionModel>> fetchAllTransactions() async {
    if (_uid == null) return [];
    try {
      final snap = await _db.child('users/$_uid/transactions').get();
      if (!snap.exists || snap.value == null) return [];
      final data = Map<dynamic, dynamic>.from(snap.value as Map);
      final list = <TransactionModel>[];
      data.forEach((key, value) {
        if (value != null) {
          list.add(TransactionModel.fromMap(
            key.toString(),
            Map<String, dynamic>.from(value as Map),
          ));
        }
      });
      return list;
    } catch (e) {
      print('Error fetching all transactions: $e');
      return [];
    }
  }

  // --------------- Sync ---------------
  Future<int> syncOfflineToOnline() async {
    if (_uid == null) return 0;
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

  // --------------- Budgets ---------------
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

  // Legacy stream
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
    try {
      final snap = await _db.child('users/$_uid/budgets').get();
      if (snap.exists && snap.value != null) {
        final budgets = Map<dynamic, dynamic>.from(snap.value as Map);
        budgets.forEach((key, val) {
          if (val != null) {
            final budget = Map<String, dynamic>.from(val as Map);
            if (budget['category']?.toString().toLowerCase() == tx.category?.toLowerCase() &&
                budget['month'] == month &&
                (budget['isActive'] == true || budget['isActive'] == null)) {
              final spent = double.tryParse(budget['spentAmount'].toString()) ?? 0.0;
              final txAmt = double.tryParse(tx.amount.toString()) ?? 0.0;
              _db.child('users/$_uid/budgets/$key').update({
                'spentAmount': spent + txAmt,
              });
            }
          }
        });
      }
    } catch (e) {
      print('Error updating budget spent amount: $e');
    }
  }

  Future<Map<String, dynamic>> getBudgetSummary(String month) async {
    double totalBudget = 0, totalSpent = 0;
    if (_uid != null) {
      final snap = await _db.child('users/$_uid/budgets').get();
      if (snap.exists && snap.value != null) {
        final budgets = Map<dynamic, dynamic>.from(snap.value as Map);
        budgets.forEach((key, val) {
          if (val != null) {
            final b = Map<String, dynamic>.from(val as Map);
            if (b['month'] == month) {
              totalBudget += double.tryParse(b['budgetAmount'].toString()) ?? 0.0;
              totalSpent += double.tryParse(b['spentAmount'].toString()) ?? 0.0;
            }
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
      processRecurringTransactions();
    }
  }

  // Legacy stream
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
      processRecurringTransactions();
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    if (_uid != null) {
      await _db.child('users/$_uid/recurring/$id').remove();
    }
  }

  Future<void> processRecurringTransactions() async {
    if (_uid == null) return;
    try {
      final snap = await _db.child('users/$_uid/recurring').get();
      if (!snap.exists || snap.value == null) return;
      final data = Map<dynamic, dynamic>.from(snap.value as Map);
      for (var entry in data.entries) {
        if (entry.value != null) {
          final rtData = Map<String, dynamic>.from(entry.value as Map);
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
    } catch (e) {
      print("Error processing recurring transactions: $e");
    }
  }

  // --------------- Notes ---------------
  Future<void> saveNote({required String title, required String content, String? reminderDateTime, required int colorValue}) async {
    if (_uid != null) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await _db.child('users/$_uid/notes/$id').set({
        'id': id,
        'title': title,
        'content': content,
        'reminderTime': reminderDateTime,
        'colorValue': colorValue,
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

  // Helper method that uses fetchAllTransactions (now defined)
  Future<List<TransactionModel>> getTransactionsOnce() async {
    return await fetchAllTransactions();
  }

  Future<void> deleteNote(String noteKey) async {
    if (_uid != null) await _db.child('users/$_uid/notes/$noteKey').remove();
  }
}