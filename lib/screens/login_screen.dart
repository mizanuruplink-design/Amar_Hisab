import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoggingIn = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    // 🟢Curves.backOut ফিক্স করে Curves.easeOutBack দেওয়া হয়েছে
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ১. ব্যাকগ্রাউন্ড গ্রেডিয়েন্ট এবং স্টাইলিশ আর্ট
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A), // ডিপ স্লেট ব্লু
                  Color(0xFF022C22), // ডিপ টিল গ্রিন
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ব্যাকগ্রাউন্ডের হালকা গ্লো ইফেক্ট বৃত্ত
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // 🟢 BoxDecoration এর সরাসরি ভেতর থেকে blurRadius সরিয়ে BoxShadow তে দেওয়া হয়েছে
                color: Colors.teal.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // ২. মেইন কন্টেন্ট বডি
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // অ্যাপ আইকন এবং নিওন গ্লো ইফেক্ট
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade500.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.teal.shade400.withOpacity(0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.shade500.withOpacity(0.3),
                              blurRadius: 25,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 64,
                          color: Color(0xff2dd4bf), // উজ্জ্বল নিওন টিল
                        ),
                      ),
                      const SizedBox(height: 24),

                      // অ্যাপ টাইটেল
                      const Text(
                        "My Accounting",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // সাবটাইটেল
                      // 🟢 Colors.slate পরিবর্তন করে Colors.grey ব্যবহার করা হয়েছে
                      Text(
                        "Track your daily finances effortlessly",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // গুগলের প্রিমিয়াম লগইন বাটন এবং কাস্টম লোডিং
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isLoggingIn
                            ? Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade800.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.teal.shade400.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xff2dd4bf),
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                "Connecting safely...",
                                style: TextStyle(
                                  color: Colors.teal.shade200,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                            : Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () async {
                              setState(() => _isLoggingIn = true);
                              try {
                                final user = await AuthService().signInWithGoogle();
                                if (user == null && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Login cancelled"),
                                      backgroundColor: Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Login failed: $e"),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoggingIn = false);
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://cdn-icons-png.flaticon.com/512/300/300221.png',
                                  height: 24,
                                  width: 24,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.g_translate, color: Colors.redAccent),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Continue with Google",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ফুটার নোট
                      // 🟢 Colors.slate পরিবর্তন করে Colors.grey ব্যবহার করা হয়েছে
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            "Secure login • Your data is safe",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}