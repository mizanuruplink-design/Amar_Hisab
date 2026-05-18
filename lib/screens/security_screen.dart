import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  String _lockType = 'pin';
  bool _hasBiometric = false;
  String _appVersion = '';
  String _buildNumber = '';

  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

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
  }

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    final enabled = await _lockService.isLockEnabled();
    final type = await _lockService.getLockType();
    final hasBio = await _lockService.isBiometricAvailable();
    if (mounted) setState(() {
      _lockEnabled = enabled;
      _lockType = (type == 'none' || type.isEmpty) ? 'pin' : type;
      _hasBiometric = hasBio;
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _showPinSetupDialog() {
    _newPinController.clear();
    _confirmPinController.clear();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(getText('set_pin')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
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
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(getText('cancel'))),
        ElevatedButton(onPressed: () async {
          if (_newPinController.text.length == 4 && _newPinController.text == _confirmPinController.text) {
            await _lockService.savePin(_newPinController.text);
            await _lockService.setLockEnabled(true);
            await _lockService.setLockType(_lockType);
            if (mounted) setState(() => _lockEnabled = true);
            Navigator.pop(ctx);
            _showSnackBar(getText('pin_set_success'));
          } else {
            _showSnackBar(getText('pin_mismatch'));
          }
        }, child: Text(getText('save'))),
      ],
    ));
  }

  void _disableLock() async {
    final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(getText('disable_lock')),
      content: Text(getText('disable_lock_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(getText('no'))),
        ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text(getText('yes'), style: const TextStyle(color: Colors.white))),
      ],
    ));
    if (confirm == true) {
      await _lockService.clearLock();
      if (mounted) setState(() => _lockEnabled = false);
      _showSnackBar(getText('lock_disabled'));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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
        h3 { color: #333; margin-top: 20px; }
        p, li { margin: 10px 0; }
        ul { padding-left: 20px; }
        hr { margin: 20px 0; }
        .footer { font-size: 12px; color: #777; text-align: center; margin-top: 30px; }
      </style>
    </head>
    <body>
      <h1>Privacy Policy</h1>
      <p><strong>Effective date:</strong> 17 May 2026</p>
      <p>Md. Mizanur Rahman built the <strong>আমার হিসাব - দৈনিক আয় ব্যয় হিসাব</strong> app as an Ad Supported app. This SERVICE is provided by Md. Mizanur Rahman at no cost and is intended for use as is.</p>
      
      <p>This page is used to inform visitors regarding our policies with the collection, use, and disclosure of Personal Information if anyone decided to use our Service.</p>
      
      <p>If you choose to use our Service, then you agree to the collection and use of information in relation to this policy. The Personal Information that we collect is used for providing and improving the Service. We will not use or share your information with anyone except as described in this Privacy Policy.</p>
      
      <p>The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which are accessible at <strong>আমার হিসাব - দৈনিক আয় ব্যয় হিসাব</strong> unless otherwise defined in this Privacy Policy.</p>
      
      <h2>Information Collection and Use</h2>
      <p>For a better experience, while using our Service, we may require you to provide us with certain personally identifiable information. The information that we request will be retained by us and used as described in this privacy policy.</p>
      
      <p>To power the core features of the app, we request access to the following data and permissions:</p>
      <ul>
        <li><strong>Authentication & Identity:</strong> Your Email address and Google Profile information (via Firebase Authentication) to securely isolate your user account and ensure you only see your own personal data.</li>
        <li><strong>Financial & Budget Data:</strong> Total income, expenses, and budget limits strictly managed by you.</li>
        <li><strong>Notebook, Drawings & Notes:</strong> Local and cloud‑saved textual notes and canvas drawings created by you.</li>
        <li><strong>Device Storage & Media Access:</strong> Access to your internal storage/gallery to save and retrieve your custom profile pictures and local attachments.</li>
        <li><strong>Local Notifications & Alarms:</strong> Permission to trigger system reminders and notifications for your budgets and tasks.</li>
      </ul>
      
      <h2>Dual Functionality: Online and Offline Modes</h2>
      <p>Our application is designed with high data‑resilience and operates seamlessly in two ways:</p>
      <ul>
        <li><strong>Offline Mode:</strong> When you are disconnected from the internet, all your transactions, notebook entries, drawings, and budgets are saved locally and securely on your device's internal database.</li>
        <li><strong>Online Syncing:</strong> As soon as an active internet connection is detected, your locally queued data safely synchronizes with secure cloud servers (Firebase) under your encrypted and unique User ID (UID). This ensures you can seamlessly access your records across devices without data loss.</li>
      </ul>
      
      <h2>Data Safety & Privacy Isolation</h2>
      <p>We respect the privacy of your personal life and records.</p>
      <ul>
        <li><strong>Strict Multi‑User Isolation:</strong> Every piece of data—including budgets, notes, profile pictures, and drawings—is cryptographically mapped to your unique Firebase UID. No other user, regardless of their login status or email id, can access or view your storage.</li>
        <li><strong>Data Deletion:</strong> You retain absolute control over your information. Deleting your profile picture or records inside the app completely wipes that data from your local device preference (SharedPreferences) and the cloud.</li>
      </ul>
      
      <h2>Third‑Party Services</h2>
      <p>The app utilizes reliable third‑party services that may collect data to identify your device or serve advertisements.</p>
      <p>Link to the privacy policy of third‑party service providers used by the app:</p>
      <ul>
        <li><a href="https://policies.google.com/privacy">Google Play Services</a></li>
        <li><a href="https://support.google.com/admob/answer/6128543">AdMob</a></li>
        <li><a href="https://firebase.google.com/support/privacy">Google Analytics for Firebase</a></li>
        <li><a href="https://firebase.google.com/support/privacy">Firebase Crashlytics</a></li>
      </ul>
      
      <h2>Log Data</h2>
      <p>We want to inform you that whenever you use our Service, in a case of an error in the app we collect data and information (through third‑party products) on your phone called Log Data. This Log Data may include information such as your device Internet Protocol (“IP”) address, device name, operating system version, the configuration of the app when utilizing our Service, the time and date of your use of the Service, and other statistics.</p>
      
      <h2>Cookies & Local Caching</h2>
      <p>Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device's internal memory.</p>
      <p>This Service does not use these “cookies” explicitly. However, the app uses localized storage engines (like SQLite, Hive, or SharedPreferences) to securely cache your notes, financial ledger, sketches, and application settings on your internal storage. Third‑party ad networks may use anonymous tracking identifiers to serve relevant ads.</p>
      
      <h2>Service Providers</h2>
      <p>We may employ third‑party companies and individuals due to the following reasons:</p>
      <ul><li>To facilitate our Service;</li><li>To provide the Service on our behalf;</li><li>To perform Service‑related services; or</li><li>To assist us in analyzing how our Service is used.</li></ul>
      <p>We want to inform users of this Service that these third parties have access to their Personal Information. The reason is to perform the tasks assigned to them on our behalf. However, they are obligated not to disclose or use the information for any other purpose.</p>
      
      <h2>Security</h2>
      <p>We value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. All data transmission between the offline cache and online servers is handled through secure, encrypted SSL tunnels. However, please remember that no method of transmission over the internet, or method of electronic storage is 100% secure, and we cannot guarantee its absolute security.</p>
      
      <h2>Children’s Privacy</h2>
      <p>These Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13 years of age. In the case we discover that a child under 13 has provided us with personal information, we immediately delete this from our servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we will be able to do the necessary actions.</p>
      
      <h2>Changes to This Privacy Policy</h2>
      <p>We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page.</p>
      
      <p>This policy is effective as of 2026‑05‑17.</p>
      
      <h2>Contact Us</h2>
      <p>If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a>.</p>
      
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
      <h2>2. Description of Service</h2>
      <p>This App provides a personal finance management tool to record income, expenses, debts, credits, savings, and reminders. It also offers offline support, backup, and optional biometric lock.</p>
      <h2>3. User Accounts</h2>
      <p>To use the App, you must sign in with a valid email address. You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account.</p>
      <h2>4. User Data</h2>
      <p>All transaction data, notes, reminders and settings you enter are stored locally on your device and in Firebase Realtime Database under your user ID. We do not share your personal financial data with third parties except as required by law or to provide core services (e.g., Firebase).</p>
      <h2>5. Acceptable Use</h2>
      <p>You agree not to:</p>
      <ul><li>Use the App for any illegal purpose;</li><li>Reverse engineer, decompile or attempt to extract the source code;</li><li>Interfere with or disrupt the integrity or performance of the App;</li><li>Upload or transmit any malicious code or viruses.</li></ul>
      <h2>6. Intellectual Property</h2>
      <p>The App and its original content, features and functionality are owned by the developer and are protected by copyright, trademark and other laws.</p>
      <h2>7. Termination</h2>
      <p>We may terminate or suspend your access immediately without prior notice for any breach of these Terms. Upon termination, your right to use the App will cease.</p>
      <h2>8. Disclaimer of Warranties</h2>
      <p>The App is provided on an "AS IS" and "AS AVAILABLE" basis. We make no warranties, expressed or implied, regarding the accuracy, reliability, or availability of the App. Use of financial data is at your own risk.</p>
      <h2>9. Limitation of Liability</h2>
      <p>To the maximum extent permitted by law, the developer shall not be liable for any indirect, incidental, special, consequential or punitive damages arising out of or related to your use of the App, including loss of data or financial loss.</p>
      <h2>10. Changes to Terms</h2>
      <p>We reserve the right to modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the revised Terms.</p>
      <h2>11. Governing Law</h2>
      <p>These Terms shall be governed by the laws of Bangladesh, without regard to its conflict of law provisions.</p>
      <h2>12. Contact</h2>
      <p>If you have any questions about these Terms, please contact us at <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a>.</p>
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
        // ---------- LOCK SETTINGS CARD ----------
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: SwitchListTile(
            title: Text(getText('app_lock'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(getText('app_lock_desc')),
            value: _lockEnabled,
            activeColor: Colors.blue,
            onChanged: (v) { if (v) _showPinSetupDialog(); else _disableLock(); },
          ),
        ),
        if (_lockEnabled) ...[
          const SizedBox(height: 15),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(getText('lock_type'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                RadioListTile<String>(title: Text(getText('pin_only')), value: 'pin', groupValue: _lockType, onChanged: (v) { if (v != null) { setState(() => _lockType = v); _lockService.setLockType(v); } }),
                if (_hasBiometric) RadioListTile<String>(title: Text(getText('biometric_only')), value: 'biometric', groupValue: _lockType, onChanged: (v) { if (v != null) { setState(() => _lockType = v); _lockService.setLockType(v); } }),
                if (_hasBiometric) RadioListTile<String>(title: Text(getText('pin_and_biometric')), value: 'both', groupValue: _lockType, onChanged: (v) { if (v != null) { setState(() => _lockType = v); _lockService.setLockType(v); } }),
              ]),
            ),
          ),
          const SizedBox(height: 15),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.lock_reset, color: Colors.blue)),
              title: Text(getText('change_pin')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showPinSetupDialog,
            ),
          ),
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