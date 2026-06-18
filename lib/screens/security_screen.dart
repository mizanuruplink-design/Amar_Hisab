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
  bool _hasBiometric = false;
  String _appVersion = '';
  String _buildNumber = '';
  bool _hasPinSaved = false;

  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _oldPinController = TextEditingController();

  // ==================== LOCALIZATION HELPER ====================
  String getText(String key) {
    final translated = widget.localizedText[widget.selectedLanguage]?[key];
    if (translated != null && translated.isNotEmpty) return translated;

    final fallback = {
      'bn': {
        'security_settings': 'সিকিউরিটি সেটিংস',
        'app_lock': 'অ্যাপ লক',
        'enable_pin_code': 'পিন কোড সক্রিয় করুন',
        'change_pin_code': 'পিন কোড পরিবর্তন করুন',
        'disable_pin_code': 'পিন কোড নিষ্ক্রিয় করুন',
        'biometric_options': 'বায়োমেট্রিক অপশন',
        'biometric_only': 'শুধুমাত্র বায়োমেট্রিক',
        'pin_and_biometric': 'পিন + বায়োমেট্রিক',
        'pin_required_for_biometric': 'বায়োমেট্রিক ব্যবহার করতে আগে পিন সেট করুন।',
        'lock_type_changed': 'লক টাইপ পরিবর্তন করা হয়েছে',
        'set_pin': 'পিন সেট করুন',
        'new_pin': 'নতুন পিন',
        'confirm_pin': 'পিন নিশ্চিত করুন',
        'pin_set_success': 'পিন সফলভাবে সেট করা হয়েছে',
        'pin_mismatch': 'পিন মেলেনি, আবার চেষ্টা করুন',
        'change_pin': 'পিন পরিবর্তন করুন',
        'old_pin': 'পুরনো পিন',
        'enter_old_pin': 'পুরনো পিন দিন',
        'wrong_old_pin': 'পুরনো পিন ভুল, আবার চেষ্টা করুন',
        'pin_changed_success': 'পিন সফলভাবে পরিবর্তিত হয়েছে',
        'disable_pin_confirm_title': 'পিন কোড নিষ্ক্রিয় করুন',
        'disable_pin_confirm': 'আপনি কি পিন কোড নিষ্ক্রিয় করতে চান?',
        'pin_disabled': 'পিন কোড নিষ্ক্রিয় করা হয়েছে',
        'save': 'সেভ',
        'cancel': 'বাতিল',
        'verify': 'যাচাই করুন',
        'yes': 'হ্যাঁ',
        'no': 'না',
        'about_app': 'অ্যাপ সম্পর্কে',
        'app_title': 'আমার হিসাব',
        'app_description': 'আমার হিসাব (Amar Hisab) হলো একটি আধুনিক, দ্রুত এবং অফলাইন-ফার্স্ট পার্সোনাল ফাইন্যান্স ম্যানেজমেন্ট ট্র্যাকার, যেখানে কোনো ঝামেলা ছাড়াই আপনি আপনার দৈনিক আয়-ব্যয়, বাজেট ও হিসাব-নিকাশ ট্র্যাক করতে পারবেন। কোনো সাইন-ইন বা অ্যাকাউন্ট খোলার ঝামেলা নেই। অ্যাপটি ওপেন করেই সরাসরি হিসাব শুরু করতে পারবেন। আপনার সমস্ত ডেটা সম্পূর্ণ সুরক্ষিতভাবে আপনার নিজের ফোনেই (Hive Database-এ) সেভ থাকে। চাইলে ১ ক্লিকে Google Drive-এ ব্যাকআপ রাখতে পারেন।',
        'current_version': 'বর্তমান ভার্সন:',
        'developer': 'ডেভেলপার',
        'support': 'সাপোর্ট',
        'all_rights_reserved': 'সর্বস্বত্ব সংরক্ষিত',
        'privacy_policy': 'গোপনীয়তা নীতি',
        'terms_of_service': 'সেবার শর্তাবলী',
        'faq_title': '🙋‍♂️ সাধারণ জিজ্ঞাসা',
        'faq_q1': 'অ্যাপটি ব্যবহার করতে কি জিমেইল দিয়ে লগইন করতে হবে?',
        'faq_a1': 'না, "আমার হিসাব" অ্যাপটি ব্যবহার করার জন্য কোনো জিমেইল আইডি বা অ্যাকাউন্ট খোলার প্রয়োজন নেই। অ্যাপটি ডাউনলোড করেই সরাসরি হিসাব রাখা শুরু করতে পারবেন।',
        'faq_q2': 'আমার ডেটাগুলো কোথায় সেভ থাকে?',
        'faq_a2': 'আপনার সমস্ত ডেটা সম্পূর্ণ অফলাইনে আপনার নিজের মোবাইল ফোনের মেমোরিতে (Hive Database) সেভ থাকে। কোনো অনলাইন সার্ভারে আপনার ডেটা পাঠানো হয় না।',
        'faq_q3': 'অ্যাপ আনইনস্টল হয়ে গেলে কি আমার ডেটা ফিরে পাবো?',
        'faq_a3': 'অ্যাপটি যদি গুগল ড্রাইভে ব্যাকআপ নেওয়া না থাকে, তবে অ্যাপ আনইনস্টল বা ফোন রিসেট দিলে লোকাল ডেটা সম্পূর্ণ ডিলিট হয়ে যাবে। যেহেতু আমরা কোনো ইউজার ডেটা সার্ভারে রাখি না, তাই ডেটা হারিয়ে গেলে তা রিকভার করার কোনো সুযোগ আমাদের কাছে নেই।',
        'faq_q4': 'গুগল ড্রাইভ ব্যাকআপ কিভাবে কাজ করে?',
        'faq_a4': 'অ্যাপের ব্যাকআপ সেকশনে গিয়ে আপনি আপনার যেকোনো একটি গুগল অ্যাকাউন্ট সিলেক্ট করে প্রথমবার ম্যানুয়ালি ব্যাকআপ সাকসেসফুল করবেন। একবার ড্রাইভের সাথে কানেক্ট হয়ে গেলে, পরবর্তীতে আপনার ফোনে ইন্টারনেট কানেকশন আসা মাত্রই অ্যাপটি ব্যাকগ্রাউন্ডে স্বয়ংক্রিয়ভাবে (Auto-Backup) আপনার লেটেস্ট ডেটা ড্রাইভে সেভ করে রাখবে।',
        'faq_q5': 'অটো-ব্যাকআপ হওয়ার জন্য কি প্রতিবার জিমেইল সিলেক্ট করতে হবে?',
        'faq_a5': 'না। জিমেইল অ্যাকাউন্ট এবং ড্রাইভের পারমিশন বা স্কোপ শুধুমাত্র প্রথমবার ব্যাকআপ নেওয়ার সময় একবারই দিতে হবে। এরপর থেকে ইন্টারনেট পেলেই অ্যাপ নিজে থেকেই অটো-ব্যাকআপের কাজ সম্পন্ন করবে।',
        'faq_q6': 'আমার ডেটা নিরাপদ রাখার দায়িত্ব কার?',
        'faq_a6': 'যেহেতু ডেটা আপনার নিজের ডিভাইসে থাকে, তাই এর সুরক্ষার দায়িত্ব সম্পূর্ণ আপনার। নিয়মিত ব্যাকআপ নেওয়ার পরামর্শ দেওয়া হচ্ছে।',
      },
      'en': {
        'security_settings': 'Security Settings',
        'app_lock': 'App Lock',
        'enable_pin_code': 'Enable PIN Code',
        'change_pin_code': 'Change PIN Code',
        'disable_pin_code': 'Disable PIN Code',
        'biometric_options': 'Biometric Options',
        'biometric_only': 'Biometric Only',
        'pin_and_biometric': 'PIN + Biometric',
        'pin_required_for_biometric': 'Please set a PIN first to use biometric.',
        'lock_type_changed': 'Lock type changed',
        'set_pin': 'Set PIN',
        'new_pin': 'New PIN',
        'confirm_pin': 'Confirm PIN',
        'pin_set_success': 'PIN set successfully',
        'pin_mismatch': 'PIN mismatch, try again',
        'change_pin': 'Change PIN',
        'old_pin': 'Old PIN',
        'enter_old_pin': 'Enter old PIN',
        'wrong_old_pin': 'Wrong old PIN, try again',
        'pin_changed_success': 'PIN changed successfully',
        'disable_pin_confirm_title': 'Disable PIN Code',
        'disable_pin_confirm': 'Do you want to disable PIN code?',
        'pin_disabled': 'PIN code disabled',
        'save': 'Save',
        'cancel': 'Cancel',
        'verify': 'Verify',
        'yes': 'Yes',
        'no': 'No',
        'about_app': 'About App',
        'app_title': 'My Accounting',
        'app_description': 'Amar Hisab is a modern, fast, offline-first personal finance management tracker. No sign-in or account creation required. All your data is stored securely on your device (Hive database). You can backup to Google Drive with one click.',
        'current_version': 'Current version:',
        'developer': 'Developer',
        'support': 'Support',
        'all_rights_reserved': 'All rights reserved',
        'privacy_policy': 'Privacy Policy',
        'terms_of_service': 'Terms of Service',
        'faq_title': '🙋‍♂️ Frequently Asked Questions',
        'faq_q1': 'Do I need to log in with Gmail to use the app?',
        'faq_a1': 'No, "Amar Hisab" does not require any Gmail ID or account creation. You can start tracking immediately after download.',
        'faq_q2': 'Where is my data stored?',
        'faq_a2': 'All your data is stored completely offline on your own device (Hive database). No data is sent to any online server.',
        'faq_q3': 'What happens if I uninstall the app?',
        'faq_a3': 'If you have not backed up to Google Drive, uninstalling or resetting your phone will permanently delete local data. Since we do not store user data on servers, lost data cannot be recovered.',
        'faq_q4': 'How does Google Drive backup work?',
        'faq_a4': 'Go to the backup section, select a Google account, and perform the first manual backup. Once connected, whenever internet is available, the app will automatically backup your latest data.',
        'faq_q5': 'Do I need to select Google account every time for auto-backup?',
        'faq_a5': 'No. You only need to grant permission once. After that, the app will auto-backup whenever internet is available.',
        'faq_q6': 'Who is responsible for my data security?',
        'faq_a6': 'Since data resides on your device, you are responsible for its security. Regular backups are recommended.',
      },
      'ar': {
        'security_settings': 'إعدادات الأمان',
        'app_lock': 'قفل التطبيق',
        'enable_pin_code': 'تفعيل رمز PIN',
        'change_pin_code': 'تغيير رمز PIN',
        'disable_pin_code': 'تعطيل رمز PIN',
        'biometric_options': 'خيارات القياسات الحيوية',
        'biometric_only': 'القياسات الحيوية فقط',
        'pin_and_biometric': 'PIN + القياسات الحيوية',
        'pin_required_for_biometric': 'يرجى تعيين رمز PIN أولاً لاستخدام القياسات الحيوية.',
        'lock_type_changed': 'تم تغيير نوع القفل',
        'set_pin': 'تعيين الرمز',
        'new_pin': 'رمز جديد',
        'confirm_pin': 'تأكيد الرمز',
        'pin_set_success': 'تم تعيين الرمز بنجاح',
        'pin_mismatch': 'الرمز غير متطابق، حاول مرة أخرى',
        'change_pin': 'تغيير الرمز',
        'old_pin': 'الرمز القديم',
        'enter_old_pin': 'أدخل الرمز القديم',
        'wrong_old_pin': 'الرمز القديم خاطئ، حاول مرة أخرى',
        'pin_changed_success': 'تم تغيير الرمز بنجاح',
        'disable_pin_confirm_title': 'تعطيل رمز PIN',
        'disable_pin_confirm': 'هل تريد تعطيل رمز PIN؟',
        'pin_disabled': 'تم تعطيل رمز PIN',
        'save': 'حفظ',
        'cancel': 'إلغاء',
        'verify': 'تحقق',
        'yes': 'نعم',
        'no': 'لا',
        'about_app': 'عن التطبيق',
        'app_title': 'محاسبتي',
        'app_description': 'تطبيق سريع وحديث لإدارة التمويل الشخصي دون الحاجة إلى تسجيل الدخول. يتم تخزين جميع بياناتك محليًا على جهازك.',
        'current_version': 'الإصدار الحالي:',
        'developer': 'المطور',
        'support': 'الدعم',
        'all_rights_reserved': 'جميع الحقوق محفوظة',
        'privacy_policy': 'سياسة الخصوصية',
        'terms_of_service': 'شروط الخدمة',
        'faq_title': '🙋‍♂️ الأسئلة الشائعة',
        'faq_q1': 'هل أحتاج إلى تسجيل الدخول باستخدام Gmail لاستخدام التطبيق؟',
        'faq_a1': 'لا، التطبيق لا يتطلب أي معرف Gmail أو إنشاء حساب. يمكنك البدء فورًا بعد التثبيت.',
        'faq_q2': 'أين يتم تخزين بياناتي؟',
        'faq_a2': 'يتم تخزين جميع بياناتك في وضع عدم الاتصال على جهازك الخاص (قاعدة بيانات Hive). لا يتم إرسال أي بيانات إلى أي خادم عبر الإنترنت.',
        'faq_q3': 'ماذا يحدث إذا قمت بإلغاء تثبيت التطبيق؟',
        'faq_a3': 'إذا لم تقم بعمل نسخة احتياطية على Google Drive، فإن إلغاء التثبيت أو إعادة ضبط الهاتف سيؤدي إلى حذف البيانات المحلية بالكامل. نظرًا لأننا لا نخزن بيانات المستخدم على الخوادم، فلا يمكن استرداد البيانات المفقودة.',
        'faq_q4': 'كيف يعمل النسخ الاحتياطي على Google Drive؟',
        'faq_a4': 'اذهب إلى قسم النسخ الاحتياطي، اختر حساب Google، وقم بأول نسخة احتياطية يدوية. بمجرد الاتصال، سيقوم التطبيق تلقائيًا بنسخ أحدث بياناتك احتياطيًا كلما كان الإنترنت متاحًا.',
        'faq_q5': 'هل أحتاج إلى تحديد حساب Google في كل مرة للنسخ الاحتياطي التلقائي؟',
        'faq_a5': 'لا. تحتاج فقط إلى منح الإذن مرة واحدة. بعد ذلك، سيقوم التطبيق بالنسخ الاحتياطي التلقائي كلما كان الإنترنت متاحًا.',
        'faq_q6': 'من المسؤول عن أمان بياناتي؟',
        'faq_a6': 'بما أن البيانات موجودة على جهازك، فأنت مسؤول عن أمانها. يوصى بعمل نسخ احتياطية منتظمة.',
      },
    };

    return fallback[widget.selectedLanguage]?[key] ?? fallback['en']?[key] ?? key;
  }

  // ==================== LIFECYCLE ====================
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

  Future<void> _loadSettings() async {
    final enabled = await _lockService.isLockEnabled();
    final hasBio = await _lockService.isBiometricAvailable();
    final pinExists = await _lockService.hasPin();
    if (mounted) {
      setState(() {
        _lockEnabled = enabled && pinExists;
        _hasBiometric = hasBio;
        _hasPinSaved = pinExists;
      });
    }
  }

  Future<void> _checkIfPinExists() async {
    final exists = await _lockService.hasPin();
    if (mounted) setState(() => _hasPinSaved = exists);
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ==================== PIN MANAGEMENT (unchanged) ====================
  Future<void> _showPinSetupDialog() async {
    _newPinController.clear();
    _confirmPinController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(getText('set_pin'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                await _lockService.setLockEnabled(true);
                if (mounted) {
                  setState(() {
                    _hasPinSaved = true;
                    _lockEnabled = true;
                  });
                }
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

  Future<void> _showChangePinDialog() async {
    _oldPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();
    bool verified = await _verifyOldPinDialog();
    if (!verified) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(getText('change_pin'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(labelText: getText('new_pin'), border: const OutlineInputBorder()),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(labelText: getText('confirm_pin'), border: const OutlineInputBorder()),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(getText('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (_newPinController.text.length != 4) {
                _showSnackBar('PIN must be 4 digits');
                return;
              }
              if (_newPinController.text != _confirmPinController.text) {
                _showSnackBar(getText('pin_mismatch'));
                return;
              }
              await _lockService.savePin(_newPinController.text);
              await _lockService.setLockEnabled(true);
              if (mounted) {
                setState(() {
                  _hasPinSaved = true;
                  _lockEnabled = true;
                });
              }
              Navigator.pop(ctx);
              _showSnackBar(getText('pin_changed_success'));
            },
            child: Text(getText('save')),
          ),
        ],
      ),
    );
  }

  Future<bool> _verifyOldPinDialog() async {
    TextEditingController pinController = TextEditingController();
    bool verified = false;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(getText('enter_old_pin'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: InputDecoration(labelText: getText('old_pin'), border: const OutlineInputBorder()),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(getText('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final enteredPin = pinController.text.trim();
              final isValid = await _lockService.verifyPin(enteredPin);
              if (isValid) {
                verified = true;
                Navigator.pop(ctx);
              } else {
                _showSnackBar(getText('wrong_old_pin'));
              }
            },
            child: Text(getText('verify')),
          ),
        ],
      ),
    );
    pinController.dispose();
    return verified;
  }

  Future<void> _disablePinCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(getText('disable_pin_confirm_title')),
        content: Text(getText('disable_pin_confirm')),
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
      await _checkIfPinExists();
      if (mounted) setState(() => _lockEnabled = false);
      _showSnackBar(getText('pin_disabled'));
    }
  }

  Future<void> _setLockType(String type) async {
    if (!_hasPinSaved) {
      _showSnackBar(getText('pin_required_for_biometric'));
      return;
    }
    if (!_lockEnabled) {
      await _lockService.setLockEnabled(true);
      if (mounted) setState(() => _lockEnabled = true);
    }
    await _lockService.setLockType(type);
    if (mounted) _showSnackBar(getText('lock_type_changed'));
  }

  // ==================== EMAIL & CLIPBOARD ====================
  void _handleEmailTap(String email) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text(getText('support')),
              onTap: () async {
                Navigator.pop(ctx);
                final Uri emailUri = Uri(scheme: 'mailto', path: email);
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                } else {
                  await Clipboard.setData(ClipboardData(text: email));
                  _showSnackBar('Email copied to clipboard');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.green),
              title: Text('Copy Email Address'),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: email));
                _showSnackBar('Email copied to clipboard');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LEGAL DOCUMENTS (UPDATED HTML) ====================
  void _showPrivacyPolicy() {
    String htmlContent;
    if (widget.selectedLanguage == 'bn') {
      htmlContent = _getPrivacyPolicyBangla();
    } else if (widget.selectedLanguage == 'ar') {
      htmlContent = _getPrivacyPolicyArabic();
    } else {
      htmlContent = _getPrivacyPolicyEnglish();
    }
    _showWebViewDialog(getText('privacy_policy'), htmlContent);
  }

  void _showTermsOfService() {
    String htmlContent;
    if (widget.selectedLanguage == 'bn') {
      htmlContent = _getTermsBangla();
    } else if (widget.selectedLanguage == 'ar') {
      htmlContent = _getTermsArabic();
    } else {
      htmlContent = _getTermsEnglish();
    }
    _showWebViewDialog(getText('terms_of_service'), htmlContent);
  }

  void _showWebViewDialog(String title, String htmlContent) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))],
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

  // ----- Privacy Policy (Bengali) - Updated -----
  String _getPrivacyPolicyBangla() {
    return """
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;}</style>
    </head>
    <body>
      <h1>গোপনীয়তা নীতি</h1>
      <p><strong>সর্বশেষ আপডেট:</strong> জুন ২০২৬</p>
      
      <h2>১. ডেটা সংগ্রহ (Data Collection)</h2>
      <p>"আমার হিসাব" অ্যাপটি ব্যবহার করার জন্য কোনো জিমেইল আইডি, নাম, ফোন নম্বর বা ব্যক্তিগত তথ্য দিয়ে সাইন-ইন বা অ্যাকাউন্ট তৈরি করার প্রয়োজন নেই। অ্যাপটি ব্যবহারকারীর কোনো ব্যক্তিগত তথ্য আমাদের নিজস্ব কোনো সার্ভারে সংগ্রহ বা সংরক্ষণ করে না।</p>
      
      <h2>২. ডেটা স্টোরেজ ও নিরাপত্তা (Data Storage & Security)</h2>
      <p>আপনার ইনপুট করা সমস্ত লেনদেন, বাজেট এবং হিসাবের ডেটা সম্পূর্ণ অফলাইনে আপনার ডিভাইসের লোকাল স্টোরেজে (Hive Database) সংরক্ষিত থাকে। যেহেতু ডেটা আপনার নিজের ডিভাইসে থাকে, তাই এর সুরক্ষার দায়িত্ব সম্পূর্ণ আপনার।</p>
      
      <h2>৩. গুগল ড্রাইভ ব্যাকআপ (Google Drive Backup)</h2>
      <p>অ্যাপটিতে অনলাইন ব্যাকআপের জন্য Google Drive API ব্যবহার করা হয়েছে। ব্যবহারকারী যখন ব্যাকআপ অপশনটি চালু করবেন, তখন অ্যাপটি সরাসরি ব্যবহারকারীর নিজস্ব গুগল ড্রাইভে একটি এনক্রিপ্টেড ব্যাকআপ ফাইল তৈরি করবে। এই ফাইলের কোনো অ্যাক্সেস আমাদের (ডেভেলপারের) কাছে থাকে না।</p>
      
      <h2>৪. থার্ড-পার্টি সার্ভিস (Third-Party Services)</h2>
      <p>অ্যাপটি ব্যাকআপ ফিচার সচল করার জন্য Google Sign-In এবং Google Drive SDK ব্যবহার করে। এই সার্ভিসগুলোর গোপনীয়তা নীতি গুগলের নিজস্ব পলিসি দ্বারা নিয়ন্ত্রিত হয়।</p>
      
      <h2>যোগাযোগ</h2>
      <p>যেকোনো প্রশ্নে ইমেইল করুন: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ২০২৪-২০২৬ আমার হিসাব</div>
    </body>
    </html>
    """;
  }

  // ----- Privacy Policy (English) - Updated -----
  String _getPrivacyPolicyEnglish() {
    return """
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;}</style>
    </head>
    <body>
      <h1>Privacy Policy</h1>
      <p><strong>Last updated:</strong> June 2026</p>
      
      <h2>1. Data Collection</h2>
      <p>No sign-in or account creation is required to use "Amar Hisab". The app does not collect any personal information such as email, name, or phone number. No user data is sent to our own servers.</p>
      
      <h2>2. Data Storage & Security</h2>
      <p>All transactions, budgets, and accounting data are stored completely offline on your device (Hive database). Since data resides on your device, you are solely responsible for its security.</p>
      
      <h2>3. Google Drive Backup</h2>
      <p>The app uses Google Drive API for online backup. When you enable backup, the app creates an encrypted backup file directly in your personal Google Drive. The developer has no access to this file.</p>
      
      <h2>4. Third‑Party Services</h2>
      <p>This app uses Google Sign-In and Google Drive SDK for backup functionality. Those services are governed by Google's own privacy policies.</p>
      
      <h2>Contact</h2>
      <p>Email: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© 2024-2026 আমার হিসাব</div>
    </body>
    </html>
    """;
  }

  // ----- Privacy Policy (Arabic) - Updated (simplified, based on English) -----
  String _getPrivacyPolicyArabic() {
    return """
    <!DOCTYPE html>
    <html dir="rtl">
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;}</style>
    </head>
    <body>
      <h1>سياسة الخصوصية</h1>
      <p><strong>آخر تحديث:</strong> يونيو ٢٠٢٦</p>
      
      <h2>١. جمع البيانات</h2>
      <p>لا حاجة لتسجيل الدخول أو إنشاء حساب لاستخدام "محاسبتي". لا يجمع التطبيق أي معلومات شخصية مثل البريد الإلكتروني أو الاسم أو رقم الهاتف. لا يتم إرسال أي بيانات مستخدم إلى خوادمنا الخاصة.</p>
      
      <h2>٢. تخزين البيانات وأمانها</h2>
      <p>يتم تخزين جميع المعاملات والميزانيات والبيانات المحاسبية دون اتصال بالإنترنت على جهازك (قاعدة بيانات Hive). نظرًا لأن البيانات موجودة على جهازك، فأنت وحدك المسؤول عن أمانها.</p>
      
      <h2>٣. النسخ الاحتياطي على Google Drive</h2>
      <p>يستخدم التطبيق واجهة برمجة تطبيقات Google Drive للنسخ الاحتياطي عبر الإنترنت. عند تمكين النسخ الاحتياطي، يقوم التطبيق بإنشاء ملف نسخ احتياطي مشفر مباشرة في Google Drive الشخصي الخاص بك. المطور لا يمكنه الوصول إلى هذا الملف.</p>
      
      <h2>٤. خدمات الطرف الثالث</h2>
      <p>يستخدم هذا التطبيق تسجيل الدخول عبر Google و Google Drive SDK لوظيفة النسخ الاحتياطي. تخضع هذه الخدمات لسياسات الخصوصية الخاصة بشركة Google.</p>
      
      <h2>اتصل بنا</h2>
      <p>البريد الإلكتروني: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ٢٠٢٤-٢٠٢٦ আমার হিসাব</div>
    </body>
    </html>
    """;
  }

  // ----- Terms of Service (Bengali) - Updated -----
  String _getTermsBangla() {
    return """
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;}</style>
    </head>
    <body>
      <h1>সেবার শর্তাবলী</h1>
      <p><strong>সর্বশেষ সংশোধন:</strong> জুন ২০২৬</p>
      
      <h2>১. অ্যাপের ব্যবহার</h2>
      <p>"আমার হিসাব" অ্যাপটি ব্যক্তিগত ব্যবহারের জন্য সম্পূর্ণ ফ্রি। অ্যাপটি কোনো অ্যাকাউন্ট ছাড়াই সরাসরি ব্যবহার করা যাবে।</p>
      
      <h2>২. ব্যবহারকারীর ডেটার দায়বদ্ধতা (গুরুত্বপূর্ণ)</h2>
      <p>আমরা (অ্যাপ কর্তৃপক্ষ বা ডেভেলপার) ব্যবহারকারীর কোনো ডেটার দায়িত্ব বা দায়বদ্ধতা গ্রহণ করি না। আপনার ফোনের সমস্ত ডেটা লোকাল ডিভাইসে থাকে। ফোন হারিয়ে গেলে, অ্যাপ আনইনস্টল করলে, ফোন রিসেট দিলে বা ডিভাইস ড্যামেজ হলে যদি কোনো ডেটা হারিয়ে যায়, তবে তার জন্য ডেভেলপার কোনোভাবেই দায়ী থাকবে না। ব্যবহারকারীকে নিজ দায়িত্বে ব্যাকআপ ফাইল শেয়ার বা ড্রাইভে সংরক্ষণ করে রাখতে হবে।</p>
      
      <h2>৩. ব্যাকআপ ও অটো-ব্যাকআপ</h2>
      <p>ব্যবহারকারী যদি তার ডেটা সুরক্ষিত রাখতে চান, তবে তাকে অবশ্যই গুগল ড্রাইভ বা লোকাল ব্যাকআপ ফিচারটি ব্যবহার করতে হবে। প্রথমবার সফলভাবে ড্রাইভে ব্যাকআপ নেওয়ার পর, ইন্টারনেট কানেকশন (WiFi বা Mobile Data) সক্রিয় থাকলে অ্যাপটি স্বয়ংক্রিয়ভাবে (Auto Backup) ডেটা আপডেট করে নেবে। তবে নেটওয়ার্ক সমস্যার কারণে ব্যাকআপ ফেইল হলে তার দায় ব্যবহারকারীর।</p>
      
      <h2>৪. পরিবর্তন ও সংশোধন</h2>
      <p>কর্তৃপক্ষ যেকোনো সময় অ্যাপের শর্তাবলী পরিবর্তন করার অধিকার সংরক্ষণ করে।</p>
      
      <h2>যোগাযোগ</h2>
      <p>ইমেইল: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ২০২৪-২০২৬ আমার হিসাব</div>
    </body>
    </html>
    """;
  }

  // ----- Terms of Service (English) - Updated -----
  String _getTermsEnglish() {
    return """
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;}</style>
    </head>
    <body>
      <h1>Terms of Service</h1>
      <p><strong>Last updated:</strong> June 2026</p>
      
      <h2>1. App Usage</h2>
      <p>"Amar Hisab" is completely free for personal use. No account is required to use the app.</p>
      
      <h2>2. User Data Responsibility (CRITICAL)</h2>
      <p>We (the app authority or developer) do not accept any responsibility or liability for user data. All data resides locally on your device. If you lose your phone, uninstall the app, factory reset your device, or suffer device damage, any data loss is not the developer's responsibility. It is your sole responsibility to keep backup files shared or stored on Drive.</p>
      
      <h2>3. Backup & Auto-Backup</h2>
      <p>If you wish to protect your data, you must use the Google Drive or local backup feature. After the first successful Drive backup, whenever internet (WiFi or mobile data) is available, the app will automatically update your backup. However, the user is responsible for any backup failure due to network issues.</p>
      
      <h2>4. Modifications</h2>
      <p>The authority reserves the right to modify the app's terms at any time.</p>
      
      <h2>Contact</h2>
      <p>Email: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© 2024-2026 আমার হিসাব</div>
    </body>
    </html>
    """;
  }

  // ----- Terms of Service (Arabic) - Updated (simplified) -----
  String _getTermsArabic() {
    return """
    <!DOCTYPE html>
    <html dir="rtl">
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;}</style>
    </head>
    <body>
      <h1>شروط الخدمة</h1>
      <p><strong>آخر تحديث:</strong> يونيو ٢٠٢٦</p>
      
      <h2>١. استخدام التطبيق</h2>
      <p>تطبيق "محاسبتي" مجاني تمامًا للاستخدام الشخصي. لا يلزم وجود حساب لاستخدام التطبيق.</p>
      
      <h2>٢. مسؤولية بيانات المستخدم (هام للغاية)</h2>
      <p>نحن (سلطة التطبيق أو المطور) لا نتحمل أي مسؤولية أو التزام تجاه بيانات المستخدم. توجد جميع البيانات محليًا على جهازك. إذا فقدت هاتفك، أو ألغيت تثبيت التطبيق، أو أعدت ضبط المصنع لجهازك، أو تعرض جهازك للتلف، فإن فقدان البيانات ليس مسؤولية المطور. تقع على عاتقك وحدك مسؤولية الاحتفاظ بنسخ احتياطية من الملفات المشتركة أو المخزنة على Drive.</p>
      
      <h2>٣. النسخ الاحتياطي والتلقائي</h2>
      <p>إذا كنت ترغب في حماية بياناتك، فيجب عليك استخدام ميزة النسخ الاحتياطي على Google Drive أو المحلي. بعد أول نسخة احتياطية ناجحة على Drive، كلما كان الإنترنت (WiFi أو بيانات الجوال) متاحًا، سيقوم التطبيق تلقائيًا بتحديث نسختك الاحتياطية. ومع ذلك، يتحمل المستخدم مسؤولية أي فشل في النسخ الاحتياطي بسبب مشاكل الشبكة.</p>
      
      <h2>٤. التعديلات</h2>
      <p>تحتفظ السلطة بالحق في تعديل شروط التطبيق في أي وقت.</p>
      
      <h2>اتصل بنا</h2>
      <p>البريد الإلكتروني: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ٢٠٢٤-٢٠٢٦ আমার হিসাব</div>
    </body>
    </html>
    """;
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Text(getText('security_settings'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Lock Card (unchanged)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.lock_outline, color: Colors.blue.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(getText('app_lock'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (!_hasPinSaved)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showPinSetupDialog,
                            icon: const Icon(Icons.lock),
                            label: Text(getText('enable_pin_code')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showChangePinDialog,
                            icon: const Icon(Icons.lock_outline),
                            label: Text(getText('change_pin_code')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _disablePinCode,
                            icon: const Icon(Icons.lock_open),
                            label: Text(getText('disable_pin_code')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade700),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_hasBiometric) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(getText('biometric_options'), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.purple.shade700)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _hasPinSaved ? () => _setLockType('biometric') : null,
                                icon: const Icon(Icons.fingerprint),
                                label: Text(getText('biometric_only')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _hasPinSaved ? () => _setLockType('both') : null,
                                icon: const Icon(Icons.lock_open),
                                label: Text(getText('pin_and_biometric')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!_hasPinSaved)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(getText('pin_required_for_biometric'), style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // About App Card (updated description from fallback)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.info_outline, color: Colors.blue.shade700),
              ),
              title: Text(getText('about_app'), style: const TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.account_balance_wallet, size: 40, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(getText('app_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${getText('current_version')} $_appVersion', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(getText('app_description'), style: const TextStyle(height: 1.4)),
                const SizedBox(height: 20),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.blue),
                  title: Text(getText('developer')),
                  subtitle: const Text('Md. Mizanur Rahman'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: Colors.blue),
                  title: Text(getText('support')),
                  subtitle: const Text('md.mizanur.ete@gmail.com'),
                  onTap: () => _handleEmailTap('md.mizanur.ete@gmail.com'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '© ${DateTime.now().year} ${getText('app_title')}. ${getText('all_rights_reserved')}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Legal Documents Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.privacy_tip, color: Colors.blue),
                  ),
                  title: Text(getText('privacy_policy'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showPrivacyPolicy,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.description, color: Colors.blue),
                  ),
                  title: Text(getText('terms_of_service'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showTermsOfService,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // FAQ Card (updated Q/A from fallback)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.help_outline, color: Colors.green.shade700),
              ),
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
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Text(answer, style: TextStyle(height: 1.5, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}