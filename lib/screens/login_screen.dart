import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView( // ওভারফ্লো এড়াতে স্ক্রোল ভিউ যোগ করা হয়েছে
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // অ্যাপ আইকন
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet, size: 80, color: Colors.teal.shade700),
              ),
              const SizedBox(height: 25),

              // অ্যাপের নাম
              const Text(
                "আমার হিসাব",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "আপনার আয়ের হিসাব রাখুন সহজে",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              // গুগল লগইন বাটন
              _isLoggingIn
                  ? const CircularProgressIndicator(color: Colors.teal)
                  : SizedBox(
                width: double.infinity,
                height: 55, // হাইট একটু বাড়ানো হয়েছে যাতে দেখতে ভালো লাগে
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    setState(() => _isLoggingIn = true);
                    try {
                      final user = await AuthService().signInWithGoogle();
                      if (user == null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("লগইন বাতিল করা হয়েছে")),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("লগইন ব্যর্থ হয়েছে: $e")),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoggingIn = false);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // অনলাইন ইমেজের বদলে আইকন ব্যবহার করা নিরাপদ
                      const Icon(Icons.login, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      const Text(
                        "Google দিয়ে লগইন করুন",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}