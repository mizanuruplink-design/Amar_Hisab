import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';  // ✅ added for BehaviorSubject
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
        // Delay to avoid UI freeze during first login
        Future.delayed(const Duration(seconds: 2), () {
          processRecurringTransactions();
        });
      }
    });
  }

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Cached broadcast streams (kept for backward compatibility)
  Stream<DatabaseEvent>? _cachedTransactionsStream;
  Stream<DatabaseEvent>? _cachedBudgetsStream;
  Stream<DatabaseEvent>? _cachedRecurringStream;
  Stream<DatabaseEvent>? _cachedNotesStream;

  // ✅ NEW: BehaviorSubject that caches and replays the latest transaction list
  BehaviorSubject<List<TransactionModel>>? _transactionsSubject;
  bool _isTransactionListenerSet = false;

  // Public stream that new listeners can subscribe to – receives the last list immediately
  Stream<List<TransactionModel>> get transactionsStream {
    if (_uid == null) return Stream.empty();
    _transactionsSubject ??= BehaviorSubject<List<TransactionModel>>();
    _ensureTransactionListener();
    return _transactionsSubject!.stream;
  }

  // One‑time fetch of all transactions (for export / stats that don't need live updates)
  Future<List<TransactionModel>> fetchAllTransactions() async {
    if (_uid == null) return [];
    try {
      final snap = await _db.child('users/$_uid/transactions').get();
      if (!snap.exists || snap.value == null) return [];
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      final List<TransactionModel> list = [];
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

  void _ensureTransactionListener() {
    if (_isTransactionListenerSet) return;
    _isTransactionListenerSet = true;

    // Create the underlying broadcast stream (only one Firebase subscription)
    _cachedTransactionsStream ??= _db
        .child('users/$_uid/transactions')
        .limitToLast(100)
        .onValue
        .asBroadcastStream();

    // Every time Firebase emits an event, parse and add to BehaviorSubject
    _cachedTransactionsStream!.listen((event) {
      final List<TransactionModel> parsed = _parseTransactions(event);
      if (!_transactionsSubject!.isClosed) {
        _transactionsSubject!.add(parsed);
      }
    });
  }

  List<TransactionModel> _parseTransactions(DatabaseEvent event) {
    final List<TransactionModel> list = [];
    if (event.snapshot.value != null) {
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
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

  void _resetCachedStreams() {
    _cachedTransactionsStream = null;
    _cachedBudgetsStream = null;
    _cachedRecurringStream = null;
    _cachedNotesStream = null;
    // Also close and recreate the BehaviorSubject on user change
    if (_transactionsSubject != null && !_transactionsSubject!.isClosed) {
      _transactionsSubject!.close();
    }
    _transactionsSubject = null;
    _isTransactionListenerSet = false;
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

  // Legacy stream – kept for compatibility (but new code should use transactionsStream)
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
  Future<List<TransactionModel>> getTransactionsOnce() async {
    return await fetchAllTransactions();
  }

  Future<void> deleteNote(String noteKey) async {
    if (_uid != null) await _db.child('users/$_uid/notes/$noteKey').remove();
  }
}