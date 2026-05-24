import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/lock_service.dart';
import 'package:flutter/services.dart';

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
    final translated = widget.localizedText[widget.selectedLanguage]?[key];
    if (translated != null && translated.isNotEmpty) return translated;

    // Full 3‑language fallback
    switch (key) {
      case 'security_settings':
        if (widget.selectedLanguage == 'bn') return 'সিকিউরিটি সেটিংস';
        if (widget.selectedLanguage == 'ar') return 'إعدادات الأمان';
        return 'Security Settings';
      case 'app_lock':
        if (widget.selectedLanguage == 'bn') return 'অ্যাপ লক';
        if (widget.selectedLanguage == 'ar') return 'قفل التطبيق';
        return 'App Lock';
      case 'enable_pin_code':
        if (widget.selectedLanguage == 'bn') return 'পিন কোড সক্রিয় করুন';
        if (widget.selectedLanguage == 'ar') return 'تفعيل رمز PIN';
        return 'Enable PIN Code';
      case 'change_pin_code':
        if (widget.selectedLanguage == 'bn') return 'পিন কোড পরিবর্তন করুন';
        if (widget.selectedLanguage == 'ar') return 'تغيير رمز PIN';
        return 'Change PIN Code';
      case 'disable_pin_code':
        if (widget.selectedLanguage == 'bn') return 'পিন কোড নিষ্ক্রিয় করুন';
        if (widget.selectedLanguage == 'ar') return 'تعطيل رمز PIN';
        return 'Disable PIN Code';
      case 'biometric_options':
        if (widget.selectedLanguage == 'bn') return 'বায়োমেট্রিক অপশন';
        if (widget.selectedLanguage == 'ar') return 'خيارات القياسات الحيوية';
        return 'Biometric Options';
      case 'biometric_only':
        if (widget.selectedLanguage == 'bn') return 'শুধুমাত্র বায়োমেট্রিক';
        if (widget.selectedLanguage == 'ar') return 'القياسات الحيوية فقط';
        return 'Biometric Only';
      case 'pin_and_biometric':
        if (widget.selectedLanguage == 'bn') return 'পিন + বায়োমেট্রিক';
        if (widget.selectedLanguage == 'ar') return 'PIN + القياسات الحيوية';
        return 'PIN + Biometric';
      case 'pin_required_for_biometric':
        if (widget.selectedLanguage == 'bn') return 'বায়োমেট্রিক ব্যবহার করতে আগে পিন সেট করুন।';
        if (widget.selectedLanguage == 'ar') return 'يرجى تعيين رمز PIN أولاً لاستخدام القياسات الحيوية.';
        return 'Please set a PIN first to use biometric.';
      case 'lock_type_changed':
        if (widget.selectedLanguage == 'bn') return 'লক টাইপ পরিবর্তন করা হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تم تغيير نوع القفل';
        return 'Lock type changed';
      case 'set_pin':
        if (widget.selectedLanguage == 'bn') return 'পিন সেট করুন';
        if (widget.selectedLanguage == 'ar') return 'تعيين الرمز';
        return 'Set PIN';
      case 'new_pin':
        if (widget.selectedLanguage == 'bn') return 'নতুন পিন';
        if (widget.selectedLanguage == 'ar') return 'رمز جديد';
        return 'New PIN';
      case 'confirm_pin':
        if (widget.selectedLanguage == 'bn') return 'পিন নিশ্চিত করুন';
        if (widget.selectedLanguage == 'ar') return 'تأكيد الرمز';
        return 'Confirm PIN';
      case 'pin_set_success':
        if (widget.selectedLanguage == 'bn') return 'পিন সফলভাবে সেট করা হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تم تعيين الرمز بنجاح';
        return 'PIN set successfully';
      case 'pin_mismatch':
        if (widget.selectedLanguage == 'bn') return 'পিন মেলেনি, আবার চেষ্টা করুন';
        if (widget.selectedLanguage == 'ar') return 'الرمز غير متطابق، حاول مرة أخرى';
        return 'PIN mismatch, try again';
      case 'change_pin':
        if (widget.selectedLanguage == 'bn') return 'পিন পরিবর্তন করুন';
        if (widget.selectedLanguage == 'ar') return 'تغيير الرمز';
        return 'Change PIN';
      case 'old_pin':
        if (widget.selectedLanguage == 'bn') return 'পুরনো পিন';
        if (widget.selectedLanguage == 'ar') return 'الرمز القديم';
        return 'Old PIN';
      case 'enter_old_pin':
        if (widget.selectedLanguage == 'bn') return 'পুরনো পিন দিন';
        if (widget.selectedLanguage == 'ar') return 'أدخل الرمز القديم';
        return 'Enter old PIN';
      case 'wrong_old_pin':
        if (widget.selectedLanguage == 'bn') return 'পুরনো পিন ভুল, আবার চেষ্টা করুন';
        if (widget.selectedLanguage == 'ar') return 'الرمز القديم خاطئ، حاول مرة أخرى';
        return 'Wrong old PIN, try again';
      case 'pin_changed_success':
        if (widget.selectedLanguage == 'bn') return 'পিন সফলভাবে পরিবর্তিত হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تم تغيير الرمز بنجاح';
        return 'PIN changed successfully';
      case 'disable_pin_confirm_title':
        if (widget.selectedLanguage == 'bn') return 'পিন কোড নিষ্ক্রিয় করুন';
        if (widget.selectedLanguage == 'ar') return 'تعطيل رمز PIN';
        return 'Disable PIN Code';
      case 'disable_pin_confirm':
        if (widget.selectedLanguage == 'bn') return 'আপনি কি পিন কোড নিষ্ক্রিয় করতে চান?';
        if (widget.selectedLanguage == 'ar') return 'هل تريد تعطيل رمز PIN؟';
        return 'Do you want to disable PIN code?';
      case 'pin_disabled':
        if (widget.selectedLanguage == 'bn') return 'পিন কোড নিষ্ক্রিয় করা হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تم تعطيل رمز PIN';
        return 'PIN code disabled';
      case 'save':
        if (widget.selectedLanguage == 'bn') return 'সেভ';
        if (widget.selectedLanguage == 'ar') return 'حفظ';
        return 'Save';
      case 'cancel':
        if (widget.selectedLanguage == 'bn') return 'বাতিল';
        if (widget.selectedLanguage == 'ar') return 'إلغاء';
        return 'Cancel';
      case 'verify':
        if (widget.selectedLanguage == 'bn') return 'যাচাই করুন';
        if (widget.selectedLanguage == 'ar') return 'تحقق';
        return 'Verify';
      case 'yes':
        if (widget.selectedLanguage == 'bn') return 'হ্যাঁ';
        if (widget.selectedLanguage == 'ar') return 'نعم';
        return 'Yes';
      case 'no':
        if (widget.selectedLanguage == 'bn') return 'না';
        if (widget.selectedLanguage == 'ar') return 'لا';
        return 'No';
      case 'about_app':
        if (widget.selectedLanguage == 'bn') return 'অ্যাপ সম্পর্কে';
        if (widget.selectedLanguage == 'ar') return 'عن التطبيق';
        return 'About App';
      case 'app_title':
        if (widget.selectedLanguage == 'bn') return 'আমার হিসাব';
        if (widget.selectedLanguage == 'ar') return 'محاسبتي';
        return 'My Accounting';
      case 'app_description':
        if (widget.selectedLanguage == 'bn')
          return 'আপনার দৈনন্দিন আয়-ব্যয় এবং লেনদেনের হিসাব রাখার সহজ অ্যাপ। অফলাইন, ব্যাকআপ ও সুরক্ষা সুবিধা সহ।';
        if (widget.selectedLanguage == 'ar')
          return 'تطبيق بسيط لتتبع دخلك ونفقاتك اليومية مع دعم غير متصل بالإنترنت والنسخ الاحتياطي وميزات الأمان.';
        return 'A simple app to track your daily income, expenses and transactions with offline support, backup and security features.';
      case 'check_updates_title':
        if (widget.selectedLanguage == 'bn') return 'আপডেট চেক করুন';
        if (widget.selectedLanguage == 'ar') return 'التحقق من التحديثات';
        return 'Check for Updates';
      case 'current_version':
        if (widget.selectedLanguage == 'bn') return 'বর্তমান ভার্সন:';
        if (widget.selectedLanguage == 'ar') return 'الإصدار الحالي:';
        return 'Current version:';
      case 'developer':
        if (widget.selectedLanguage == 'bn') return 'ডেভেলপার';
        if (widget.selectedLanguage == 'ar') return 'المطور';
        return 'Developer';
      case 'support':
        if (widget.selectedLanguage == 'bn') return 'সাপোর্ট';
        if (widget.selectedLanguage == 'ar') return 'الدعم';
        return 'Support';
      case 'all_rights_reserved':
        if (widget.selectedLanguage == 'bn') return 'সর্বস্বত্ব সংরক্ষিত';
        if (widget.selectedLanguage == 'ar') return 'جميع الحقوق محفوظة';
        return 'All rights reserved';
      case 'privacy_policy':
        if (widget.selectedLanguage == 'bn') return 'গোপনীয়তা নীতি';
        if (widget.selectedLanguage == 'ar') return 'سياسة الخصوصية';
        return 'Privacy Policy';
      case 'terms_of_service':
        if (widget.selectedLanguage == 'bn') return 'সেবার শর্তাবলী';
        if (widget.selectedLanguage == 'ar') return 'شروط الخدمة';
        return 'Terms of Service';
      case 'faq_title':
        if (widget.selectedLanguage == 'bn') return '🙋‍♂️ সাধারণ জিজ্ঞাসা';
        if (widget.selectedLanguage == 'ar') return '🙋‍♂️ الأسئلة الشائعة';
        return '🙋‍♂️ Frequently Asked Questions';
      case 'faq_q1':
        if (widget.selectedLanguage == 'bn') return 'অ্যাপটি মূলত কী কী কাজে ব্যবহার করা যাবে?';
        if (widget.selectedLanguage == 'ar') return 'ما هي الميزات الرئيسية لهذا التطبيق؟';
        return 'What are the main features of this app?';
      case 'faq_a1':
        if (widget.selectedLanguage == 'bn')
          return 'এই অ্যাপটি আপনার দৈনন্দিন জীবনের অল-ইন-ওয়ান অ্যাসিস্ট্যান্ট। আপনি এখানে ৪টি প্রধান সুবিধা পাবেন:\n\n📊 হিসাব-নিকাশ: আয়-ব্যয়ের হিসাব রাখতে পারেন।\n📓 নোটবুক ও ড্রয়িং: গুরুত্বপূর্ণ তথ্য লিখতে ও আঁকতে পারেন।\n⏰ রিমাইন্ডার: কাজ বা বিলের তারিখ মনে করিয়ে দেবে।\n💰 বাজেট: মাসিক বা সাপ্তাহিক বাজেট সেট করে খরচ নিয়ন্ত্রণ করতে পারেন।';
        if (widget.selectedLanguage == 'ar')
          return 'هذا التطبيق هو مساعد شامل. يوفر 4 ميزات رئيسية:\n\n📊 تتبع الدخل والمصروفات\n📓 دفتر الملاحظات والرسم\n⏰ تذكيرات\n💰 تخطيط الميزانية';
        return 'This app is your all-in-one assistant. It offers 4 main features:\n\n📊 Income/Expense Tracking\n📓 Notebook & Drawing\n⏰ Reminders\n💰 Budget Planning';
      case 'faq_q2':
        if (widget.selectedLanguage == 'bn') return 'অ্যাপটি ব্যবহার করতে কি ইন্টারনেট লাগবে?';
        if (widget.selectedLanguage == 'ar') return 'هل أحتاج إلى الإنترنت لاستخدام التطبيق؟';
        return 'Do I need internet to use the app?';
      case 'faq_a2':
        if (widget.selectedLanguage == 'bn')
          return 'অ্যাপটি অনলাইন ও অফলাইন দুভাবেই কাজ করে। ইন্টারনেট না থাকলেও লেনদেন, নোট ও রিমাইন্ডার যোগ করতে পারবেন। পরে ইন্টারনেট এলে স্বয়ংক্রিয়ভাবে ক্লাউডে ব্যাকআপ হবে।';
        if (widget.selectedLanguage == 'ar')
          return 'التطبيق يعمل عبر الإنترنت وغير متصل. بدون إنترنت، لا يزال بإمكانك إضافة المعاملات والملاحظات والتذكيرات. عندما تتصل بالإنترنت، تتم مزامنة كل شيء تلقائياً مع السحابة.';
        return 'The app works online and offline. Without internet, you can still add transactions, notes and reminders. When you go online, everything syncs automatically to the cloud.';
      case 'faq_q3':
        if (widget.selectedLanguage == 'bn') return 'আমার ফোনের ডাটা হারিয়ে যাওয়ার ভয় আছে কি?';
        if (widget.selectedLanguage == 'ar') return 'هل سأفقد بياناتي إذا غيرت هاتفي؟';
        return 'Will I lose my data if I change my phone?';
      case 'faq_a3':
        if (widget.selectedLanguage == 'bn')
          return 'না। আপনার ডাটা অনলাইন সিঙ্ক সুবিধায় সুরক্ষিত থাকে। ফোন পরিবর্তন বা অ্যাপ আনইনস্টল করলেও একই অ্যাকাউন্টে লগইন করে সব ডাটা ফিরে পাবেন।';
        if (widget.selectedLanguage == 'ar')
          return 'لا. يتم تخزين بياناتك بأمان في حسابك. بعد تسجيل الدخول على جهاز جديد، سيتم استعادة جميع سجلاتك.';
        return 'No. Your data is safely stored in your account. After logging in on a new device, all your records will be restored.';
      case 'faq_q4':
        if (widget.selectedLanguage == 'bn') return 'রিমাইন্ডার ফিচারটি কীভাবে কাজ করে?';
        if (widget.selectedLanguage == 'ar') return 'كيف تعمل ميزة التذكير؟';
        return 'How does the reminder feature work?';
      case 'faq_a4':
        if (widget.selectedLanguage == 'bn')
          return 'আপনি নির্দিষ্ট দিন ও সময়ে কাজের রিমাইন্ডার সেট করতে পারেন। সেই সময় পুশ নোটিফিকেশনের মাধ্যমে অ্যাপ আপনাকে মনে করিয়ে দেবে।';
        if (widget.selectedLanguage == 'ar')
          return 'يمكنك تعيين تذكير لأي مهمة بتاريخ ووقت محددين. في الوقت المحدد، سيقوم التطبيق بإعلامك عبر إشعار.';
        return 'You can set a reminder for any task with a specific date and time. At the scheduled time, the app will notify you via push notification.';
      case 'faq_q5':
        if (widget.selectedLanguage == 'bn') return 'বাজেট ফিচারটির সুবিধা কী?';
        if (widget.selectedLanguage == 'ar') return 'ما فائدة ميزة الميزانية؟';
        return 'What is the benefit of the budget feature?';
      case 'faq_a5':
        if (widget.selectedLanguage == 'bn')
          return 'ক্যাটাগরি ভিত্তিক সর্বোচ্চ খরচের সীমা নির্ধারণ করে আপনি অতিরিক্ত খরচ নিয়ন্ত্রণ করতে পারবেন। এটি সঞ্চয় করতে সাহায্য করে।';
        if (widget.selectedLanguage == 'ar')
          return 'يمكنك تعيين حدود الإنفاق لكل فئة للتحكم في نفقاتك. هذا يساعدك على توفير المال.';
        return 'You can set spending limits per category to control your expenses. This helps you save money.';
      case 'faq_q6':
        if (widget.selectedLanguage == 'bn') return 'নোটবুকে কি ছবি বা ড্রয়িং যোগ করা যায়?';
        if (widget.selectedLanguage == 'ar') return 'هل يمكنني إضافة صور أو رسومات إلى ملاحظاتي؟';
        return 'Can I add images or drawings to my notes?';
      case 'faq_a6':
        if (widget.selectedLanguage == 'bn')
          return 'হ্যাঁ। আপনি টেক্সট নোটের সাথে ক্যামেরা বা গ্যালারি থেকে ছবি যোগ করতে পারেন এবং আঙ্গুল দিয়ে স্কেচ বা ড্রয়িং করতে পারেন।';
        if (widget.selectedLanguage == 'ar')
          return 'نعم. يمكنك إرفاق صور من الكاميرا / المعرض وكذلك الرسم أو التخطيط على اللوحة داخل دفتر الملاحظات.';
        return 'Yes. You can attach images from camera/gallery and also draw or sketch on the canvas inside the notebook.';
      case 'no_internet':
        if (widget.selectedLanguage == 'bn') return 'ইন্টারনেট সংযোগ নেই। নেটওয়ার্ক চেক করুন।';
        if (widget.selectedLanguage == 'ar') return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من شبكتك.';
        return 'No internet connection. Please check your network.';
      case 'checking_updates':
        if (widget.selectedLanguage == 'bn') return 'আপডেট চেক করা হচ্ছে...';
        if (widget.selectedLanguage == 'ar') return 'جارٍ التحقق من التحديثات...';
        return 'Checking for updates...';
      case 'update_check_error':
        if (widget.selectedLanguage == 'bn') return 'আপডেট চেক করা যায়নি। ইন্টারনেট সংযোগ নিশ্চিত করুন।';
        if (widget.selectedLanguage == 'ar') return 'تعذر التحقق من التحديثات. يرجى التأكد من وجود اتصال بالإنترنت.';
        return 'Could not check for updates. Please ensure you have an internet connection.';
      case 'update_unable':
        if (widget.selectedLanguage == 'bn') return 'ভার্সন তথ্য পাওয়া যায়নি। পরে আবার চেষ্টা করুন।';
        if (widget.selectedLanguage == 'ar') return 'تعذر الحصول على معلومات الإصدار. يرجى المحاولة لاحقًا.';
        return 'Unable to get version info. Please try again later.';
      case 'already_latest':
        if (widget.selectedLanguage == 'bn') return 'আপনি সর্বশেষ ভার্সনে আছেন';
        if (widget.selectedLanguage == 'ar') return 'أنت على أحدث إصدار';
        return 'You are on the latest version';
      case 'update_available':
        if (widget.selectedLanguage == 'bn') return 'নতুন আপডেট পাওয়া গেছে!';
        if (widget.selectedLanguage == 'ar') return 'تحديث متوفر!';
        return 'Update Available!';
      case 'new_version_msg':
        if (widget.selectedLanguage == 'bn') return 'নতুন ভার্সন উপলব্ধ:';
        if (widget.selectedLanguage == 'ar') return 'إصدار جديد متاح:';
        return 'A new version is available:';
      case 'later':
        if (widget.selectedLanguage == 'bn') return 'পরে দেখুন';
        if (widget.selectedLanguage == 'ar') return 'لاحقًا';
        return 'Later';
      case 'update_now':
        if (widget.selectedLanguage == 'bn') return 'এখন আপডেট করুন';
        if (widget.selectedLanguage == 'ar') return 'تحديث الآن';
        return 'Update Now';
      case 'cannot_open_url':
        if (widget.selectedLanguage == 'bn') return 'ইউআরএল খোলা যায়নি';
        if (widget.selectedLanguage == 'ar') return 'لا يمكن فتح الرابط';
        return 'Cannot open URL';
      default:
        return key;
    }
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
    final pinExists = await _lockService.hasPin();
    if (mounted) setState(() {
      _lockEnabled = enabled && pinExists;
      _hasBiometric = hasBio;
      _hasPinSaved = pinExists;
    });
  }

  Future<void> _checkIfPinExists() async {
    final exists = await _lockService.hasPin();
    if (mounted) setState(() => _hasPinSaved = exists);
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
        content: SingleChildScrollView(
          child: Column(
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

  Future<void> _checkForUpdate() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showSnackBar(getText('no_internet'));
      return;
    }
    _showSnackBar(getText('checking_updates'));
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
      _showSnackBar(getText('update_check_error'));
      return;
    }
    if (remoteVersion == null || remoteVersion.isEmpty) {
      _showSnackBar(getText('update_unable'));
      return;
    }
    if (_isNewerVersion(remoteVersion, _appVersion)) {
      _showUpdateDialog(remoteVersion);
    } else {
      _showSnackBar('${getText('already_latest')} ($_appVersion)');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(getText('update_available')),
        content: Text('${getText('new_version_msg')} $newVersion'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(getText('later'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              _launchUrl('https://play.google.com/store/apps/details?id=com.example.amar_hisab');
            },
            child: Text(getText('update_now')),
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
      _showSnackBar(getText('cannot_open_url'));
    }
  }

  void _handleEmailTap(String email) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Open Email App'),
              onTap: () async {
                Navigator.pop(ctx);
                final Uri emailUri = Uri(scheme: 'mailto', path: email);
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                } else {
                  // fallback: copy to clipboard
                  await Clipboard.setData(ClipboardData(text: email));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email copied to clipboard')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.green),
              title: const Text('Copy Email Address'),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: email));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email copied to clipboard')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // PRIVACY POLICY HTML (unchanged, kept as in your original)
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

  String _getPrivacyPolicyBangla() {
    return """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif; padding: 20px; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; }
        h1, h2 { color: #1976D2; }
        p, li { margin: 10px 0; }
        ul { padding-left: 20px; }
        .footer { font-size: 12px; color: #777; text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px; }
        .last-updated { color: #555; font-style: italic; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <h1>গোপনীয়তা নীতি</h1>
      <p class="last-updated"><strong>কার্যকর তারিখ:</strong> ২১ মে ২০২৬</p>
      <p>মোঃ মিজানুর রহমান <strong>"আমার হিসাব - দৈনিক আয় ব্যয় হিসাব"</strong> অ্যাপটি একটি বিজ্ঞাপন সমর্থিত অ্যাপ হিসেবে তৈরি করেছেন। এই সেবা বিনামূল্যে প্রদান করা হয় এবং এটি ব্যবহারের জন্য যেমন আছে তেমনই প্রদান করা হয়েছে।</p>
      <h2>তথ্য সংগ্রহ ও ব্যবহার</h2>
      <p>আমাদের সেবা ব্যবহারের সময়, আমরা আপনাকে কিছু ব্যক্তিগত তথ্য প্রদান করতে বলতে পারি যা আমরা সেবা উন্নত করতে ব্যবহার করি। আমরা আপনার তথ্য গোপনীয়তার নীতি ব্যতীত অন্য কোনো উদ্দেশ্যে ব্যবহার বা শেয়ার করি না।</p>
      <p>অ্যাপটি নিম্নলিখিত ডাটা ও অনুমতি ব্যবহার করে:</p>
      <ul>
        <li><strong>প্রমাণীকরণ ও পরিচয়:</strong> আপনার ইমেল ঠিকানা এবং Google প্রোফাইল তথ্য (Firebase Authentication এর মাধ্যমে) যাতে আপনার ডাটা নিরাপদে আলাদা থাকে।</li>
        <li><strong>আর্থিক ও বাজেট ডাটা:</strong> আপনি নিজে পরিচালিত আয়, ব্যয় ও বাজেটের সীমা।</li>
        <li><strong>নোটবুক, ড্রয়িং ও নোট:</strong> আপনার তৈরি টেক্সট নোট ও স্কেচ।</li>
        <li><strong>ডিভাইস স্টোরেজ ও মিডিয়া অ্যাক্সেস:</strong> প্রোফাইল ছবি ও সংযুক্তি সংরক্ষণ করতে।</li>
        <li><strong>লোকাল নোটিফিকেশন ও অ্যালার্ম:</strong> রিমাইন্ডার ও বাজেট বিজ্ঞপ্তির জন্য।</li>
      </ul>
      <h2>তৃতীয় পক্ষের সেবা</h2>
      <ul><li>Google Play Services</li><li>AdMob</li><li>Google Analytics for Firebase</li><li>Firebase Crashlytics</li></ul>
      <h2>ডাটা নিরাপত্তা</h2>
      <p>আপনার ডাটা ফায়ারবেস ক্লাউডে সুরক্ষিত SSL টানেলের মাধ্যমে সংরক্ষণ করা হয়। সম্পূর্ণ নিরাপত্তা নিশ্চিত করা সম্ভব নয়, তবে আমরা যথাসাধ্য চেষ্টা করি।</p>
      <h2>শিশুদের গোপনীয়তা</h2>
      <p>আমাদের সেবা ১৩ বছরের কম বয়সী শিশুদের উদ্দেশ্যে নয়। আমরা জেনেশুনে শিশুদের ব্যক্তিগত তথ্য সংগ্রহ করি না।</p>
      <h2>এই নীতির পরিবর্তন</h2>
      <p>আমরা আমাদের গোপনীয়তা নীতি সময়ে সময়ে আপডেট করতে পারি। এই পৃষ্ঠায় নিয়মিত চোখ রাখার পরামর্শ দেওয়া হয়।</p>
      <h2>যোগাযোগ</h2>
      <p>আপনার কোনো প্রশ্ন থাকলে ইমেইল করুন: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ২০২৪-২০২৬ আমার হিসাব। সর্বস্বত্ব সংরক্ষিত।</div>
    </body>
    </html>
    """;
  }

  String _getPrivacyPolicyEnglish() {
    return """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif; padding: 20px; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; }
        h1, h2 { color: #1976D2; }
        p, li { margin: 10px 0; }
        ul { padding-left: 20px; }
        .footer { font-size: 12px; color: #777; text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px; }
        .last-updated { color: #555; font-style: italic; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <h1>Privacy Policy</h1>
      <p class="last-updated"><strong>Effective date:</strong> 21 May 2026</p>
      <p>Md. Mizanur Rahman built the <strong>"আমার হিসাব - দৈনিক আয় ব্যয় হিসাব"</strong> app as an Ad Supported app. This SERVICE is provided at no cost and is intended for use as is.</p>
      <h2>Information Collection and Use</h2>
      <p>For a better experience, while using our Service, we may require you to provide certain personally identifiable information. The information we request will be retained and used as described in this privacy policy.</p>
      <p>The app uses the following data and permissions:</p>
      <ul>
        <li><strong>Authentication & Identity:</strong> Email address and Google profile info via Firebase Authentication.</li>
        <li><strong>Financial & Budget Data:</strong> Income, expenses, budget limits managed by you.</li>
        <li><strong>Notebook, Drawings & Notes:</strong> Text notes and sketches you create.</li>
        <li><strong>Device Storage & Media Access:</strong> To save profile pictures and attachments.</li>
        <li><strong>Local Notifications & Alarms:</strong> For reminders and budget alerts.</li>
      </ul>
      <h2>Third-Party Services</h2>
      <ul><li>Google Play Services</li><li>AdMob</li><li>Google Analytics for Firebase</li><li>Firebase Crashlytics</li></ul>
      <h2>Data Security</h2>
      <p>Your data is stored in Firebase Cloud via encrypted SSL tunnels. While no method is 100% secure, we strive to protect your information.</p>
      <h2>Children's Privacy</h2>
      <p>Our Service does not address anyone under the age of 13. We do not knowingly collect personal information from children.</p>
      <h2>Changes to This Policy</h2>
      <p>We may update our Privacy Policy from time to time. You are advised to review this page periodically.</p>
      <h2>Contact</h2>
      <p>If you have any questions, please email us at: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© 2024-2026 আমার হিসাব. All rights reserved.</div>
    </body>
    </html>
    """;
  }

  String _getPrivacyPolicyArabic() {
    return """
    <!DOCTYPE html>
    <html dir="rtl">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif; padding: 20px; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; }
        h1, h2 { color: #1976D2; }
        p, li { margin: 10px 0; }
        ul { padding-left: 20px; }
        .footer { font-size: 12px; color: #777; text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px; }
        .last-updated { color: #555; font-style: italic; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <h1>سياسة الخصوصية</h1>
      <p class="last-updated"><strong>تاريخ السريان:</strong> ٢١ مايو ٢٠٢٦</p>
      <p>قام السيد / Md. Mizanur Rahman ببناء تطبيق <strong>"আমার হিসাব - দৈনিক আয় ب্যয় হিসاب"</strong> كتطبيق يدعم الإعلانات. يتم تقديم هذه الخدمة مجانًا وهي مخصصة للاستخدام كما هي.</p>
      <h2>جمع المعلومات واستخدامها</h2>
      <p>لتجربة أفضل، أثناء استخدام خدمتنا، قد نطلب منك تقديم بعض المعلومات الشخصية. سنحتفظ بالمعلومات التي نطلبها ونستخدمها كما هو موضح في سياسة الخصوصية هذه.</p>
      <p>يستخدم التطبيق البيانات والأذونات التالية:</p>
      <ul>
        <li><strong>المصادقة والهوية:</strong> عنوان البريد الإلكتروني ومعلومات ملف Google عبر Firebase Authentication.</li>
        <li><strong>البيانات المالية والميزانية:</strong> الدخل والمصروفات وحدود الميزانية التي تديرها.</li>
        <li><strong>دفتر الملاحظات والرسومات والملاحظات:</strong> الملاحظات النصية والرسومات التي تنشئها.</li>
        <li><strong>الوصول إلى التخزين والوسائط:</strong> لحفظ الصور الشخصية والمرفقات.</li>
        <li><strong>الإشعارات المحلية والتنبيهات:</strong> للتذكيرات وتنبيهات الميزانية.</li>
      </ul>
      <h2>خدمات الطرف الثالث</h2>
      <ul><li>Google Play Services</li><li>AdMob</li><li>Google Analytics for Firebase</li><li>Firebase Crashlytics</li></ul>
      <h2>أمان البيانات</h2>
      <p>يتم تخزين بياناتك في سحابة Firebase عبر أنفاق SSL مشفرة. على الرغم من عدم وجود طريقة آمنة بنسبة 100٪، فإننا نسعى جاهدين لحماية معلوماتك.</p>
      <h2>خصوصية الأطفال</h2>
      <p>خدمتنا لا تخاطب أي شخص تحت سن ١٣ عامًا. نحن لا نجمع معلومات شخصية من الأطفال عن قصد.</p>
      <h2>تغييرات هذه السياسة</h2>
      <p>قد نقوم بتحديث سياسة الخصوصية الخاصة بنا من وقت لآخر. ننصحك بمراجعة هذه الصفحة بشكل دوري.</p>
      <h2>اتصل بنا</h2>
      <p>إذا كان لديك أي أسئلة، يرجى مراسلتنا عبر البريد الإلكتروني: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ٢٠٢٤-٢٠٢٦ আমার হিসاب. جميع الحقوق محفوظة.</div>
    </body>
    </html>
    """;
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

  String _getTermsBangla() {
    return """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif; padding: 20px; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; }
        h1, h2 { color: #1976D2; }
        p, li { margin: 10px 0; }
        ul { padding-left: 20px; }
        .footer { font-size: 12px; color: #777; text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px; }
        .last-updated { color: #555; font-style: italic; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <h1>সেবার শর্তাবলী</h1>
      <p class="last-updated"><strong>শেষ সংশোধন:</strong> ২১ মে ২০২৬</p>
      <h2>১. শর্তাবলীর স্বীকৃতি</h2>
      <p><strong>"আমার হিসাব"</strong> অ্যাপ্লিকেশনটি ডাউনলোড, ইনস্টল বা ব্যবহার করার মাধ্যমে আপনি এই সেবার শর্তাবলীতে বাধ্য হতে সম্মতি জানাচ্ছেন। যদি একমত না হন, অনুগ্রহ করে অ্যাপ ব্যবহার করবেন না।</p>
      <h2>২. সেবার বিবরণ</h2>
      <p>এই অ্যাপটি ব্যক্তিগত আর্থিক ব্যবস্থাপনার জন্য। বৈশিষ্ট্যসমূহ: আয়-ব্যয় ট্র্যাকিং, বাজেট ব্যবস্থাপনা, দেনা-পাওনা হিসাব, নোট ও ড্রয়িং, রিমাইন্ডার, অফলাইন সাপোর্ট এবং ক্লাউড সিঙ্ক।</p>
      <h2>৩. ব্যবহারকারীর অ্যাকাউন্ট</h2>
      <p>আপনার ইমেইল দিয়ে সাইন-ইন প্রয়োজন। আপনার অ্যাকাউন্টের নিরাপত্তা ও কার্যকলাপের দায়িত্ব আপনার।</p>
      <h2>৪. ব্যবহারকারীর ডাটা ও গোপনীয়তা</h2>
      <p>আপনার ডাটা ফায়ারবেস ক্লাউডে সুরক্ষিত থাকে। গোপনীয়তা নীতিতে বিস্তারিত জানুন।</p>
      <h2>৫. ব্যবহারের সীমাবদ্ধতা</h2>
      <p>আপনি অ্যাপ ব্যবহার করে কোনো অবৈধ কাজ, সার্ভারে আক্রমণ, বা দূষিত কোড ছড়াতে পারবেন না।</p>
      <h2>৬. দায়িত্ব অস্বীকার</h2>
      <p>অ্যাপ "যেমন আছে, তেমনই" প্রদান করা হয়। ডাটা হারানো বা আর্থিক ক্ষতির জন্য ডেভেলপার দায়ী নয়।</p>
      <h2>৭. শর্তাবলী পরিবর্তন</h2>
      <p>ডেভেলপার যেকোনো সময় শর্তাবলী পরিবর্তন করতে পারেন। পরিবর্তনের পরে অ্যাপ ব্যবহার চালিয়ে যাওয়া মানে সম্মতি।</p>
      <h2>৮. যোগাযোগ</h2>
      <p>প্রশ্ন থাকলে ইমেইল করুন: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ২০২৪-২০২৬ আমার হিসাব। সর্বস্বত্ব সংরক্ষিত।</div>
    </body>
    </html>
    """;
  }

  String _getTermsEnglish() {
    return """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif; padding: 20px; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; }
        h1, h2 { color: #1976D2; }
        p, li { margin: 10px 0; }
        ul { padding-left: 20px; }
        .footer { font-size: 12px; color: #777; text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px; }
        .last-updated { color: #555; font-style: italic; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <h1>Terms of Service</h1>
      <p class="last-updated"><strong>Last updated:</strong> 21 May 2026</p>
      <h2>1. Acceptance of Terms</h2>
      <p>By downloading, installing or using <strong>"আমার হিসাব"</strong> application, you agree to be bound by these Terms. If you do not agree, do not use the app.</p>
      <h2>2. Description of Service</h2>
      <p>This app provides personal finance management features: income/expense tracking, budget management, debt/credit records, notes & drawing, reminders, offline support and cloud sync.</p>
      <h2>3. User Account</h2>
      <p>You must sign in with a valid email. You are responsible for your account security and activities.</p>
      <h2>4. User Data & Privacy</h2>
      <p>Your data is stored securely in Firebase Cloud. See our Privacy Policy for details.</p>
      <h2>5. Acceptable Use</h2>
      <p>You may not use the app for illegal purposes, attack servers, or spread malicious code.</p>
      <h2>6. Disclaimer of Warranties</h2>
      <p>The app is provided "AS IS". The developer is not liable for data loss or financial damages.</p>
      <h2>7. Changes to Terms</h2>
      <p>We may update these Terms at any time. Continued use constitutes acceptance.</p>
      <h2>8. Contact</h2>
      <p>Email: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© 2024-2026 আমার হিসاب. All rights reserved.</div>
    </body>
    </html>
    """;
  }

  String _getTermsArabic() {
    return """
    <!DOCTYPE html>
    <html dir="rtl">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif; padding: 20px; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; }
        h1, h2 { color: #1976D2; }
        p, li { margin: 10px 0; }
        ul { padding-left: 20px; }
        .footer { font-size: 12px; color: #777; text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px; }
        .last-updated { color: #555; font-style: italic; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <h1>شروط الخدمة</h1>
      <p class="last-updated"><strong>آخر تحديث:</strong> ٢١ مايو ٢٠٢٦</p>
      <h2>١. قبول الشروط</h2>
      <p>بتحميل أو تثبيت أو استخدام تطبيق <strong>"আমার হিসাব"</strong>، فإنك توافق على الالتزام بهذه الشروط. إذا كنت لا توافق، فلا تستخدم التطبيق.</p>
      <h2>٢. وصف الخدمة</h2>
      <p>يقدم هذا التطبيق إدارة مالية شخصية: تتبع الدخل والمصروفات، إدارة الميزانية، سجلات الديون والائتمانات، الملاحظات والرسم، التذكيرات، الدعم دون اتصال بالإنترنت والمزامنة السحابية.</p>
      <h2>٣. حساب المستخدم</h2>
      <p>يجب عليك تسجيل الدخول ببريد إلكتروني صالح. أنت مسؤول عن أمان حسابك وأنشطتك.</p>
      <h2>٤. بيانات المستخدم والخصوصية</h2>
      <p>يتم تخزين بياناتك بشكل آمن في سحابة Firebase. راجع سياسة الخصوصية للحصول على التفاصيل.</p>
      <h2>٥. الاستخدام المقبول</h2>
      <p>لا يجوز لك استخدام التطبيق لأغراض غير قانونية، أو مهاجمة الخوادم، أو نشر تعليمات برمجية ضارة.</p>
      <h2>٦. إخلاء المسؤولية</h2>
      <p>يتم تقديم التطبيق "كما هو". المطور غير مسؤول عن فقدان البيانات أو الأضرار المالية.</p>
      <h2>٧. تغييرات الشروط</h2>
      <p>قد نقوم بتحديث هذه الشروط في أي وقت. الاستمرار في استخدام التطبيق يعني القبول.</p>
      <h2>٨. اتصل بنا</h2>
      <p>البريد الإلكتروني: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ٢٠٢٤-٢٠٢٦ আমার হিসاب. جميع الحقوق محفوظة.</div>
    </body>
    </html>
    """;
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
          // App Lock Card
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
          // About Card - FIXED: title now uses getText('about_app')
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
              title: Text(getText('about_app'), style: const TextStyle(fontWeight: FontWeight.bold)), // <-- FIXED
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
                          Text('Version $_appVersion', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(getText('app_description'), style: const TextStyle(height: 1.4)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.system_update_alt, color: Colors.blue),
                  title: Text(getText('check_updates_title')),
                  subtitle: Text('${getText('current_version')} $_appVersion'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _checkForUpdate,
                ),
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
          // Legal Cards
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
          // FAQ Card
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