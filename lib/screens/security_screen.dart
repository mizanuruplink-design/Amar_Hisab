import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/lock_service.dart';

class SecurityScreen extends StatefulWidget {
  final String selectedLanguage;
  final Map<String, Map<String, String>> localizedText;

  const SecurityScreen({
    super.key,
    required this.selectedLanguage,
    required this.localizedText,
  });

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final LockService _lockService = LockService();
  bool _lockEnabled = false;
  bool _hasBiometric = false;
  String _appVersion = '';
  String _buildNumber = '';
  bool _hasPinSaved = false;

  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _oldPinController = TextEditingController();

  String getText(String key) {
    return widget.localizedText[widget.selectedLanguage]?[key] ??
        widget.localizedText['bn']?[key] ??
        key;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
    _checkIfPinExists();
  }

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    _oldPinController.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    final enabled = await _lockService.isLockEnabled();
    final hasBio = await _lockService.isBiometricAvailable();
    if (mounted) setState(() {
      _lockEnabled = enabled;
      _hasBiometric = hasBio;
    });
  }

  Future<void> _checkIfPinExists() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin');
    if (mounted) setState(() {
      _hasPinSaved = pin != null && pin.isNotEmpty;
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ========== TOGGLE LOCK (without forcing PIN dialog) ==========
  Future<void> _toggleLock(bool value) async {
    if (value) {
      // Lock চালু করলে শুধু setLockEnabled(true) দিলেই হবে
      await _lockService.setLockEnabled(true);
      if (mounted) setState(() {
        _lockEnabled = true;
      });
      _showSnackBar('অ্যাপ লক চালু করা হয়েছে');
    } else {
      // লক বন্ধ করতে কনফার্মেশন নেওয়া হবে
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(getText('disable_lock')),
          content: Text(getText('disable_lock_confirm')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(getText('no'))),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(getText('yes'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _lockService.clearLock();
        if (mounted) setState(() {
          _lockEnabled = false;
          _hasPinSaved = false;
        });
        _showSnackBar(getText('lock_disabled'));
      }
    }
  }

  // ========== PIN SETUP ==========
  void _showPinSetupDialog() {
    _newPinController.clear();
    _confirmPinController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(getText('set_pin')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(labelText: getText('new_pin'), border: const OutlineInputBorder()),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(labelText: getText('confirm_pin'), border: const OutlineInputBorder()),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(getText('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (_newPinController.text.length == 4 && _newPinController.text == _confirmPinController.text) {
                await _lockService.savePin(_newPinController.text);
                // যদি লক ইতিমধ্যে অন না করা থাকে, তাহলে অন করে দিই
                if (!_lockEnabled) {
                  await _lockService.setLockEnabled(true);
                  if (mounted) setState(() => _lockEnabled = true);
                }
                if (mounted) setState(() => _hasPinSaved = true);
                Navigator.pop(ctx);
                _showSnackBar(getText('pin_set_success'));
              } else {
                _showSnackBar(getText('pin_mismatch'));
              }
            },
            child: Text(getText('save')),
          ),
        ],
      ),
    );
  }

  // ========== PIN CHANGE (requires old PIN) ==========
  void _showChangePinDialog() async {
    _oldPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();

    bool? verified = await _verifyCurrentPinDialog();
    if (verified != true) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('পিন পরিবর্তন করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'নতুন পিন', border: OutlineInputBorder()),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'নতুন পিন নিশ্চিত করুন', border: OutlineInputBorder()),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(getText('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (_newPinController.text.length == 4 && _newPinController.text == _confirmPinController.text) {
                await _lockService.savePin(_newPinController.text);
                if (!_lockEnabled) {
                  await _lockService.setLockEnabled(true);
                  if (mounted) setState(() => _lockEnabled = true);
                }
                if (mounted) setState(() => _hasPinSaved = true);
                Navigator.pop(ctx);
                _showSnackBar('পিন সফলভাবে পরিবর্তিত হয়েছে');
              } else {
                _showSnackBar(getText('pin_mismatch'));
              }
            },
            child: Text(getText('save')),
          ),
        ],
      ),
    );
  }

  Future<bool?> _verifyCurrentPinDialog() async {
    TextEditingController pinController = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পুরনো পিন দিন'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'বর্তমান পিন', border: OutlineInputBorder()),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(getText('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final enteredPin = pinController.text;
              final prefs = await SharedPreferences.getInstance();
              final savedPin = prefs.getString('user_pin');
              if (enteredPin == savedPin) {
                Navigator.pop(ctx, true);
              } else {
                _showSnackBar('পুরনো পিন ভুল, আবার চেষ্টা করুন');
                Navigator.pop(ctx, false);
              }
            },
            child: const Text('যাচাই করুন'),
          ),
        ],
      ),
    );
  }

  // ========== LOCK TYPE SETTERS ==========
  Future<void> _setLockType(String type) async {
    // লক অন না থাকলে আগে অন করে দিই
    if (!_lockEnabled) {
      await _lockService.setLockEnabled(true);
      if (mounted) setState(() => _lockEnabled = true);
    }
    await _lockService.setLockType(type);
    if (mounted) {
      _showSnackBar('লক টাইপ পরিবর্তন করা হয়েছে');
    }
  }

  // ========== UPDATE CHECK (unchanged) ==========
  Future<void> _checkForUpdate() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showSnackBar('No internet connection. Please check your network.');
      return;
    }
    _showSnackBar('Checking for updates...');
    String? remoteVersion;
    try {
      final ref = FirebaseDatabase.instance.ref('app_version/current');
      final snapshot = await ref.once();
      if (snapshot.snapshot.value != null) {
        remoteVersion = snapshot.snapshot.value.toString();
      } else {
        if (kDebugMode) {
          _showSnackBar('Debug: Please set app_version/current in Firebase Realtime Database.');
        }
      }
    } catch (e) {
      _showSnackBar('Could not check for updates. Please ensure you have an internet connection.');
      return;
    }
    if (remoteVersion == null || remoteVersion.isEmpty) {
      _showSnackBar('Unable to get version info. Please try again later.');
      return;
    }
    if (_isNewerVersion(remoteVersion, _appVersion)) {
      _showUpdateDialog(remoteVersion);
    } else {
      _showSnackBar('You are on the latest version (${_appVersion}+$_buildNumber).');
    }
  }

  bool _isNewerVersion(String remote, String current) {
    final remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < remoteParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (remoteParts[i] > currentParts[i]) return true;
      if (remoteParts[i] < currentParts[i]) return false;
    }
    return remoteParts.length > currentParts.length;
  }

  void _showUpdateDialog(String newVersion) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Update Available!'),
        content: Text('A new version ($newVersion) is available. Would you like to update?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              _launchUrl('https://play.google.com/store/apps/details?id=com.example.amar_hisab');
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Cannot open URL');
    }
  }

  // ========== PRIVACY & TERMS (simplified, same as before) ==========
  void _showPrivacyPolicy() {
    final privacyHtml = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; padding: 20px; line-height: 1.6; color: #333; }
        h1, h2 { color: #1976D2; }
        p, li { margin: 10px 0; }
        ul { padding-left: 20px; }
        .footer { font-size: 12px; color: #777; text-align: center; margin-top: 30px; }
      </style>
    </head>
    <body>
      <h1>Privacy Policy</h1>
      <p><strong>Effective date:</strong> 17 May 2026</p>
      <p>Md. Mizanur Rahman built the <strong>আমার হিসাব - দৈনিক আয় ব্যয় হিসাব</strong> app as an Ad Supported app. This SERVICE is provided by Md. Mizanur Rahman at no cost and is intended for use as is.</p>
      <p>This page is used to inform visitors regarding our policies with the collection, use, and disclosure of Personal Information if anyone decided to use our Service.</p>
      <h2>Information Collection and Use</h2>
      <p>For a better experience, while using our Service, we may require you to provide us with certain personally identifiable information. The information that we request will be retained by us and used as described in this privacy policy.</p>
      <div class="footer">© ${DateTime.now().year} আমার হিসাব. All rights reserved.</div>
    </body>
    </html>
    """;
    _showWebViewDialog(getText('privacy_policy'), privacyHtml);
  }

  void _showTermsOfService() {
    final termsHtml = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; padding: 20px; line-height: 1.6; color: #333; }
        h1, h2 { color: #1976D2; }
        p, li { margin: 10px 0; }
        ul { padding-left: 20px; }
        .footer { font-size: 12px; color: #777; text-align: center; margin-top: 30px; }
      </style>
    </head>
    <body>
      <h1>Terms of Service</h1>
      <p><strong>Last updated:</strong> 16 May 2026</p>
      <h2>1. Acceptance of Terms</h2>
      <p>By downloading, installing or using the <strong>আমার হিসাব</strong> application ("App"), you agree to be bound by these Terms of Service. If you do not agree, please do not use the App.</p>
      <div class="footer">© ${DateTime.now().year} আমার হিসাব. All rights reserved.</div>
    </body>
    </html>
    """;
    _showWebViewDialog(getText('terms_of_service'), termsHtml);
  }

  void _showWebViewDialog(String title, String htmlContent) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            body: WebViewWidget(
              controller: WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..loadHtmlString(htmlContent),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Text(getText('security_settings'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ---------- APP LOCK SWITCH (without forcing PIN dialog) ----------
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: SwitchListTile(
            title: Text(getText('app_lock'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(getText('app_lock_desc')),
            value: _lockEnabled,
            activeColor: Colors.blue,
            onChanged: (v) => _toggleLock(v),
          ),
        ),

        // লক অন থাকলেই নিচের অপশনগুলো দেখাবে
        if (_lockEnabled) ...[
          const SizedBox(height: 15),

          // ---------- PIN MANAGEMENT CARD ----------
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pin, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text('পিন কোড', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_hasPinSaved)
                    ElevatedButton.icon(
                      onPressed: _showChangePinDialog,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('পিন কোড পরিবর্তন করুন'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _showPinSetupDialog,
                      icon: const Icon(Icons.lock),
                      label: const Text('পিন কোড সেটআপ করুন'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ---------- BIOMETRIC OPTIONS CARD (if available) ----------
          if (_hasBiometric) ...[
            const SizedBox(height: 15),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fingerprint, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Text('বায়োমেট্রিক লক', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _setLockType('biometric'),
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('শুধুমাত্র বায়োমেট্রিক'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _setLockType('both'),
                            icon: const Icon(Icons.lock_open),
                            label: const Text('পিন + বায়োমেট্রিক'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],

        const SizedBox(height: 20),

        // ---------- ABOUT APP CARD ----------
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          child: ExpansionTile(
            leading: Icon(Icons.info_outline, color: Colors.blue.shade700),
            title: Text(getText('about_app'), style: const TextStyle(fontWeight: FontWeight.bold)),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.account_balance_wallet, size: 40, color: Colors.blue),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(getText('app_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Version $_appVersion+$_buildNumber', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Text(getText('app_description'), style: const TextStyle(height: 1.4)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.system_update_alt, color: Colors.blue),
                title: const Text('Check for Updates'),
                subtitle: Text('Current version: $_appVersion+$_buildNumber'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _checkForUpdate,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.blue),
                title: const Text('Developer'),
                subtitle: const Text('Md. Mizanur Rahman'),
                onTap: () => _launchUrl('mailto:md.mizanur.ete@gmail.com'),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined, color: Colors.blue),
                title: const Text('Support'),
                subtitle: const Text('md.mizanur.ete@gmail.com'),
                onTap: () => _launchUrl('mailto:md.mizanur.ete@gmail.com'),
              ),
              const Divider(height: 20),
              Center(child: Text('© ${DateTime.now().year} আমার হিসাব. All rights reserved.', style: TextStyle(color: Colors.grey[500], fontSize: 12))),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // ---------- PRIVACY & TERMS CARD ----------
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.blue),
                title: Text(getText('privacy_policy'), style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showPrivacyPolicy,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: Text(getText('terms_of_service'), style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showTermsOfService,
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // ---------- FAQ CARD ----------
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            leading: Icon(Icons.help_outline, color: Colors.green.shade700),
            title: Text(getText('faq_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildFaqTile(getText('faq_q1'), getText('faq_a1')),
              _buildFaqTile(getText('faq_q2'), getText('faq_a2')),
              _buildFaqTile(getText('faq_q3'), getText('faq_a3')),
              _buildFaqTile(getText('faq_q4'), getText('faq_a4')),
              _buildFaqTile(getText('faq_q5'), getText('faq_a5')),
              _buildFaqTile(getText('faq_q6'), getText('faq_a6')),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          Text(answer, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}