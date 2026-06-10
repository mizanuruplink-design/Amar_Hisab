import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/lock_service.dart';
import 'services/local_database_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'models/transaction_model.dart';
import 'models/budget_model.dart';
import 'models/recurring_transaction_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('bn', null);
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('ar', null);

  await Hive.initFlutter();

  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(RecurringTransactionModelAdapter());

  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<BudgetModel>('budgets');
  await Hive.openBox<RecurringTransactionModel>('recurring');
  await Hive.openBox('settings');

  await LocalDatabaseService().init();

  tz.initializeTimeZones();
  await NotificationService.initialize();

  runApp(const AmarHisabApp());
}

class AmarHisabApp extends StatelessWidget {
  const AmarHisabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'আমার হিসাব',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      locale: const Locale('en'),                // ✅ default English
      supportedLocales: const [Locale('bn'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LockWrapper(),
    );
  }
}

class LockWrapper extends StatefulWidget {
  const LockWrapper({super.key});

  @override
  State<LockWrapper> createState() => _LockWrapperState();
}

class _LockWrapperState extends State<LockWrapper> {
  final LockService _lockService = LockService();
  bool _isLocked = false;
  bool _isLoading = true;
  String _language = 'bn';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = await _lockService.isLockEnabled();
    setState(() {
      _isLocked = enabled;
      _language = prefs.getString('language') ?? 'bn';
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isLocked) {
      return LockScreen(
        onUnlocked: (success) {
          if (success) setState(() => _isLocked = false);
        },
        language: _language,
        isDarkMode: _isDarkMode,
      );
    }
    return const HomeScreen();
  }
}