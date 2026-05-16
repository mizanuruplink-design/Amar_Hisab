import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/notification_service.dart';
import 'services/lock_service.dart';
import 'services/offline_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await OfflineService.init();

  try {
    await Firebase.initializeApp();

    // ✅ Correct: setPersistenceEnabled and setPersistenceCacheSizeBytes are synchronous (void)
    final FirebaseDatabase db = FirebaseDatabase.instance;
    db.setPersistenceEnabled(true);
    db.setPersistenceCacheSizeBytes(50 * 1024 * 1024);
    // keepSynced returns Future<void>, so we await it
    await db.ref('users').keepSynced(true);

    tz.initializeTimeZones();
    await NotificationService.init();
  } catch (e) {
    debugPrint("Init error: $e");
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

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  void _checkLockStatus() async {
    try {
      final isEnabled = await _lockService.isLockEnabled();
      if (mounted) {
        setState(() {
          _isLocked = isEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lock check error: $e");
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
        language: 'bn',
        isDarkMode: false,
      );
    }

    return const HomeScreen();
  }
}