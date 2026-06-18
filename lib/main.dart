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

class AmarHisabApp extends StatefulWidget {
  const AmarHisabApp({super.key});

  @override
  State<AmarHisabApp> createState() => _AmarHisabAppState();
}

class _AmarHisabAppState extends State<AmarHisabApp> {
  String _language = 'en';
  bool _isDarkMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'en';
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _isLoading = false;
    });
  }

  // 🔄 এই ফাংশনটি HomeScreen থেকে কল হলে পুরো অ্যাপের থিম ও ভাষা সাথে সাথে চেঞ্জ হবে
  void _updateAppSettings({String? language, bool? isDarkMode}) {
    setState(() {
      if (language != null) _language = language;
      if (isDarkMode != null) _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'আমার হিসাব',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      locale: Locale(_language),
      supportedLocales: const [Locale('bn'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 🟢 LockWrapper-এ অ্যাপডেটের ফাংশনটি পাস করা হলো
      home: LockWrapper(
        language: _language,
        isDarkMode: _isDarkMode,
        onSettingsChanged: _updateAppSettings,
      ),
    );
  }
}

class LockWrapper extends StatefulWidget {
  final String language;
  final bool isDarkMode;
  final Function({String? language, bool? isDarkMode}) onSettingsChanged; // 🟢 কলব্যাক রিসিভার

  const LockWrapper({
    super.key,
    required this.language,
    required this.isDarkMode,
    required this.onSettingsChanged,
  });

  @override
  State<LockWrapper> createState() => _LockWrapperState();
}

class _LockWrapperState extends State<LockWrapper> {
  final LockService _lockService = LockService();
  bool _isLocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    final enabled = await _lockService.isLockEnabled();
    setState(() {
      _isLocked = enabled;
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
        language: widget.language,
        isDarkMode: widget.isDarkMode,
      );
    }

    // 🟢 HomeScreen ওপেন করার সময় কারেন্ট থিম, ভাষা এবং চেইঞ্জ করার ফাংশনটি পাস করে দিন
    return HomeScreen(
      initialLanguage: widget.language,
      initialDarkMode: widget.isDarkMode,
      onSettingsChanged: widget.onSettingsChanged,
    );
  }
}