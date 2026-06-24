import 'dart:async';
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
  final TextEditingController _secQuestionController = TextEditingController();
  final TextEditingController _secAnswerController = TextEditingController();

  String? _currentSecurityQuestion;

  // ===== ৩টি ভাষায় প্রি-সেট প্রশ্ন =====
  List<String> _getPresetQuestions(String lang) {
    if (lang == 'bn') {
      return [
        'আপনার মায়ের প্রথম নাম কী?',
        'আপনার প্রথম পোষা প্রাণীর নাম কী?',
        'আপনার প্রিয় শিক্ষকের নাম কী?',
        'আপনার জন্মস্থান কোথায়?',
        'আপনার প্রিয় বইয়ের নাম কী?',
        'আপনার প্রথম স্কুলের নাম কী?',
      ];
    } else if (lang == 'ar') {
      return [
        'ما هو اسم والدتك الأول؟',
        'ما هو اسم حيوانك الأليف الأول؟',
        'ما هو اسم معلمك المفضل؟',
        'أين مكان ولادتك؟',
        'ما هو اسم كتابك المفضل؟',
        'ما هو اسم مدرستك الأولى؟',
      ];
    } else {
      return [
        'What is your mother\'s first name?',
        'What is your first pet\'s name?',
        'What is your favorite teacher\'s name?',
        'What is your birthplace?',
        'What is your favorite book?',
        'What is your first school\'s name?',
      ];
    }
  }

  // ===== LOCALIZATION =====
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
        'app_description': 'আমার হিসাব (Amar Hisab) হলো একটি আধুনিক, দ্রুত এবং অফলাইন-ফার্স্ট পার্সোনাল ফাইন্যান্স ম্যানেজমেন্ট ট্র্যাকার, যেখানে কোনো ঝামেলা ছাড়াই আপনি আপনার দৈনিক আয়-ব্যয়, বাজেট ও হিসাব-নিকাশ ট্র্যাক করতে পারবেন। কোনো সাইন-ইন বা অ্যাকাউন্ট খোলার ঝামেলা নেই। অ্যাপটি ওপেন করেই সরাসরি হিসাব শুরু করতে পারবেন। আপনার সমস্ত ডেটা সম্পূর্ণ সুরক্ষিতভাবে আপনার নিজের ফোনে (Hive Database-এ) সেভ থাকে। চাইলে ১ ক্লিকে Google Drive-এ ব্যাকআপ রাখতে পারেন।',
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
        'security_question': 'নিরাপত্তা প্রশ্ন',
        'set_security_question': 'নিরাপত্তা প্রশ্ন সেট করুন',
        'change_security_question': 'নিরাপত্তা প্রশ্ন পরিবর্তন করুন',
        'current_question': 'বর্তমান প্রশ্ন:',
        'not_set': 'সেট করা নেই',
        'enter_question': 'প্রশ্ন নির্বাচন করুন',
        'enter_answer': 'উত্তর লিখুন (মনে রাখার মতো একটি উত্তর দিন)',
        'question_saved': 'নিরাপত্তা প্রশ্ন সেভ হয়েছে',
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
        'security_question': 'Security Question',
        'set_security_question': 'Set Security Question',
        'change_security_question': 'Change Security Question',
        'current_question': 'Current question:',
        'not_set': 'Not set',
        'enter_question': 'Select a question',
        'enter_answer': 'Enter answer (choose something memorable)',
        'question_saved': 'Security question saved',
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
        'security_question': 'سؤال الأمان',
        'set_security_question': 'تعيين سؤال الأمان',
        'change_security_question': 'تغيير سؤال الأمان',
        'current_question': 'السؤال الحالي:',
        'not_set': 'غير مضبوط',
        'enter_question': 'اختر سؤالاً',
        'enter_answer': 'أدخل الإجابة (اختر شيئًا لا ينسى)',
        'question_saved': 'تم حفظ سؤال الأمان',
      },
    };

    return fallback[widget.selectedLanguage]?[key] ?? fallback['en']?[key] ?? key;
  }

  // ===== ডাইনামিক এবং লোকালাইজড কপিরাইট টেক্সট =====
  String _getLocalizedCopyright() {
    final year = DateTime.now().year.toString();
    String localizedYear = year;

    if (widget.selectedLanguage == 'bn') {
      final Map<String, String> banglaDigits = {
        '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
        '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
      };
      localizedYear = year.split('').map((digit) => banglaDigits[digit] ?? digit).join();
      return '© $localizedYear ${getText('app_title')}। ${getText('all_rights_reserved')}';
    } else if (widget.selectedLanguage == 'ar') {
      final Map<String, String> arabicDigits = {
        '0': '٠', '1': '١', '2': '٢', '3': '٣', '4': '٤',
        '5': '٥', '6': '٦', '7': '٧', '8': '٨', '9': '٩'
      };
      localizedYear = year.split('').map((digit) => arabicDigits[digit] ?? digit).join();
      return '© $localizedYear ${getText('app_title')}. ${getText('all_rights_reserved')}';
    }

    return '© $localizedYear ${getText('app_title')}. ${getText('all_rights_reserved')}';
  }

  // ===== LIFECYCLE =====
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
    _checkIfPinExists();
    _loadSecurityQuestion();
  }

  Future<void> _loadSecurityQuestion() async {
    final q = await _lockService.getSecurityQuestion();
    if (mounted) {
      setState(() {
        _currentSecurityQuestion = q;
        _secQuestionController.text = q ?? '';
      });
    }
  }

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    _oldPinController.dispose();
    _secQuestionController.dispose();
    _secAnswerController.dispose();
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===== COLORFUL DIALOG (SCROLLABLE) =====
  Future<T?> _showColorfulDialog<T>({
    required String title,
    required String subtitle,
    required Widget content,
    required List<Widget> actions,
    Gradient? gradient,
    IconData? icon,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            maxWidth: MediaQuery.of(ctx).size.width * 0.92,
          ),
          decoration: BoxDecoration(
            gradient: gradient ??
                LinearGradient(
                  colors: [Colors.blue.shade700, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                  if (icon != null) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
              ],
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: content,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions.map((action) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: action,
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ===== PIN SETUP =====
  Future<void> _showPinSetupDialog() async {
    _newPinController.clear();
    _confirmPinController.clear();
    _secQuestionController.clear();
    _secAnswerController.clear();

    final presetQuestions = _getPresetQuestions(widget.selectedLanguage);
    String? selectedQuestion = _secQuestionController.text.isNotEmpty &&
            presetQuestions.contains(_secQuestionController.text)
        ? _secQuestionController.text
        : null;

    await _showColorfulDialog(
      title: getText('set_pin'),
      subtitle: '🔐 ${getText('security_question')}',
      icon: Icons.lock_outline,
      gradient: LinearGradient(
        colors: [Colors.green.shade700, Colors.teal.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _newPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: getText('new_pin'),
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              counterStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock, color: Colors.white70),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: getText('confirm_pin'),
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              counterStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Text(
            getText('security_question'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedQuestion,
            isExpanded: true,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.grey[800],
            decoration: InputDecoration(
              labelText: getText('enter_question'),
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.question_answer, color: Colors.white70),
            ),
            items: presetQuestions.map((q) {
              return DropdownMenuItem<String>(
                value: q,
                child: Text(q, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                selectedQuestion = value;
                _secQuestionController.text = value;
              }
            },
            hint: Text(
              getText('enter_question'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _secAnswerController,
            obscureText: true,
            obscuringCharacter: '●',
            enableInteractiveSelection: false,
            autocorrect: false,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: getText('enter_answer'),
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.visibility_off, color: Colors.white70),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(getText('cancel'), style: const TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              if (_newPinController.text.length != 4) {
                _showSnackBar('PIN must be 4 digits');
                return;
              }
              if (_newPinController.text != _confirmPinController.text) {
                _showSnackBar(getText('pin_mismatch'));
                return;
              }
              if (_secQuestionController.text.isEmpty || _secAnswerController.text.isEmpty) {
                _showSnackBar('Please select a question and provide answer');
                return;
              }

              await _lockService.savePin(_newPinController.text);
              await _lockService.setLockEnabled(true);
              await _lockService.saveSecurityQuestion(
                _secQuestionController.text.trim(),
                _secAnswerController.text.trim(),
              );

              if (!mounted) return;

              setState(() {
                _hasPinSaved = true;
                _lockEnabled = true;
                _currentSecurityQuestion = _secQuestionController.text.trim();
              });

              Navigator.pop(context);
              _showSnackBar(getText('pin_set_success'));
            } catch (e) {
              _showSnackBar('Error: $e');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.green.shade700,
          ),
          child: Text(getText('save')),
        ),
      ],
    );
  }

  // ===== CHANGE PIN (ক্র্যাশ মুক্ত) =====
  Future<void> _showChangePinDialog() async {
    _oldPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();

    bool verified = await _verifyOldPinDialog();
    if (!mounted) return;
    if (!verified) return;

    final Completer<bool> completer = Completer<bool>();
    bool isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(getText('change_pin'),
              style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: getText('new_pin'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: getText('confirm_pin'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (isDialogOpen) {
                  isDialogOpen = false;
                  if (!completer.isCompleted) completer.complete(false);
                  Navigator.pop(context);
                }
              },
              child: Text(getText('cancel')),
            ),
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

                if (!isDialogOpen || !mounted) {
                  return;
                }

                setState(() {
                  _hasPinSaved = true;
                  _lockEnabled = true;
                });

                isDialogOpen = false;
                if (!completer.isCompleted) completer.complete(true);
                Navigator.pop(context);
                _showSnackBar(getText('pin_changed_success'));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(getText('save')),
            ),
          ],
        );
      },
    );

    await completer.future;
  }

  // ===== VERIFY OLD PIN (ক্র্যাশ মুক্ত) =====
  Future<bool> _verifyOldPinDialog() async {
    final Completer<bool> completer = Completer<bool>();
    final TextEditingController pinController = TextEditingController();
    bool isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(getText('enter_old_pin'),
              style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: getText('old_pin'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (isDialogOpen) {
                  isDialogOpen = false;
                  Navigator.pop(context);
                  if (!completer.isCompleted) completer.complete(false);
                  // ডায়ালগ বন্ধ হওয়ার সামান্য পরে ডিসপোজ হবে যেন রেড স্ক্রিন না আসে
                  Future.delayed(const Duration(milliseconds: 100), () => pinController.dispose());
                }
              },
              child: Text(getText('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final enteredPin = pinController.text.trim();
                if (enteredPin.isEmpty) {
                  _showSnackBar('Please enter your current PIN');
                  return;
                }
                final isValid = await _lockService.verifyPin(enteredPin);
                if (!isDialogOpen) return;

                if (isValid) {
                  isDialogOpen = false;
                  Navigator.pop(context);
                  if (!completer.isCompleted) completer.complete(true);
                  Future.delayed(const Duration(milliseconds: 100), () => pinController.dispose());
                } else {
                  _showSnackBar(getText('wrong_old_pin'));
                  pinController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(getText('verify')),
            ),
          ],
        );
      },
    );

    return completer.future;
  }

  // ===== DISABLE PIN =====
  Future<void> _disablePinCode() async {
    final confirm = await _showColorfulDialog<bool>(
      title: getText('disable_pin_confirm_title'),
      subtitle: '',
      icon: Icons.warning_amber_rounded,
      gradient: LinearGradient(
        colors: [Colors.red.shade700, Colors.pink.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      content: Text(
        getText('disable_pin_confirm'),
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(getText('no')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.red.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            elevation: 3,
          ),
          child: Text(getText('yes')),
        ),
      ],
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

  // ===== SECURITY QUESTION (৩টি ভাষায় ড্রপডাউন) =====
  Future<void> _showSetSecurityQuestionDialog() async {
    _secQuestionController.text = _currentSecurityQuestion ?? '';
    _secAnswerController.clear();

    final presetQuestions = _getPresetQuestions(widget.selectedLanguage);
    String? selectedQuestion = _secQuestionController.text.isNotEmpty &&
            presetQuestions.contains(_secQuestionController.text)
        ? _secQuestionController.text
        : null;

    await _showColorfulDialog(
      title: _currentSecurityQuestion == null
          ? getText('set_security_question')
          : getText('change_security_question'),
      subtitle: '',
      icon: Icons.question_answer,
      gradient: LinearGradient(
        colors: [Colors.green.shade700, Colors.lime.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedQuestion,
            isExpanded: true,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.grey[800],
            decoration: InputDecoration(
              labelText: getText('enter_question'),
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.question_answer, color: Colors.white70),
            ),
            items: presetQuestions.map((q) {
              return DropdownMenuItem<String>(
                value: q,
                child: Text(q, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                selectedQuestion = value;
                _secQuestionController.text = value;
              }
            },
            hint: Text(
              getText('enter_question'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _secAnswerController,
            obscureText: true,
            obscuringCharacter: '●',
            enableInteractiveSelection: false,
            autocorrect: false,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: getText('enter_answer'),
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.visibility_off, color: Colors.white70),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(getText('cancel')),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              if (_secQuestionController.text.isEmpty || _secAnswerController.text.isEmpty) {
                _showSnackBar('Please select a question and provide answer');
                return;
              }
              await _lockService.saveSecurityQuestion(
                _secQuestionController.text.trim(),
                _secAnswerController.text.trim(),
              );
              if (mounted) {
                setState(() {
                  _currentSecurityQuestion = _secQuestionController.text.trim();
                });
                Navigator.pop(context);
                _showSnackBar(getText('question_saved'));
              }
            } catch (e) {
              _showSnackBar('Error: $e');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.green.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            elevation: 3,
          ),
          child: Text(getText('save')),
        ),
      ],
    );
  }

  // ===== EMAIL & CLIPBOARD =====
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
              title: const Text('Copy Email Address'),
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

  // ===== PRIVACY POLICY & TERMS OF SERVICE (সম্পূর্ণ HTML) =====
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

  // ----- Privacy Policy (Bengali) -----
  String _getPrivacyPolicyBangla() {
    return """
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;} .footer{text-align:center;margin-top:30px;color:#888;font-size:12px;}</style>
    </head>
    <body>
      <h1>🔒 গোপনীয়তা নীতি</h1>
      <p><strong>সর্বশেষ আপডেট:</strong> জুন ২০২৬</p>

      <h2>১. ডেটা সংগ্রহ (Data Collection)</h2>
      <p>"আমার হিসাব" অ্যাপটি ব্যবহার করার জন্য কোনো ব্যক্তিগত তথ্য যেমন নাম, ইমেইল, ফোন নম্বর বা অ্যাকাউন্ট দেওয়ার প্রয়োজন নেই। অ্যাপটি আপনার কোনো তথ্য আমাদের সার্ভারে সংগ্রহ বা সংরক্ষণ করে না।</p>

      <h2>২. ডেটা স্টোরেজ ও নিরাপত্তা (Data Storage & Security)</h2>
      <p>আপনার সমস্ত ডেটা (লেনদেন, নোট, বাজেট ইত্যাদি) শুধুমাত্র আপনার ডিভাইসের লোকাল স্টোরেজে (Hive Database) সংরক্ষিত থাকে। আমরা কোনো ক্লাউড সার্ভিসে ডেটা পাঠাই না। তাই আপনার ডেটার নিরাপত্তা সম্পূর্ণ আপনার নিজের হাতে।</p>

      <h2>৩. গুগল ড্রাইভ ব্যাকআপ (Google Drive Backup)</h2>
      <p>আপনি চাইলে Google Drive API ব্যবহার করে নিজের ড্রাইভে ব্যাকআপ নিতে পারেন। এই ক্ষেত্রে আপনার ড্রাইভে একটি এনক্রিপ্টেড JSON ফাইল সংরক্ষণ করা হয়, যা ডেভেলপার বা অন্য কেউ অ্যাক্সেস করতে পারে না।</p>

      <h2>৪. থার্ড-পার্টি সার্ভিস (Third‑Party Services)</h2>
      <p>অ্যাপটি Google Sign‑In ও Google Drive SDK ব্যবহার করে শুধুমাত্র ব্যাকআপ ফিচারের জন্য। এই সার্ভিসগুলোর নিজস্ব গোপনীয়তা নীতি প্রযোজ্য।</p>

      <h2>📧 যোগাযোগ</h2>
      <p>যেকোনো প্রশ্নে ইমেইল করুন: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ২০২৪-২০২৬ আমার হিসাব</div>
    </body>
    </html>
    """;
  }

  // ----- Privacy Policy (English) -----
  String _getPrivacyPolicyEnglish() {
    return """
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;} .footer{text-align:center;margin-top:30px;color:#888;font-size:12px;}</style>
    </head>
    <body>
      <h1>🔒 Privacy Policy</h1>
      <p><strong>Last updated:</strong> June 2026</p>

      <h2>1. Data Collection</h2>
      <p>No personal information (name, email, phone, etc.) is required to use "Amar Hisab". The app does not collect or transmit any of your data to our servers.</p>

      <h2>2. Data Storage & Security</h2>
      <p>All your data (transactions, notes, budgets, etc.) is stored entirely offline on your device (Hive database). We do not send any data to any cloud service. Therefore, the security of your data is entirely in your hands.</p>

      <h2>3. Google Drive Backup</h2>
      <p>You may choose to back up your data to your personal Google Drive using the Google Drive API. In that case, an encrypted JSON file is stored in your Drive, which is not accessible to the developer or any third party.</p>

      <h2>4. Third‑Party Services</h2>
      <p>This app uses Google Sign‑In and Google Drive SDK solely for the backup feature. Those services are governed by Google's own privacy policies.</p>

      <h2>📧 Contact</h2>
      <p>Email: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© 2024-2026 আমার হিসাব</div>
    </body>
    </html>
    """;
  }

  // ----- Privacy Policy (Arabic) -----
  String _getPrivacyPolicyArabic() {
    return """
    <!DOCTYPE html>
    <html dir="rtl">
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;} .footer{text-align:center;margin-top:30px;color:#888;font-size:12px;}</style>
    </head>
    <body>
      <h1>🔒 سياسة الخصوصية</h1>
      <p><strong>آخر تحديث:</strong> يونيو ٢٠٢٦</p>

      <h2>١. جمع البيانات</h2>
      <p>لا حاجة لتقديم أي معلومات شخصية (الاسم، البريد الإلكتروني، رقم الهاتف، إلخ) لاستخدام "محاسبتي". لا يجمع التطبيق أي بيانات من مستخدميه.</p>

      <h2>٢. تخزين البيانات وأمانها</h2>
      <p>جميع بياناتك (المعاملات، الملاحظات، الميزانيات، إلخ) تُخزَّن محليًا على جهازك فقط (قاعدة بيانات Hive). نحن لا نرسل أي بيانات إلى أي خدمة سحابية. وبالتالي، فإن أمان بياناتك يقع بالكامل على عاتقك.</p>

      <h2>٣. النسخ الاحتياطي على Google Drive</h2>
      <p>يمكنك اختيار عمل نسخ احتياطي لبياناتك إلى Google Drive الشخصي الخاص بك باستخدام واجهة برمجة تطبيقات Google Drive. في هذه الحالة، يتم تخزين ملف JSON مشفر في Drive الخاص بك، ولا يمكن للمطور أو أي طرف ثالث الوصول إليه.</p>

      <h2>٤. خدمات الطرف الثالث</h2>
      <p>يستخدم هذا التطبيق Google Sign‑In و Google Drive SDK فقط لميزة النسخ الاحتياطي. تخضع هذه الخدمات لسياسات الخصوصية الخاصة بـ Google.</p>

      <h2>📧 اتصل بنا</h2>
      <p>البريد الإلكتروني: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ٢٠٢٤-٢٠٢٦ আমার হিসاب</div>
    </body>
    </html>
    """;
  }

  // ----- Terms of Service (Bengali) -----
  String _getTermsBangla() {
    return """
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;} .footer{text-align:center;margin-top:30px;color:#888;font-size:12px;}</style>
    </head>
    <body>
      <h1>📋 সেবার শর্তাবলী</h1>
      <p><strong>সর্বশেষ সংশোধন:</strong> জুন ২০২৬</p>

      <h2>১. অ্যাপের ব্যবহার</h2>
      <p>"আমার হিসাব" অ্যাপটি ব্যক্তিগত ব্যবহারের জন্য সম্পূর্ণ বিনামূল্যে। অ্যাপটি ব্যবহারের জন্য কোনো অ্যাকাউন্ট খোলার প্রয়োজন নেই।</p>

      <h2>২. ব্যবহারকারীর ডেটার দায়বদ্ধতা (গুরুত্বপূর্ণ)</h2>
      <p>আমরা (অ্যাপ কর্তৃপক্ষ বা ডেভেলপার) ব্যবহারকারীর ডেটার কোনো দায়িত্ব বা দায়বদ্ধতা গ্রহণ করি না। যেহেতু ডেটা আপনার ডিভাইসে সংরক্ষিত থাকে, তাই ফোন হারানো, অ্যাপ আনইনস্টল করা, ফ্যাক্টরি রিসেট ইত্যাদি কারণে ডেটা হারিয়ে গেলে তার জন্য ডেভেলপার দায়ী নয়। আপনি নিজেই পর্যায়ক্রমে ব্যাকআপ নেওয়ার দায়িত্ব নিন।</p>

      <h2>৩. ব্যাকআপ ও অটো-ব্যাকআপ</h2>
      <p>আপনি চাইলে Google Drive বা লোকাল ব্যাকআপ ব্যবহার করতে পারেন। প্রথমবার ব্যাকআপ দেওয়ার পর ইন্টারনেট সংযোগ থাকলে অ্যাপ স্বয়ংক্রিয়ভাবে ব্যাকআপ আপডেট করতে পারে। তবে নেটওয়ার্ক বা অন্যান্য কারণে ব্যাকআপ ব্যর্থ হলে তার দায় ব্যবহারকারীর নিজের।</p>

      <h2>৪. পরিবর্তন ও সংশোধন</h2>
      <p>ডেভেলপার যেকোনো সময় এই শর্তাবলী পরিবর্তন করার অধিকার সংরক্ষণ করে।</p>

      <h2>📧 যোগাযোগ</h2>
      <p>ইমেইল: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ২০২৪-২০২৬ আমার হিসাব</div>
    </body>
    </html>
    """;
  }

  // ----- Terms of Service (English) -----
  String _getTermsEnglish() {
    return """
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;} .footer{text-align:center;margin-top:30px;color:#888;font-size:12px;}</style>
    </head>
    <body>
      <h1>📋 Terms of Service</h1>
      <p><strong>Last updated:</strong> June 2026</p>

      <h2>1. App Usage</h2>
      <p>"Amar Hisab" is completely free for personal use. No account registration is required.</p>

      <h2>2. User Data Responsibility (CRITICAL)</h2>
      <p>We (the app authority or developer) do not accept any responsibility or liability for user data. Since data resides locally on your device, any data loss due to phone loss, app uninstallation, factory reset, or device damage is not the developer's responsibility. You are solely responsible for taking regular backups.</p>

      <h2>3. Backup & Auto-Backup</h2>
      <p>You may use Google Drive or local backup features. After the first successful backup, the app may automatically update your backup when internet is available. However, any backup failure due to network or other issues is the user's own responsibility.</p>

      <h2>4. Modifications</h2>
      <p>The developer reserves the right to modify these terms at any time.</p>

      <h2>📧 Contact</h2>
      <p>Email: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© 2024-2026 আমার হিসاب</div>
    </body>
    </html>
    """;
  }

  // ----- Terms of Service (Arabic) -----
  String _getTermsArabic() {
    return """
    <!DOCTYPE html>
    <html dir="rtl">
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>body{font-family:sans-serif;padding:20px;line-height:1.6;max-width:800px;margin:0 auto;} h1,h2{color:#1976D2;} .footer{text-align:center;margin-top:30px;color:#888;font-size:12px;}</style>
    </head>
    <body>
      <h1>📋 شروط الخدمة</h1>
      <p><strong>آخر تحديث:</strong> يونيو ٢٠٢٦</p>

      <h2>١. استخدام التطبيق</h2>
      <p>تطبيق "محاسبتي" مجاني تمامًا للاستخدام الشخصي. لا يلزم التسجيل لاستخدامه.</p>

      <h2>٢. مسؤولية بيانات المستخدم (هام جدًا)</h2>
      <p>نحن (سلطة التطبيق أو المطور) لا نتحمل أي مسؤولية أو التزام تجاه بيانات المستخدم. نظرًا لأن البيانات مخزنة محليًا على جهازك، فإن أي فقدان للبيانات بسبب فقدان الهاتف، أو إلغاء تثبيت التطبيق، أو إعادة ضبط المصنع، أو تلف الجهاز ليس مسؤولية المطور. تقع على عاتقك وحدك مسؤولية إجراء نسخ احتياطية منتظمة.</p>

      <h2>٣. النسخ الاحتياطي والتلقائي</h2>
      <p>يمكنك استخدام ميزات النسخ الاحتياطي على Google Drive أو المحلي. بعد أول نسخ احتياطي ناجح، قد يقوم التطبيق بتحديث النسخ الاحتياطي تلقائيًا عند توفر الإنترنت. ومع ذلك، فإن أي فشل في النسخ الاحتياطي بسبب مشاكل الشبكة أو غيرها هو مسؤولية المستخدم نفسه.</p>

      <h2>٤. التعديلات</h2>
      <p>يحتفظ المطور بالحق في تعديل هذه الشروط في أي وقت.</p>

      <h2>📧 اتصل بنا</h2>
      <p>البريد الإلكتروني: <a href="mailto:md.mizanur.ete@gmail.com">md.mizanur.ete@gmail.com</a></p>
      <div class="footer">© ٢٠٢٤-٢٠٢٦ আমার হিসاب</div>
    </body>
    </html>
    """;
  }

  // ===== BUILD =====
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
          // Security Question Card
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
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.question_answer, color: Colors.green.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(getText('security_question'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${getText('current_question')} ${_currentSecurityQuestion ?? getText('not_set')}',
                        style: TextStyle(fontWeight: _currentSecurityQuestion != null ? FontWeight.w500 : FontWeight.normal),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showSetSecurityQuestionDialog,
                          icon: Icon(_currentSecurityQuestion == null ? Icons.add : Icons.edit),
                          label: Text(
                            _currentSecurityQuestion == null
                                ? getText('set_security_question')
                                : getText('change_security_question'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // About App Card
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
                    _getLocalizedCopyright(),
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