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

  // ✅ প্রথম লঞ্চ চেক করুন
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

  runApp(AmarHisabApp(isFirstLaunch: isFirstLaunch));
}

// ==================== ওয়েলকাম স্ক্রিন (ইংরেজি + উন্নত ডিজাইন) ====================
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const WelcomeScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F766E), // Teal 700
              const Color(0xFF2DD4BF), // Teal 400
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                // অ্যাপের লোগো (বর্ডার সহ)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'My Accounting',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Track your daily income & expenses effortlessly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        Icons.trending_up,
                        'Income & Expense Tracking',
                        'Add transactions with ease',
                      ),
                      _buildFeatureItem(
                        Icons.book,
                        'Notebook',
                        'Write notes and draw sketches',
                      ),
                      _buildFeatureItem(
                        Icons.notifications_active,
                        'Reminders',
                        'Never miss a bill again',
                      ),
                      _buildFeatureItem(
                        Icons.account_balance,
                        'Budget Planner',
                        'Control your spending limits',
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: onGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== মূল অ্যাপ ====================
class AmarHisabApp extends StatefulWidget {
  final bool isFirstLaunch;

  const AmarHisabApp({super.key, required this.isFirstLaunch});

  @override
  State<AmarHisabApp> createState() => _AmarHisabAppState();
}

class _AmarHisabAppState extends State<AmarHisabApp> {
  String _language = 'en';
  bool _isDarkMode = false;
  bool _isLoading = true;
  late bool _showWelcome;

  @override
  void initState() {
    super.initState();
    _showWelcome = widget.isFirstLaunch;
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

  void _updateAppSettings({String? language, bool? isDarkMode}) {
    setState(() {
      if (language != null) _language = language;
      if (isDarkMode != null) _isDarkMode = isDarkMode;
    });
  }

  void _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);
    setState(() {
      _showWelcome = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // যদি প্রথম লঞ্চ হয়, ওয়েলকাম স্ক্রিন দেখাব
    if (_showWelcome) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My Accounting',
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
        home: WelcomeScreen(onGetStarted: _onGetStarted),
      );
    }

    // অন্যথায় মূল অ্যাপ
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Accounting',
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
      home: LockWrapper(
        language: _language,
        isDarkMode: _isDarkMode,
        onSettingsChanged: _updateAppSettings,
      ),
    );
  }
}

// ==================== LockWrapper (অপরিবর্তিত) ====================
class LockWrapper extends StatefulWidget {
  final String language;
  final bool isDarkMode;
  final Function({String? language, bool? isDarkMode}) onSettingsChanged;

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

    return HomeScreen(
      initialLanguage: widget.language,
      initialDarkMode: widget.isDarkMode,
      onSettingsChanged: widget.onSettingsChanged,
    );
  }
}