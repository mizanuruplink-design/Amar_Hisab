import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  // 👇 আপনার রিমোট JSON ফাইলের URL (GitHub Gist বা আপনার সার্ভার)
  static const String versionCheckUrl =
      'https://raw.githubusercontent.com/yourusername/yourrepo/main/version.json';
  // JSON ফাইলের ফরম্যাট: {"latest_version": "1.2.3"}

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String localVersion = packageInfo.version;

      // রিমোট ভার্সন ফেচ করুন
      final response = await http.get(Uri.parse(versionCheckUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersion = data['latest_version'] ?? '';
        if (latestVersion.isNotEmpty) {
          if (_isNewerVersionAvailable(localVersion, latestVersion)) {
            _showUpdateDialog(context, latestVersion);
          } else {
            _showMessage(context, 'আপনার অ্যাপ আপডেটেড আছে');
          }
        } else {
          _showMessage(context, 'রিমোট ভার্সন তথ্য পাওয়া যায়নি');
        }
      } else {
        _showMessage(context, 'সার্ভার থেকে তথ্য আনতে ব্যর্থ');
      }
    } catch (e) {
      print('Update check failed: $e');
      _showMessage(context, 'ভার্সন চেক করতে সমস্যা হয়েছে। পরে আবার চেষ্টা করুন।');
    }
  }

  static bool _isNewerVersionAvailable(String current, String latest) {
    // সহজ উপায়: স্ট্রিং তুলনা (যদি '1.2.0' ফরম্যাট হয়)
    // নিখুঁত তুলনার জন্য `version_compare` প্যাকেজ ব্যবহার করতে পারেন
    return current != latest;
  }

  static void _showUpdateDialog(BuildContext context, String latestVersion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নতুন আপডেট পাওয়া গেছে!'),
        content: Text('আপডেট ভার্সন: $latestVersion\nপ্লে স্টোর থেকে ডাউনলোড করুন।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('পরে দেখুন'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: প্লে স্টোর লিংক ওপেন করুন (url_launcher প্যাকেজ ব্যবহার করুন)
              // await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=your.package.name'));
              Navigator.pop(context);
            },
            child: const Text('আপডেট করুন'),
          ),
        ],
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}