import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String localVersion = packageInfo.version;

      final RemoteConfig remoteConfig = RemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 20),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.fetchAndActivate();
      final String latestVersion = remoteConfig.getString('latest_version');

      if (_isNewerVersionAvailable(localVersion, latestVersion)) {
        _showUpdateDialog(context, latestVersion);
      } else {
        _showMessage(context, 'আপনার অ্যাপ আপডেটেড আছে');
      }
    } catch (e) {
      print('Update check failed: $e');
      _showMessage(context, 'Unable to get version info. Please try again later.');
    }
  }

  static bool _isNewerVersionAvailable(String current, String latest) {
    // সহজ উপায়: সরাসরি স্ট্রিং তুলনা (যদি '1.2.0' ফরম্যাট হয়)
    return current != latest;
    // আরও নিখুঁত পদ্ধতি চাইলে version_compare প্যাকেজ ব্যবহার করতে পারেন
  }

  static void _showUpdateDialog(BuildContext context, String latestVersion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('নতুন আপডেট পাওয়া গেছে!'),
        content: Text('আপডেট ভার্সন: $latestVersion\nপ্লে স্টোর থেকে ডাউনলোড করুন।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('পরে দেখুন'),
          ),
          ElevatedButton(
            onPressed: () {
              // প্লে স্টোর লিংক ওপেন করুন
              // openPlayStore();
              Navigator.pop(context);
            },
            child: Text('আপডেট করুন'),
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