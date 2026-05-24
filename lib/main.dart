import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'services/notification_service.dart';
import 'services/lock_service.dart';
import 'services/offline_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lock_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // ১. ফ্লাটার বাইন্ডিং নিশ্চিত করা
  WidgetsFlutterBinding.ensureInitialized();

  // লোকাল ডেট ফরম্যাটিং লোড করা (তিনটি ভাষার জন্য)
  await initializeDateFormatting('bn', null);
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('ar', null);

  // লোকাল ডাটাবেজ হাইভ ইনিশিয়েল করা
  await Hive.initFlutter();
  await OfflineService.init();

  try {
    await Firebase.initializeApp();

    final FirebaseDatabase db = FirebaseDatabase.instance;
    // অফলাইন পারসিস্টেন্স অন থাকবে (এটি ক্যাশ ধরে রাখবে)
    db.setPersistenceEnabled(true);
    db.setPersistenceCacheSizeBytes(50 * 1024 * 1024);

    tz.initializeTimeZones();
    await NotificationService.init();
  } catch (e) {
    debugPrint("Initialization error: $e");
  }

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      // ✅ ডিফল্ট লোকেল ইংরেজি সেট করা হয়েছে
      locale: const Locale('en'),
      supportedLocales: const [Locale('bn'), Locale('en'), Locale('ar')],
      home: const AuthWrapper(),
    );
  }
}

// ==================== Auth Wrapper ====================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const LockWrapper();
        }
        return const LoginScreen();
      },
    );
  }
}

// ==================== Lock Wrapper ====================
class LockWrapper extends StatefulWidget {
  const LockWrapper({super.key});

  @override
  State<LockWrapper> createState() => _LockWrapperState();
}

class _LockWrapperState extends State<LockWrapper> {
  final LockService _lockService = LockService();
  bool _isLocked = false;
  bool _isLoading = true;
  String _language = 'en'; // ✅ ডিফল্ট ইংরেজি
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initializeAppSettings();
  }

  Future<void> _initializeAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = await _lockService.isLockEnabled();

      // ✅ 'language' কী-তে কোনো মান না থাকলে 'en' (ইংরেজি) সেট করা হবে
      final savedLang = prefs.getString('language');
      final lang = savedLang ?? 'en';

      if (mounted) {
        setState(() {
          _language = lang;
          _isDarkMode = prefs.getBool('darkMode') ?? false;
          _isLocked = isEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing app settings: $e");
      if (mounted) {
        setState(() {
          _isLocked = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    if (_isLocked) {
      return LockScreen(
        onUnlocked: (success) {
          if (success && mounted) {
            setState(() => _isLocked = false);
          }
        },
        language: _language,
        isDarkMode: _isDarkMode,
      );
    }

    return const HomeScreen();
  }
}