import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/local_database_service.dart';
import '../models/transaction_model.dart';
import 'daily_stats_screen.dart';
import 'monthly_stats_screen.dart';
import 'yearly_stats_screen.dart';
import 'recurring_screen.dart';
import 'export_screen.dart';
import 'security_screen.dart';
import 'budget_screen.dart';
import '../models/budget_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/custom_category_model.dart';
import '../services/category_service.dart';
import '../widgets/category_dropdown.dart';
import 'package:open_file/open_file.dart';

// ==================== Helper Classes ====================
class HijriCalendar {
  static Map<int, String> _getMonths(String language) {
    if (language == 'ar') {
      return {
        1: 'محرم', 2: 'صفر', 3: 'ربيع الأول', 4: 'ربيع الثاني',
        5: 'جمادى الأولى', 6: 'جمادى الثانية', 7: 'رجب', 8: 'شعبان',
        9: 'رمضان', 10: 'شوال', 11: 'ذو القعدة', 12: 'ذو الحجة',
      };
    } else if (language == 'bn') {
      return {
        1: 'মুহাররম', 2: 'সফর', 3: 'রবিউল আউয়াল', 4: 'রবিউস সানি',
        5: 'জমাদিউল আউয়াল', 6: 'জমাদিউস সানি', 7: 'রজব', 8: 'শাবান',
        9: 'রমজান', 10: 'শাওয়াল', 11: 'জিলকদ', 12: 'জিলহজ',
      };
    } else {
      return {
        1: 'Muharram', 2: 'Safar', 3: 'Rabi al-Awwal', 4: 'Rabi al-Thani',
        5: 'Jumada al-Awwal', 6: 'Jumada al-Thani', 7: 'Rajab', 8: 'Sha\'ban',
        9: 'Ramadan', 10: 'Shawwal', 11: 'Dhu al-Qa\'dah', 12: 'Dhu al-Hijjah',
      };
    }
  }

  static int _gregorianToJDN(DateTime date) {
    int y = date.year;
    int m = date.month;
    int d = date.day;
    int a = (14 - m) ~/ 12;
    int y2 = y + 4800 - a;
    int m2 = m + 12 * a - 3;
    return d + ((153 * m2 + 2) ~/ 5) + 365 * y2 + (y2 ~/ 4) - (y2 ~/ 100) + (y2 ~/ 400) - 32045;
  }

  static int _hijriToJDN(int year) {
    return (1948440 + ((year - 1) * 354.367)).floor();
  }

  static String getHijriDate(DateTime date, String language) {
    int jdn = _gregorianToJDN(date);
    int adjustment = 0;
    int hijriYear = ((jdn - 1948440 + 0.5) / 354.367).floor();
    if (hijriYear < 1) hijriYear = 1;
    int firstDayJDN = _hijriToJDN(hijriYear);
    int dayOfYear = (jdn - firstDayJDN).toInt() + adjustment;
    List<int> monthLengths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
    int month = 1;
    int day = dayOfYear;
    for (int i = 0; i < monthLengths.length; i++) {
      if (day < monthLengths[i]) {
        month = i + 1;
        day = day + 1;
        break;
      }
      day -= monthLengths[i];
    }
    if (month > 12) {
      month = 1;
      day = 1;
      hijriYear++;
    }
    final months = _getMonths(language);
    final monthName = months[month] ?? '';
    String suffix = language == 'bn' ? 'হিজরি' : (language == 'ar' ? 'هـ' : 'AH');
    return '$day $monthName $hijriYear $suffix';
  }
}

class BengaliCalendar {
  static Map<int, String> bengaliMonths = {
    1: 'বৈশাখ', 2: 'জ্যৈষ্ঠ', 3: 'আষাঢ়', 4: 'শ্রাবণ',
    5: 'ভাদ্র', 6: 'আশ্বিন', 7: 'কার্তিক', 8: 'অগ্রহায়ণ',
    9: 'পৌষ', 10: 'মাঘ', 11: 'ফাল্গুন', 12: 'চৈত্র',
  };

  static String getBengaliDate(DateTime date) {
    int year = date.year;
    DateTime bengaliNewYear = DateTime(year, 4, 14);
    int daysDiff = date.difference(bengaliNewYear).inDays;
    int bengaliYear;
    int dayOfYear;
    if (daysDiff >= 0) {
      bengaliYear = year - 593;
      dayOfYear = daysDiff;
    } else {
      bengaliYear = year - 594;
      DateTime prevNewYear = DateTime(year - 1, 4, 14);
      dayOfYear = date.difference(prevNewYear).inDays;
    }
    List<int> monthLengths = [31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 30, 30];
    int monthIndex = 0;
    int day = dayOfYear;
    for (int i = 0; i < monthLengths.length; i++) {
      if (day < monthLengths[i]) {
        monthIndex = i + 1;
        day = day + 1;
        break;
      }
      day -= monthLengths[i];
    }
    return '${day} ${bengaliMonths[monthIndex]} $bengaliYear';
  }

  static String getBengaliDay(int weekday) {
    Map<int, String> days = {
      1: 'সোমবার', 2: 'মঙ্গলবার', 3: 'বুধবার', 4: 'বৃহস্পতিবার',
      5: 'শুক্রবার', 6: 'শনিবার', 7: 'রবিবার'
    };
    return days[weekday] ?? '';
  }
}

class BDHolidays {
  static Map<String, String> holidays = {
    '21/02': 'শহীদ দিবস', '17/03': 'বঙ্গবন্ধুর জন্মদিন', '26/03': 'স্বাধীনতা দিবস',
    '14/04': 'পহেলা বৈশাখ', '01/05': 'মে দিবস', '15/08': 'শোক দিবস', '16/12': 'বিজয় দিবস', '25/12': 'বড়দিন',
  };
  static String? getHoliday(DateTime date) => holidays[DateFormat('dd/MM').format(date)];
}

class RemoteNotice {
  final String title;
  final String body;
  final DateTime date;
  RemoteNotice({required this.title, required this.body, required this.date});

  factory RemoteNotice.fromJson(Map<String, dynamic> json) {
    return RemoteNotice(
      title: json['title'],
      body: json['body'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'date': date.toIso8601String(),
  };
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatefulWidget {
  final String initialLanguage;
  final bool initialDarkMode;
  final Function({String? language, bool? isDarkMode}) onSettingsChanged;

  const HomeScreen({
    super.key,
    required this.initialLanguage,
    required this.initialDarkMode,
    required this.onSettingsChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // ==================== NOTEBOOK ====================
  List<Map<String, dynamic>> _textNotes = [];
  List<Map<String, dynamic>> _drawingNotes = [];
  int _notebookMode = 0;
  bool _isNoteEditorOpen = false;
  bool _isDrawingEditorOpen = false;

  // ==================== ডেনা/পাওনার শেষ তারিখ ====================
  DateTime? _lastDebtDate;
  DateTime? _lastCreditDate;

  // ==================== LOCAL PROFILE PICTURE ====================
  String? _localProfilePicPath;
  String _userName = '';
  String? _profileImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  // ==================== APP SETTINGS ====================
  int _currentIndex = 0;
  String _selectedLanguage = 'bn';
  String _selectedCurrency = 'BDT';
  bool _showHijriDate = true;
  bool _showBengaliDate = true;
  bool _isDarkMode = false;
  Map<String, String> _currencySymbols = {'BDT': '৳', 'USD': '\$', 'EUR': '€', 'GBP': '£', 'INR': '₹'};

  Locale _getTimePickerLocale() {
    switch (_selectedLanguage) {
      case 'bn': return const Locale('bn', 'BD');
      case 'ar': return const Locale('ar', 'SA');
      default: return const Locale('en', 'US');
    }
  }

  String _getFormattedAppTitle() {
    final appName = getText('app_title');
    return '📊 $appName';
  }

  Future<TimeOfDay?> _show12HourTimePicker(BuildContext context, {required TimeOfDay initialTime}) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Localizations.override(
            context: context,
            locale: const Locale('en', 'US'),
            child: child!,
          ),
        );
      },
    );
  }

  // ==================== REMOTE NOTICES ====================
  List<RemoteNotice> _remoteNotices = [];

  // ==================== LOCALIZATION ====================
  Map<String, Map<String, String>> _localizedText = {
    'bn': {
      'app_title': 'আমার হিসাব',
      'home': 'হোম',
      'calendar': 'ক্যালেন্ডার',
      'notice': 'নোটিশ',
      'notebook': 'নোটবুক',
      'profile': 'প্রোফাইল',
      'income': 'আয়',
      'expense': 'ব্যয়',
      'savings': 'সঞ্চয়',
      'debt': 'দেনা',
      'credit': 'পাওনা',
      'monthly_stats': 'মাসিক পরিসংখ্যান',
      'monthly_report': 'মাসিক রিপোর্ট',
      'select_month': 'মাস নির্বাচন করুন',
      'balance': 'ব্যালেন্স',
      'income_expense_stats': 'আয়-ব্যয় পরিসংখ্যান',
      'other_accounts': 'অন্যান্য হিসাব',
      'recent_transactions': 'সাম্প্রতিক লেনদেন',
      'daily': 'দৈনিক',
      'monthly': 'মাসিক',
      'yearly': 'বাৎসরিক',
      'no_transactions': 'কোনো লেনদেন নেই',
      'add_income': 'আয় যোগ করুন',
      'add_expense': 'ব্যয় যোগ করুন',
      'add_reminder': 'রিমাইন্ডার যোগ করুন',
      'no_reminders': 'কোনো রিমাইন্ডার নেই',
      'no_notices': 'কোনো নোটিশ নেই',
      'no_notes': 'কোনো নোট নেই',
      'no_drawing': 'কোনো ড্রয়িং নেই',
      'add_note': 'নতুন নোট',
      'add_drawing': 'ড্রয়িং যোগ করুন',
      'text_note': 'নোট',
      'drawing': 'ড্রয়িং',
      'archive': 'আর্কাইভ',
      'yes': 'হ্যাঁ',
      'no': 'না',
      'save': 'সেভ',
      'cancel': 'বাতিল',
      'amount': 'টাকা',
      'description': 'বিবরণ',
      'title': 'শিরোনাম',
      'date': 'তারিখ',
      'time': 'সময়',
      'logout': 'লগ আউট',
      'settings': 'সেটিংস',
      'language': 'ভাষা',
      'currency': 'কারেন্সি',
      'dark_mode': 'ডার্ক মোড',
      'user_name': 'নাম',
      'change_photo': 'ছবি পরিবর্তন',
      'take_photo': 'ক্যামেরা',
      'choose_gallery': 'গ্যালারি',
      'edit': 'এডিট',
      'delete': 'ডিলিট',
      'ok': 'ঠিক আছে',
      'select_category': 'ক্যাটাগরি',
      'amount_error': 'টাকা লিখুন',
      'salary': 'বেতন',
      'business': 'ব্যবসা',
      'house_rent': 'বাড়ি ভাড়া',
      'other': 'অন্যান্য',
      'gas_bill': 'গ্যাস বিল',
      'electricity_bill': 'বিদ্যুৎ বিল',
      'internet_bill': 'ইন্টারনেট',
      'water_bill': 'পানি বিল',
      'transport': 'যাতায়াত',
      'grocery': 'বাজার',
      'education': 'শিক্ষা',
      'medical': 'চিকিৎসা',
      'food': 'খাবার',
      'mobile_bill': 'মোবাইল',
      'entertainment': 'বিনোদন',
      'government_holiday': 'সরকারি ছুটি',
      'holidays': 'ছুটি',
      'notification_scheduled': 'নোটিফিকেশন সেট',
      'budget_management': 'বাজেট',
      'monthly_budget': 'মাসিক বাজেট',
      'budget_spent': 'খরচ',
      'total_budget': 'মোট বাজেট',
      'used': 'ব্যবহৃত',
      'remaining': 'বাকি',
      'budget_exceeded': 'বাজেট অতিক্রম',
      'recurring_transactions': 'রিকারিং',
      'export_report': 'এক্সপোর্ট',
      'security_settings': 'সিকিউরিটি',
      'change_settings': 'সেটিংস পরিবর্তন',
      'delete_confirm': 'আপনি কি নিশ্চিত?',
      'show_hijri': 'হিজরি দেখান',
      'show_bengali': 'বাংলা দেখান',
      'calendar_settings': 'পঞ্জিকা সেটিংস',
      'set_pin': 'পিন সেট করুন',
      'new_pin': 'নতুন পিন',
      'confirm_pin': 'পিন নিশ্চিত করুন',
      'disable_lock': 'লক বন্ধ করুন',
      'disable_lock_confirm': 'আপনি কি লক সিস্টেম বন্ধ করতে চান?',
      'app_lock_desc': 'অ্যাপ খুলতে পিন/বায়োমেট্রিক লাগবে',
      'lock_type': 'লক টাইপ',
      'pin_only': 'শুধুমাত্র পিন',
      'biometric_only': 'শুধুমাত্র বায়োমেট্রিক',
      'pin_and_biometric': 'পিন ও বায়োমেট্রিক',
      'change_pin': 'পিন পরিবর্তন করুন',
      'about_app': 'অ্যাপ সম্পর্কে',
      'app_description': 'আপনার দৈনন্দিন আয়-ব্যয় এবং লেনদেনের হিসাব রাখার সহজ অ্যাপ। অফলাইন, ব্যাকআপ ও সুরক্ষা সুবিধা সহ।',
      'privacy_policy': 'গোপনীয়তা নীতি',
      'terms_of_service': 'সেবার শর্তাবলী',
      'pin_set_success': 'পিন সফলভাবে সেট করা হয়েছে',
      'pin_mismatch': 'পিন মেলেনি, আবার চেষ্টা করুন',
      'lock_disabled': 'লক বন্ধ করা হয়েছে',
      'faq_title': '🙋‍♂️ সাধারণ জিজ্ঞাসা',
      'faq_q1': 'অ্যাপটি মূলত কী কী কাজে ব্যবহার করা যাবে?',
      'faq_a1': 'এই অ্যাপটি আপনার দৈনন্দিন জীবনের অল-ইন-ওয়ান অ্যাসিস্ট্যান্ট। আপনি এখানে ৪টি প্রধান সুবিধা পাবেন:\n\n📊 হিসাব-নিকাশ: আয়-ব্যয়ের হিসাব রাখতে পারেন।\n📓 নোটবুক ও ড্রয়িং: গুরুত্বপূর্ণ তথ্য লিখতে ও আঁকতে পারেন।\n⏰ রিমাইন্ডার: কাজ বা বিলের তারিখ মনে করিয়ে দেবে।\n💰 বাজেট: মাসিক বা সাপ্তাহিক বাজেট সেট করে খরচ নিয়ন্ত্রণ করতে পারেন।',
      'faq_q2': 'অ্যাপটি ব্যবহার করতে কি ইন্টারনেট লাগবে?',
      'faq_a2': 'অ্যাপটি অনলাইন ও অফলাইন দুভাবেই কাজ করে। ইন্টারনেট না থাকলেও লেনদেন, নোট ও রিমাইন্ডার যোগ করতে পারবেন। পরে ইন্টারনেট এলে স্বয়ংক্রিয়ভাবে ক্লাউডে ব্যাকআপ হবে।',
      'faq_q3': 'অ্যাপ আনইনস্টল হয়ে গেলে কি আমার ডেটা ফিরে পাবো?',
      'faq_a3': 'অ্যাপটি যদি গুগল ড্রাইভে ব্যাকআপ নেওয়া না থাকে, তবে অ্যাপ আনইনস্টল বা ফোন রিসেট দিলে লোকাল ডেটা সম্পূর্ণ ডিলিট হয়ে যাবে। যেহেতু আমরা কোনো ইউজার ডেটা সার্ভারে রাখি না, তাই ডেটা হারিয়ে গেলে তা রিকভার করার কোনো সুযোগ আমাদের কাছে নেই।',
      'faq_q4': 'রিমাইন্ডার ফিচারটি কীভাবে কাজ করে?',
      'faq_a4': 'আপনি নির্দিষ্ট দিন ও সময়ে কাজের রিমাইন্ডার সেট করতে পারেন। সেই সময় পুশ নোটিফিকেশনের মাধ্যমে অ্যাপ আপনাকে মনে করিয়ে দেবে।',
      'faq_q5': 'বাজেট ফিচারটির সুবিধা কী?',
      'faq_a5': 'ক্যাটাগরি ভিত্তিক সর্বোচ্চ খরচের সীমা নির্ধারণ করে আপনি অতিরিক্ত খরচ নিয়ন্ত্রণ করতে পারবেন। এটি সঞ্চয় করতে সাহায্য করে।',
      'faq_q6': 'নোটবুকে কি ছবি বা ড্রয়িং যোগ করা যায়?',
      'faq_a6': 'হ্যাঁ। আপনি টেক্সট নোটের সাথে ক্যামেরা বা গ্যালারি থেকে ছবি যোগ করতে পারেন এবং আঙ্গুল দিয়ে স্কেচ বা ড্রয়িং করতে পারেন।',
      'pin_required_first': 'পিন সেট না থাকলে লক চালু করা যাবে না। আগে পিন সেট করুন।',
      'pin_required_for_biometric': 'বায়োমেট্রিক ব্যবহার করতে আগে পিন সেট করুন।',
      'pin_changed_success': 'পিন সফলভাবে পরিবর্তিত হয়েছে',
      'enter_old_pin': 'পুরনো পিন দিন',
      'old_pin': 'বর্তমান পিন',
      'wrong_old_pin': 'পুরনো পিন ভুল, আবার চেষ্টা করুন',
      'verify': 'যাচাই করুন',
      'no_internet': 'ইন্টারনেট সংযোগ নেই। নেটওয়ার্ক চেক করুন।',
      'checking_updates': 'আপডেট চেক করা হচ্ছে...',
      'update_check_error': 'আপডেট চেক করা যায়নি। ইন্টারনেট সংযোগ নিশ্চিত করুন।',
      'update_unable': 'ভার্সন তথ্য পাওয়া যায়নি। পরে আবার চেষ্টা করুন।',
      'already_latest': 'আপনি সর্বশেষ ভার্সনে আছেন',
      'update_available': 'নতুন আপডেট পাওয়া গেছে!',
      'new_version_msg': 'নতুন ভার্সন উপলব্ধ:',
      'later': 'পরে দেখুন',
      'update_now': 'এখন আপডেট করুন',
      'cannot_open_url': 'ইউআরএল খোলা যায়নি',
      'current_version': 'বর্তমান ভার্সন:',
      'developer': 'ডেভেলপার',
      'support': 'সাপোর্ট',
      'all_rights_reserved': 'সর্বস্বত্ব সংরক্ষিত',
      'check_updates_title': 'আপডেট চেক করুন',
      'app_lock_enabled': 'অ্যাপ লক চালু করা হয়েছে',
      'pin_code': 'পিন কোড',
      'change_pin_button': 'পিন কোড পরিবর্তন করুন',
      'setup_pin_button': 'পিন কোড সেটআপ করুন',
      'biometric_lock': 'বায়োমেট্রিক লক',
      'biometric_only': 'শুধুমাত্র বায়োমেট্রিক',
      'pin_and_biometric': 'পিন + বায়োমেট্রিক',
      'lock_type_changed': 'লক টাইপ পরিবর্তন করা হয়েছে',
      'close': 'বন্ধ করুন',
      'editing': 'এডিটিং',
      'yearly_stats': 'বার্ষিক পরিসংখ্যান',
      'year_report': 'সালের রিপোর্ট',
      'income_expense_ratio': 'আয়-ব্যয়ের অনুপাত',
      'income_label': 'আয়',
      'expense_label': 'ব্যয়',
      'month': 'মাস',
      'total_label': 'মোট:',
      'drawing_create': 'ড্রয়িং তৈরি করুন',
      'drawing_edit': 'ড্রয়িং এডিট',
      'drawing_saved': 'ড্রয়িং সেভ হয়েছে',
      'write_note_hint': 'নোট লিখুন...',
      'enable_pin_code': 'পিন কোড সক্রিয় করুন',
      'change_pin_code': 'পিন কোড পরিবর্তন করুন',
      'disable_pin_code': 'পিন কোড নিষ্ক্রিয় করুন',
      'disable_pin_confirm_title': 'পিন কোড নিষ্ক্রিয় করুন',
      'pin_disabled': 'পিন কোড নিষ্ক্রিয় করা হয়েছে',
      'biometric_options': 'বায়োমেট্রিক অপশন',
      'daily_stats': 'দৈনিক পরিসংখ্যান',
      'all': 'সব',
      'total_income': 'মোট আয়',
      'total_expense': 'মোট ব্যয়',
      'transaction_history': 'লেনদেন ইতিহাস',
      'pdf': 'পিডিএফ',
      'select_date': 'নির্বাচন করুন',
      'select_time': 'নির্বাচন করুন',
      'saving': 'সেভ হচ্ছে...',
      'daily_report': 'দৈনিক রিপোর্ট',
      'export_success': 'এক্সপোর্ট সফল',
      'pdf_created_message': 'পিডিএফ ফাইল তৈরি হয়েছে। আপনি শেয়ার বা প্রিন্ট করতে পারেন।',
      'share': 'শেয়ার',
      'print': 'প্রিন্ট',
      'pdf_failed': 'পিডিএফ তৈরি করতে ব্যর্থ',
      'reminder_debt_payment': 'ঋণ পরিশোধের কথা মনে করিয়ে দিন',
      'from_date': 'থেকে',
      'to_date': 'পর্যন্ত',
      'start_date_before_end_date': 'শুরুর তারিখ শেষ তারিখের আগে হতে হবে',
      'end_date_after_start_date': 'শেষ তারিখ শুরুর তারিখের পরে হতে হবে',
      'good_morning': 'শুভ সকাল',
      'good_afternoon': 'শুভ অপরাহ্ন',
      'good_evening': 'শুভ সন্ধ্যা',
      'good_night': 'শুভ রাত্রি',
      'edit_reminder': 'রিমাইন্ডার সম্পাদনা',
      'reminder_updated': 'রিমাইন্ডার আপডেট করা হয়েছে',
      'reminder_comment': 'মন্তব্য',
      'enter_comment': 'মন্তব্য লিখুন...',
      'reminder_completed': 'সম্পন্ন',
      'mark_done': 'সম্পন্ন করুন',
      'snooze': 'পিছিয়ে দিন',
      'snooze_1h': '১ ঘন্টা',
      'snooze_1d': '১ দিন',
      'snooze_1w': '১ সপ্তাহ',
      'time_left': 'বাকি সময়',
      'overdue': 'মেয়াদ উত্তীর্ণ',
      'in_days': '%d দিন বাকি',
      'in_hours': '%d ঘন্টা বাকি',
      'in_minutes': '%d মিনিট বাকি',
      'cash': 'নগদ',
      'bank': 'ব্যাংক',
      'savings_type': 'সঞ্চয়ের ধরন',
      'gallery': 'গ্যালারি',
      'camera': 'ক্যামেরা',
      'backup': 'ব্যাকআপ',
      'restore': 'রিস্টোর',
      'restore_confirmation': 'সব ডাটা রিস্টোর করলে বর্তমান ডাটা মুছে যাবে। চালিয়ে যেতে চান?',
      'translating': 'অনুবাদ করা হচ্ছে...',
      'failed': 'ব্যর্থ',
      'google_drive_backup': 'গুগল ড্রাইভে ব্যাকআপ',
      'google_drive_restore': 'গুগল ড্রাইভ থেকে রিস্টোর',
      'sign_in_google': 'গুগলে সাইন ইন করুন',
      'daily_reminder_title': 'দৈনিক হিসাব রিমাইন্ডার',
      'set_daily_reminder': 'দৈনিক রিমাইন্ডার সেট করুন',
      'reminder_set': 'রিমাইন্ডার সেট করা হয়েছে',
      'miscellaneous_notices': 'বিবিধ নোটিশ',
      'reminders': 'রিমাইন্ডার',
      'morning_reminder_title': '🌅 শুভ সকাল',
      'morning_reminder_body': 'শুভ সকাল! আজকের নতুন দিনে আপনার আয়-ব্যয়ের হিসাব আপডেট করুন। সুন্দর একটি দিন কাটুক!',
      'evening_reminder_title': '🌇 শুভ বিকাল',
      'evening_reminder_body': 'শুভ বিকাল! দিনের অর্ধেক পেরিয়ে গেছে। আজকের আয়-ব্যয়ের হিসাব একবার চেক করে নিন।',
      'night_reminder_title': '🌙 শুভ রাত্রি',
      'night_reminder_body': 'শুভ রাত্রি! আজকের দিনের সব লেনদেন শেষ করুন। আগামীকালের জন্য প্রস্তুত হন।',
      'backup_success': 'ব্যাকআপ সফল!',
      'backup_location': 'ফাইলের অবস্থান:',
      'backup_share_message': 'আমার হিসাব ব্যাকআপ ফাইল শেয়ার করুন',
      'please_wait': 'দয়া করে অপেক্ষা করুন...',
      'saving': 'সেভ হচ্ছে...',
      'share': 'শেয়ার',
      'close': 'বন্ধ করুন',
      'restore_success': 'রিস্টোর সফল!',
      'restore': 'রিস্টোর',
      'restore_confirmation': 'সব ডাটা রিস্টোর করলে বর্তমান ডাটা মুছে যাবে। চালিয়ে যেতে চান?',
      'ok': 'ঠিক আছে',
      'yes': 'হ্যাঁ',
      'no': 'না',
      'please_wait': 'দয়া করে অপেক্ষা করুন...',
      'change_photo': 'ছবি পরিবর্তন',
      'take_photo': 'ক্যামেরা',
      'choose_gallery': 'গ্যালারি',
      'remove_photo': 'ছবি সরান',
      'cancel': 'বাতিল',
      'profile_pic_removed': 'প্রোফাইল পিকচার রিমুভ করা হয়েছে',
      'default_user': 'ব্যবহারকারী',
      'refresh': 'রিফ্রেশ',
      'notices_refreshed': 'নোটিশ রিফ্রেশ করা হয়েছে',
      'add_new_category': 'নতুন ক্যাটাগরি যোগ করুন',
      'add_new_category_dialog_title': 'নতুন ক্যাটাগরি যোগ করুন',
      'category_name': 'ক্যাটাগরির নাম',
      'add': 'যোগ করুন',
      'edit_category': 'ক্যাটাগরি সম্পাদনা',
      'delete_category': 'ক্যাটাগরি মুছুন',
      'delete_category_confirm': 'আপনি কি "{name}" ক্যাটাগরিটি মুছতে চান?',
      'category_exists': 'এই নামে একটি ক্যাটাগরি ইতিমধ্যে আছে!',
      'category_added': 'ক্যাটাগরি যোগ করা হয়েছে',
      'category_deleted': 'ক্যাটাগরি মুছে ফেলা হয়েছে',
    },
    'en': {
      'app_title': 'My Accounting',
      'home': 'Home',
      'calendar': 'Calendar',
      'notice': 'Notice',
      'notebook': 'Notebook',
      'profile': 'Profile',
      'income': 'Income',
      'expense': 'Expense',
      'savings': 'Savings',
      'debt': 'Payable',
      'credit': 'Receivable',
      'monthly_stats': 'Monthly Statistics',
      'monthly_report': 'Monthly Report',
      'select_month': 'Select month',
      'balance': 'Balance',
      'income_expense_stats': 'Stats',
      'other_accounts': 'Other',
      'recent_transactions': 'Recent',
      'daily': 'Daily',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'no_transactions': 'No transactions',
      'add_income': 'Add Income',
      'add_expense': 'Add Expense',
      'add_reminder': 'Add Reminder',
      'no_reminders': 'No reminders',
      'no_notices': 'No notices',
      'no_notes': 'No notes',
      'no_drawing': 'No drawings',
      'add_note': 'New Note',
      'add_drawing': 'Add Drawing',
      'text_note': 'Note',
      'drawing': 'Drawing',
      'archive': 'Archive',
      'yes': 'Yes',
      'no': 'No',
      'save': 'Save',
      'cancel': 'Cancel',
      'amount': 'Amount',
      'description': 'Description',
      'title': 'Title',
      'date': 'Date',
      'time': 'Time',
      'logout': 'Logout',
      'settings': 'Settings',
      'language': 'Language',
      'currency': 'Currency',
      'dark_mode': 'Dark Mode',
      'user_name': 'Name',
      'change_photo': 'Change Photo',
      'take_photo': 'Camera',
      'choose_gallery': 'Gallery',
      'edit': 'Edit',
      'delete': 'Delete',
      'ok': 'OK',
      'select_category': 'Category',
      'amount_error': 'Enter amount',
      'salary': 'Salary',
      'business': 'Business',
      'house_rent': 'House Rent',
      'other': 'Other',
      'gas_bill': 'Gas Bill',
      'electricity_bill': 'Electricity Bill',
      'internet_bill': 'Internet',
      'water_bill': 'Water',
      'transport': 'Transport',
      'grocery': 'Grocery',
      'education': 'Education',
      'medical': 'Medical',
      'food': 'Food',
      'mobile_bill': 'Mobile',
      'entertainment': 'Entertainment',
      'government_holiday': 'Holiday',
      'holidays': 'Holidays',
      'notification_scheduled': 'Notification',
      'budget_management': 'Budget',
      'monthly_budget': 'Monthly Budget',
      'budget_spent': 'Spent',
      'total_budget': 'Total Budget',
      'used': 'Used',
      'remaining': 'Remaining',
      'budget_exceeded': 'Exceeded',
      'recurring_transactions': 'Recurring',
      'export_report': 'Export',
      'security_settings': 'Security',
      'change_settings': 'Change Settings',
      'delete_confirm': 'Are you sure?',
      'show_hijri': 'Show Hijri',
      'show_bengali': 'Show Bengali',
      'calendar_settings': 'Calendar Settings',
      'set_pin': 'Set PIN',
      'new_pin': 'New PIN',
      'confirm_pin': 'Confirm PIN',
      'disable_lock': 'Disable Lock',
      'pin_required_first': 'Cannot enable lock without a PIN. Please set a PIN first.',
      'pin_required_for_biometric': 'Please set a PIN first to use biometric.',
      'pin_changed_success': 'PIN changed successfully',
      'enter_old_pin': 'Enter old PIN',
      'old_pin': 'Current PIN',
      'wrong_old_pin': 'Wrong old PIN, try again',
      'verify': 'Verify',
      'no_internet': 'No internet connection. Please check your network.',
      'checking_updates': 'Checking for updates...',
      'update_check_error': 'Could not check for updates. Please ensure you have an internet connection.',
      'update_unable': 'Unable to get version info. Please try again later.',
      'already_latest': 'You are on the latest version',
      'update_available': 'Update Available!',
      'new_version_msg': 'A new version is available:',
      'later': 'Later',
      'enable_pin_code': 'Enable PIN Code',
      'change_pin_code': 'Change PIN Code',
      'disable_pin_code': 'Disable PIN Code',
      'disable_pin_confirm_title': 'Disable PIN Code',
      'pin_disabled': 'PIN code disabled',
      'biometric_options': 'Biometric Options',
      'update_now': 'Update Now',
      'cannot_open_url': 'Cannot open URL',
      'current_version': 'Current version:',
      'developer': 'Developer',
      'support': 'Support',
      'all_rights_reserved': 'All rights reserved',
      'check_updates_title': 'Check for Updates',
      'app_lock_enabled': 'App lock enabled',
      'pin_code': 'PIN Code',
      'change_pin_button': 'Change PIN Code',
      'setup_pin_button': 'Setup PIN Code',
      'biometric_lock': 'Biometric Lock',
      'biometric_only': 'Biometric Only',
      'pin_and_biometric': 'PIN + Biometric',
      'lock_type_changed': 'Lock type changed',
      'disable_lock_confirm': 'Do you want to disable the lock system?',
      'app_lock_desc': 'Require PIN/Biometric to open the app',
      'lock_type': 'Lock Type',
      'pin_only': 'PIN only',
      'pin_and_biometric': 'PIN & Biometric',
      'change_pin': 'Change PIN',
      'about_app': 'About App',
      'app_description': 'A simple app to track your daily income, expenses and transactions with offline support, backup and security features.',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'pin_set_success': 'PIN set successfully',
      'pin_mismatch': 'PIN mismatch, try again',
      'lock_disabled': 'Lock disabled',
      'faq_title': '🙋‍♂️ Frequently Asked Questions',
      'faq_q1': 'What are the main features of this app?',
      'faq_a1': 'This app is your all-in-one assistant. It offers 4 main features:\n\n📊 Income/Expense Tracking\n📓 Notebook & Drawing\n⏰ Reminders\n💰 Budget Planning',
      'faq_q2': 'Do I need internet to use the app?',
      'faq_a2': 'The app works online and offline. Without internet, you can still add transactions, notes and reminders. When you go online, everything syncs automatically to the cloud.',
      'faq_q3': 'What happens if I uninstall the app?',
      'faq_a3': 'If you have not backed up to Google Drive, uninstalling or resetting your phone will permanently delete local data. Since we do not store user data on servers, lost data cannot be recovered.',
      'faq_q4': 'How does the reminder feature work?',
      'faq_a4': 'You can set a reminder for any task with a specific date and time. At the scheduled time, the app will notify you via push notification.',
      'faq_q5': 'What is the benefit of the budget feature?',
      'faq_a5': 'You can set spending limits per category to control your expenses. This helps you save money.',
      'faq_q6': 'Can I add images or drawings to my notes?',
      'faq_a6': 'Yes. You can attach images from camera/gallery and also draw or sketch on the canvas inside the notebook.',
      'close': 'Close',
      'editing': 'Editing',
      'yearly_stats': 'Yearly Statistics',
      'year_report': 'Year Report',
      'income_expense_ratio': 'Income-Expense Ratio',
      'income_label': 'Income',
      'expense_label': 'Expense',
      'month': 'Month',
      'total_label': 'Total:',
      'drawing_create': 'Create Drawing',
      'drawing_edit': 'Edit Drawing',
      'drawing_saved': 'Drawing saved',
      'write_note_hint': 'Write a note...',
      'daily_stats': 'Daily Statistics',
      'all': 'All',
      'total_income': 'Total Income',
      'total_expense': 'Total Expense',
      'transaction_history': 'Transaction History',
      'pdf': 'PDF',
      'saving': 'Saving...',
      'daily_report': 'Daily Report',
      'export_success': 'Export Successful',
      'pdf_created_message': 'PDF file created. You can share or print it.',
      'share': 'Share',
      'print': 'Print',
      'pdf_failed': 'Failed to create PDF',
      'reminder_debt_payment': 'Reminder: Payable payment',
      'from_date': 'From',
      'to_date': 'To',
      'start_date_before_end_date': 'Start date must be before end date',
      'end_date_after_start_date': 'End date must be after start date',
      'good_morning': 'Good Morning',
      'good_afternoon': 'Good Afternoon',
      'good_evening': 'Good Evening',
      'good_night': 'Good Night',
      'edit_reminder': 'Edit Reminder',
      'reminder_updated': 'Reminder updated',
      'reminder_comment': 'Comment',
      'enter_comment': 'Enter comment...',
      'reminder_completed': 'Completed',
      'mark_done': 'Mark Done',
      'snooze': 'Snooze',
      'snooze_1h': '1 hour',
      'snooze_1d': '1 day',
      'snooze_1w': '1 week',
      'time_left': 'Time left',
      'overdue': 'Overdue',
      'in_days': '%d days left',
      'in_hours': '%d hours left',
      'in_minutes': '%d minutes left',
      'cash': 'Cash',
      'bank': 'Bank',
      'savings_type': 'Savings Type',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'backup': 'Backup',
      'restore': 'Restore',
      'restore_confirmation': 'Restoring will overwrite all current data. Continue?',
      'translating': 'Translating...',
      'failed': 'Failed',
      'google_drive_backup': 'Backup to Google Drive',
      'google_drive_restore': 'Restore from Google Drive',
      'sign_in_google': 'Sign in with Google',
      'daily_reminder_title': 'Daily Accounting Reminder',
      'set_daily_reminder': 'Set Daily Reminder',
      'reminder_set': 'Reminder set',
      'miscellaneous_notices': 'Miscellaneous Notices',
      'reminders': 'Reminders',
      'morning_reminder_title': '🌅 Good Morning',
      'morning_reminder_body': 'Good morning! Update your income & expense records for today. Have a great day!',
      'evening_reminder_title': '🌇 Good Afternoon',
      'evening_reminder_body': 'Good afternoon! Half the day is over. Review your financial summary now.',
      'night_reminder_title': '🌙 Good Night',
      'night_reminder_body': 'Good night! Finalize today\'s transactions and get ready for tomorrow.',
      'backup_success': 'Backup Successful!',
      'backup_location': 'File location:',
      'backup_share_message': 'Share Amar Hisab backup file',
      'please_wait': 'Please wait...',
      'saving': 'Saving...',
      'share': 'Share',
      'close': 'Close',
      'restore_success': 'Restore Successful!',
      'restore': 'Restore',
      'restore_confirmation': 'Restoring will overwrite all current data. Continue?',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'please_wait': 'Please wait...',
      'change_photo': 'Change Photo',
      'take_photo': 'Camera',
      'choose_gallery': 'Gallery',
      'remove_photo': 'Remove Photo',
      'cancel': 'Cancel',
      'profile_pic_removed': 'Profile picture removed',
      'default_user': 'User',
      'refresh': 'Refresh',
      'notices_refreshed': 'Notices refreshed',
      'add_new_category': 'Add New Category',
      'add_new_category_dialog_title': 'Add New Category',
      'category_name': 'Category Name',
      'add': 'Add',
      'edit_category': 'Edit Category',
      'delete_category': 'Delete Category',
      'delete_category_confirm': 'Are you sure you want to delete "{name}"?',
      'category_exists': 'A category with this name already exists!',
      'category_added': 'Category added',
      'category_deleted': 'Category deleted',
    },
    'ar': {
      'app_title': 'محاسبتي',
      'home': 'الرئيسية',
      'calendar': 'التقويم',
      'notice': 'الإشعارات',
      'notebook': 'دفتر الملاحظات',
      'profile': 'الملف الشخصي',
      'income': 'دخل',
      'expense': 'مصروف',
      'savings': 'مدخرات',
      'debt': 'مستحق الدفع',
      'credit': 'مستحق القبض',
      'monthly_stats': 'الإحصائيات الشهرية',
      'monthly_report': 'تقرير شهري',
      'select_month': 'اختر الشهر',
      'balance': 'رصيد',
      'income_expense_stats': 'إحصائيات',
      'other_accounts': 'أخرى',
      'recent_transactions': 'الأخيرة',
      'daily': 'يومي',
      'monthly': 'شهري',
      'yearly': 'سنوي',
      'no_transactions': 'لا معاملات',
      'add_income': 'إضافة دخل',
      'add_expense': 'إضافة مصروف',
      'add_reminder': 'إضافة تذكير',
      'no_reminders': 'لا تذكيرات',
      'no_notices': 'لا إشعارات',
      'no_notes': 'لا ملاحظات',
      'no_drawing': 'لا توجد رسومات',
      'add_note': 'ملاحظة جديدة',
      'add_drawing': 'إضافة رسم',
      'text_note': 'ملاحظة',
      'drawing': 'رسم',
      'archive': 'أرشفة',
      'yes': 'نعم',
      'no': 'لا',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'amount': 'المبلغ',
      'description': 'الوصف',
      'title': 'العنوان',
      'date': 'التاريخ',
      'time': 'الوقت',
      'logout': 'خروج',
      'settings': 'إعدادات',
      'language': 'اللغة',
      'currency': 'العملة',
      'dark_mode': 'داكن',
      'user_name': 'الاسم',
      'change_photo': 'تغيير الصورة',
      'take_photo': 'كاميرا',
      'choose_gallery': 'معرض',
      'edit': 'تعديل',
      'delete': 'حذف',
      'ok': 'حسنا',
      'select_category': 'الفئة',
      'amount_error': 'أدخل المبلغ',
      'salary': 'راتب',
      'business': 'عمل',
      'house_rent': 'إيجار',
      'other': 'آخر',
      'gas_bill': 'غاز',
      'electricity_bill': 'فاتورة الكهرباء',
      'internet_bill': 'إنترنت',
      'water_bill': 'ماء',
      'transport': 'نقل',
      'grocery': 'بقالة',
      'education': 'تعليم',
      'medical': 'طبي',
      'food': 'طعام',
      'mobile_bill': 'جوال',
      'entertainment': 'ترفيه',
      'government_holiday': 'عطلة',
      'holidays': 'عطل',
      'notification_scheduled': 'إشعار',
      'budget_management': 'ميزانية',
      'monthly_budget': 'شهري',
      'budget_spent': 'أنفق',
      'total_budget': 'الإجمالي',
      'used': 'مستخدم',
      'remaining': 'متبقي',
      'budget_exceeded': 'تجاوز',
      'recurring_transactions': 'متكرر',
      'export_report': 'تصدير',
      'security_settings': 'أمان',
      'change_settings': 'تغيير',
      'delete_confirm': 'هل أنت متأكد؟',
      'show_hijri': 'إظهار الهجري',
      'show_bengali': 'إظهار البنغالي',
      'calendar_settings': 'إعدادات التقويم',
      'set_pin': 'تعيين الرمز',
      'new_pin': 'رمز جديد',
      'confirm_pin': 'تأكيد الرمز',
      'disable_lock': 'تعطيل القفل',
      'pin_required_first': 'لا يمكن تمكين القفل بدون رمز PIN. يرجى تعيين رمز PIN أولاً.',
      'pin_required_for_biometric': 'يرجى تعيين رمز PIN أولاً لاستخدام القياسات الحيوية.',
      'pin_changed_success': 'تم تغيير الرمز بنجاح',
      'enter_old_pin': 'أدخل الرمز القديم',
      'old_pin': 'الرمز الحالي',
      'wrong_old_pin': 'الرمز القديم خاطئ، حاول مرة أخرى',
      'verify': 'تحقق',
      'no_internet': 'لا يوجد اتصال بالإنترنت. يرجى التحقق من شبكتك.',
      'checking_updates': 'جارٍ التحقق من التحديثات...',
      'update_check_error': 'تعذر التحقق من التحديثات. يرجى التأكد من وجود اتصال بالإنترنت.',
      'update_unable': 'تعذر الحصول على معلومات الإصدار. يرجى المحاولة لاحقًا.',
      'already_latest': 'أنت على أحدث إصدار',
      'update_available': 'تحديث متوفر!',
      'new_version_msg': 'إصدار جديد متاح:',
      'later': 'لاحقًا',
      'enable_pin_code': 'تفعيل رمز PIN',
      'change_pin_code': 'تغيير رمز PIN',
      'disable_pin_code': 'تعطيل رمز PIN',
      'disable_pin_confirm_title': 'تعطيل رمز PIN',
      'pin_disabled': 'تم تعطيل رمز PIN',
      'biometric_options': 'خيارات القياسات الحيوية',
      'update_now': 'تحديث الآن',
      'cannot_open_url': 'لا يمكن فتح الرابط',
      'current_version': 'الإصدار الحالي:',
      'developer': 'المطور',
      'support': 'الدعم',
      'all_rights_reserved': 'جميع الحقوق محفوظة',
      'check_updates_title': 'التحقق من التحديثات',
      'app_lock_enabled': 'تم تمكين قفل التطبيق',
      'pin_code': 'رمز PIN',
      'change_pin_button': 'تغيير رمز PIN',
      'setup_pin_button': 'إعداد رمز PIN',
      'biometric_lock': 'قفل القياسات الحيوية',
      'biometric_only': 'القياسات الحيوية فقط',
      'pin_and_biometric': 'PIN + القياسات الحيوية',
      'lock_type_changed': 'تم تغيير نوع القفل',
      'disable_lock_confirm': 'هل تريد تعطيل نظام القفل؟',
      'app_lock_desc': 'مطلوب رمز أو بصمة لفتح التطبيق',
      'lock_type': 'نوع القفل',
      'pin_only': 'رمز فقط',
      'pin_and_biometric': 'الرمز والبصمة',
      'change_pin': 'تغيير الرمز',
      'about_app': 'عن التطبيق',
      'app_description': 'تطبيق بسيط لتتبع دخلك ونفقاتك اليومية مع دعم غير متصل بالإنترنت والنسخ الاحتياطي وميزات الأمان.',
      'privacy_policy': 'سياسة الخصوصية',
      'terms_of_service': 'شروط الخدمة',
      'pin_set_success': 'تم تعيين الرمز بنجاح',
      'pin_mismatch': 'الرمز غير متطابق، حاول مرة أخرى',
      'lock_disabled': 'تم تعطيل القفل',
      'faq_title': '🙋‍♂️ الأسئلة الشائعة',
      'faq_q1': 'ما هي الميزات الرئيسية لهذا التطبيق؟',
      'faq_a1': 'هذا التطبيق هو مساعد شامل. يوفر 4 ميزات رئيسية:\n\n📊 تتبع الدخل والمصروفات\n📓 دفتر الملاحظات والرسم\n⏰ تذكيرات\n💰 تخطيط الميزانية',
      'faq_q2': 'هل أحتاج إلى الإنترنت لاستخدام التطبيق؟',
      'faq_a2': 'التطبيق يعمل عبر الإنترنت وغير متصل. بدون إنترنت، لا يزال بإمكانك إضافة المعاملات والملاحظات والتذكيرات. عندما تتصل بالإنترنت، تتم مزامنة كل شيء تلقائياً مع السحابة.',
      'faq_q3': 'ماذا يحدث إذا قمت بإلغاء تثبيت التطبيق؟',
      'faq_a3': 'إذا لم تقم بعمل نسخة احتياطية على Google Drive، فإن إلغاء التثبيت أو إعادة ضبط الهاتف سيؤدي إلى حذف البيانات المحلية بالكامل. نظرًا لأننا لا نخزن بيانات المستخدم على الخوادم، فلا يمكن استرداد البيانات المفقودة.',
      'faq_q4': 'كيف تعمل ميزة التذكير؟',
      'faq_a4': 'يمكنك تعيين تذكير لأي مهمة بتاريخ ووقت محددين. في الوقت المحدد، سيقوم التطبيق بإعلامك عبر إشعار.',
      'faq_q5': 'ما فائدة ميزة الميزانية؟',
      'faq_a5': 'يمكنك تعيين حدود الإنفاق لكل فئة للتحكم في نفقاتك. هذا يساعدك على توفير المال.',
      'faq_q6': 'هل يمكنني إضافة صور أو رسومات إلى ملاحظاتي؟',
      'faq_a6': 'نعم. يمكنك إرفاق صور من الكاميرا / المعرض وكذلك الرسم أو التخطيط على اللوحة داخل دفتر الملاحظات.',
      'close': 'إغلاق',
      'editing': 'تحرير',
      'drawing_create': 'إنشاء رسم',
      'drawing_edit': 'تحرير الرسم',
      'drawing_saved': 'تم حفظ الرسم',
      'write_note_hint': 'اكتب ملاحظة...',
      'daily_stats': 'الإحصائيات اليومية',
      'all': 'الكل',
      'total_income': 'إجمالي الدخل',
      'total_expense': 'إجمالي المصروفات',
      'transaction_history': 'سجل المعاملات',
      'pdf': 'PDF',
      'saving': 'جاري الحفظ...',
      'daily_report': 'تقرير يومي',
      'export_success': 'تم التصدير بنجاح',
      'pdf_created_message': 'تم إنشاء ملف PDF. يمكنك مشاركته أو طباعته.',
      'share': 'مشاركة',
      'print': 'طباعة',
      'pdf_failed': 'فشل إنشاء PDF',
      'reminder_debt_payment': 'تذكير: دفع المستحق',
      'good_morning': 'صباح الخير',
      'good_afternoon': 'مساء الخير',
      'good_evening': 'مساء الخير',
      'good_night': 'تصبح على خير',
      'edit_reminder': 'تحرير التذكير',
      'reminder_updated': 'تم تحديث التذكير',
      'reminder_comment': 'تعليق',
      'enter_comment': 'أدخل تعليقاً...',
      'reminder_completed': 'مكتمل',
      'mark_done': 'تحديد كمكتمل',
      'snooze': 'تأجيل',
      'snooze_1h': 'ساعة واحدة',
      'snooze_1d': 'يوم واحد',
      'snooze_1w': 'أسبوع واحد',
      'time_left': 'الوقت المتبقي',
      'overdue': 'متأخر',
      'in_days': 'متبقي %d أيام',
      'in_hours': 'متبقي %d ساعات',
      'in_minutes': 'متبقي %d دقائق',
      'cash': 'نقدي',
      'bank': 'بنك',
      'savings_type': 'نوع المدخرات',
      'gallery': 'معرض الصور',
      'camera': 'الكاميرا',
      'backup': 'نسخ احتياطي',
      'restore': 'استعادة',
      'restore_confirmation': 'سيؤدي الاستعادة إلى استبدال جميع البيانات الحالية. هل تريد المتابعة؟',
      'translating': 'جاري الترجمة...',
      'failed': 'فشل',
      'google_drive_backup': 'نسخ احتياطي إلى جوجل درايف',
      'google_drive_restore': 'استعادة من جوجل درايف',
      'sign_in_google': 'تسجيل الدخول بحساب جوجل',
      'daily_reminder_title': 'تذكير يومي بالمحاسبة',
      'set_daily_reminder': 'تعيين تذكير يومي',
      'reminder_set': 'تم تعيين التذكير',
      'miscellaneous_notices': 'إشعارات متنوعة',
      'reminders': 'تذكيرات',
      'morning_reminder_title': '🌅 صباح الخير',
      'morning_reminder_body': 'صباح الخير! قم بتحديث سجلات الدخل والمصروفات لهذا اليوم. يوم سعيد!',
      'evening_reminder_title': '🌇 مساء الخير',
      'evening_reminder_body': 'مساء الخير! مضى نصف اليوم. راجع ملخصك المالي الآن.',
      'night_reminder_title': '🌙 تصبح على خير',
      'night_reminder_body': 'تصبح على خير! أنهِ معاملات اليوم واستعد للغد.',
      'backup_success': 'تم النسخ الاحتياطي بنجاح!',
      'backup_location': 'موقع الملف:',
      'backup_share_message': 'مشاركة ملف النسخ الاحتياطي لتطبيق محاسبتي',
      'please_wait': 'يرجى الانتظار...',
      'saving': 'جاري الحفظ...',
      'share': 'مشاركة',
      'close': 'إغلاق',
      'restore_success': 'تمت الاستعادة بنجاح!',
      'restore': 'استعادة',
      'restore_confirmation': 'سيؤدي الاستعادة إلى استبدال جميع البيانات الحالية. هل تريد المتابعة؟',
      'ok': 'حسنا',
      'yes': 'نعم',
      'no': 'لا',
      'please_wait': 'يرجى الانتظار...',
      'change_photo': 'تغيير الصورة',
      'take_photo': 'كاميرا',
      'choose_gallery': 'معرض الصور',
      'remove_photo': 'إزالة الصورة',
      'cancel': 'إلغاء',
      'profile_pic_removed': 'تمت إزالة الصورة الشخصية',
      'default_user': 'مستخدم افتراضي',
      'refresh': 'تحديث',
      'notices_refreshed': 'تم تحديث الإشعارات',
      'add_new_category': 'إضافة فئة جديدة',
      'add_new_category_dialog_title': 'إضافة فئة جديدة',
      'category_name': 'اسم الفئة',
      'add': 'إضافة',
      'edit_category': 'تعديل الفئة',
      'delete_category': 'حذف الفئة',
      'delete_category_confirm': 'هل أنت متأكد من حذف "{name}"؟',
      'category_exists': 'هناك فئة بهذا الاسم بالفعل!',
      'category_added': 'تمت إضافة الفئة',
      'category_deleted': 'تم حذف الفئة',
    },
  };

  String getText(String key) =>
      _localizedText[_selectedLanguage]?[key] ?? _localizedText['bn']?[key] ?? key;

  List<Map<String, dynamic>> incomeCategories = [
    {'key': 'salary', 'icon': Icons.work, 'color': Colors.green},
    {'key': 'business', 'icon': Icons.store, 'color': Colors.blue},
    {'key': 'house_rent', 'icon': Icons.house, 'color': Colors.orange},
    {'key': 'other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  List<Map<String, dynamic>> expenseCategories = [
    {'key': 'gas_bill', 'icon': Icons.electric_bolt, 'color': Colors.red},
    {'key': 'electricity_bill', 'icon': Icons.electric_bolt, 'color': Colors.amber},
    {'key': 'house_rent', 'icon': Icons.house, 'color': Colors.orange},
    {'key': 'internet_bill', 'icon': Icons.wifi, 'color': Colors.blue},
    {'key': 'water_bill', 'icon': Icons.water_drop, 'color': Colors.cyan},
    {'key': 'transport', 'icon': Icons.directions_bus, 'color': Colors.green},
    {'key': 'grocery', 'icon': Icons.shopping_cart, 'color': Colors.deepOrange},
    {'key': 'education', 'icon': Icons.school, 'color': Colors.purple},
    {'key': 'medical', 'icon': Icons.medical_services, 'color': Colors.redAccent},
    {'key': 'food', 'icon': Icons.restaurant, 'color': Colors.amber},
    {'key': 'mobile_bill', 'icon': Icons.phone_android, 'color': Colors.indigo},
    {'key': 'entertainment', 'icon': Icons.tv, 'color': Colors.pink},
    {'key': 'other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  String getCategoryName(String key) {
    final allCats = CategoryService().allCategories;
    final matching = allCats.where((c) => c['key'] == key).toList();
    if (matching.isNotEmpty && matching.first['isCustom'] == true) {
      return matching.first['key'];
    }
    return getText(key);
  }

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<Map<String, dynamic>> _allReminders = [];
  String _display = "0";
  double? _firstValue;
  String? _operator;
  bool _shouldResetDisplay = false;
  bool _isNewNumber = true;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final Connectivity _connectivity = Connectivity();

  // ========== Helper Methods ==========
  String _getCurrentGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return getText('good_morning');
    if (hour < 17) return getText('good_afternoon');
    if (hour < 21) return getText('good_evening');
    return getText('good_night');
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny;
    if (hour < 17) return Icons.wb_sunny;
    if (hour < 21) return Icons.brightness_3;
    return Icons.nights_stay;
  }

  String _convertToEnglishDigits(String input) {
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(bengali[i], english[i]);
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  String _convertToScriptDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    List<String> target;
    if (_selectedLanguage == 'bn') {
      target = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    } else if (_selectedLanguage == 'ar') {
      target = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    } else {
      return input;
    }
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], target[i]);
    }
    return input;
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      String engStr = timeStr;
      for (int i = 0; i < english.length; i++) {
        engStr = engStr.replaceAll(bengali[i], english[i]);
        engStr = engStr.replaceAll(arabic[i], english[i]);
      }

      try {
        final format = DateFormat('h:mm a');
        final date = format.parse(engStr);
        return TimeOfDay(hour: date.hour, minute: date.minute);
      } catch (_) {
        try {
          final format = DateFormat('HH:mm');
          final date = format.parse(engStr);
          return TimeOfDay(hour: date.hour, minute: date.minute);
        } catch (_) {
          return TimeOfDay.now();
        }
      }
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  String _getTimeLeftString(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    if (difference.isNegative) return getText('overdue');
    if (difference.inDays >= 1) return getText('in_days').replaceAll('%d', difference.inDays.toString());
    if (difference.inHours >= 1) return getText('in_hours').replaceAll('%d', difference.inHours.toString());
    return getText('in_minutes').replaceAll('%d', difference.inMinutes.toString());
  }

  String _formatAmount(double amount) {
    String locale = _selectedLanguage == 'bn' ? 'bn' : (_selectedLanguage == 'ar' ? 'ar' : 'en');
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: _currencySymbols[_selectedCurrency] ?? '৳',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // ========== Lifecycle ==========
  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _loadLocalProfilePic();
    _initializeNotifications();
    _loadDataFromHive();
    _startAutoBackupListener();
    _loadRemoteNotices();
    _loadDailyReminderTime();
  }

  Future<void> _loadDataFromHive() async {
    final txBox = Hive.box<TransactionModel>('transactions');
    _processTransactions(txBox.values.toList());
    setState(() {});
  }

  void _processTransactions(List<TransactionModel> transactions) {
    Map<DateTime, List<Map<String, dynamic>>> newEvents = {};
    List<Map<String, dynamic>> reminders = [];
    List<Map<String, dynamic>> textNotes = [];
    List<Map<String, dynamic>> drawingNotes = [];

    for (var tx in transactions) {
      if (tx.type == 'Reminder' && !tx.isArchived && !tx.isPaid) {
        try {
          DateTime date = DateFormat('dd/MM/yyyy').parse(tx.date);
          newEvents.putIfAbsent(date, () => []);
          newEvents[date]!.add({'key': tx.id, 'note': tx.note ?? '', 'time': tx.time ?? '12:00 AM', 'completed': tx.isPaid});
          reminders.add({'key': tx.id, 'note': tx.note ?? '', 'date': tx.date, 'time': tx.time ?? '12:00 AM', 'completed': tx.isPaid});
        } catch (_) {}
      }
      if (tx.type == 'Note' && !tx.isArchived) {
        bool hasDrawing = false;
        if (tx.category.startsWith('{')) {
          try {
            final extra = json.decode(tx.category);
            hasDrawing = extra['hasDrawing'] == true;
          } catch (_) {}
        }
        final noteMap = {'key': tx.id, 'note': tx.note ?? '', 'date': tx.date ?? '', 'category': tx.category};
        if (hasDrawing) drawingNotes.add(noteMap);
        else textNotes.add(noteMap);
      }
    }
    setState(() {
      _events = newEvents;
      _allReminders = reminders;
      _textNotes = textNotes;
      _drawingNotes = drawingNotes;
    });
  }

  void _loadLocalProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _localProfilePicPath = prefs.getString('local_profile_pic'));
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '';
      _profileImagePath = prefs.getString('profileImagePath');
      _selectedCurrency = prefs.getString('currency') ?? 'BDT';
      _showHijriDate = prefs.getBool('showHijriDate') ?? true;
      _showBengaliDate = prefs.getBool('showBengaliDate') ?? true;
      _selectedLanguage = widget.initialLanguage;
      _isDarkMode = widget.initialDarkMode;
    });
  }

  Future<void> _saveUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setString('userName', _userName);
    if (_profileImagePath != null) {
      await prefs.setString('profileImagePath', _profileImagePath!);
    }
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setBool('showHijriDate', _showHijriDate);
    await prefs.setBool('showBengaliDate', _showBengaliDate);
    setState(() {});
    widget.onSettingsChanged(
      language: _selectedLanguage,
      isDarkMode: _isDarkMode,
    );
  }

  // ========== Translation API ==========
  Future<String> _translateText(String text, String targetLang) async {
    if (text.isEmpty) return text;
    try {
      final lang = targetLang == 'bn' ? 'bn' : (targetLang == 'ar' ? 'ar' : 'en');
      final url = Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=auto|$lang');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseStatus'] == 200 && data['responseData'] != null) {
          String translated = data['responseData']['translatedText'] ?? text;
          translated = translated.replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'")
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>');
          if (translated == text || translated.contains('invalid source language')) {
            return text;
          }
          return translated;
        }
      }
    } catch (e) {
      print('Translation error: $e');
    }
    return text;
  }

  Future<void> _translateAllUserData(String targetLang) async {
    final txBox = Hive.box<TransactionModel>('transactions');
    final recurringBox = Hive.box<RecurringTransactionModel>('recurring');
    List<Future> translations = [];

    for (var tx in txBox.values) {
      if (tx.note != null && tx.note!.isNotEmpty) {
        translations.add(_translateText(tx.note!, targetLang).then((translated) {
          tx.note = translated;
          txBox.put(tx.id, tx);
        }));
      }
    }

    for (var r in recurringBox.values) {
      if (r.note != null && r.note!.isNotEmpty) {
        translations.add(_translateText(r.note!, targetLang).then((translated) {
          r.note = translated;
          recurringBox.put(r.id, r);
        }));
      }
    }

    await Future.wait(translations);
    await _loadDataFromHive();
  }

  // ========== Notifications ==========
  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iOSSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (mounted) setState(() => _currentIndex = 2);
        if (response.payload != null) {
          final parts = response.payload!.split('|');
          if (parts.length == 2) {
            if (parts[1] == 'done') _markReminderDone(parts[0]);
            else if (parts[1] == 'snooze') _showSnoozeDialog(parts[0]);
          }
        }
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      const dailyChannel = AndroidNotificationChannel(
        'daily_reminder_channel',
        'দৈনিক রিমাইন্ডার',
        importance: Importance.high,
      );
      await androidPlugin?.createNotificationChannel(dailyChannel);

      const reminderChannel = AndroidNotificationChannel(
        'r',
        'রিমাইন্ডার',
        importance: Importance.max,
      );
      await androidPlugin?.createNotificationChannel(reminderChannel);

      const noticeChannel = AndroidNotificationChannel(
        'notice_channel',
        'নতুন নোটিশ',
        importance: Importance.high,
      );
      await androidPlugin?.createNotificationChannel(noticeChannel);
    }

    await _scheduleDefaultDailyReminders();
  }

  Future<void> _scheduleDefaultDailyReminders() async {
    const morningTime = TimeOfDay(hour: 9, minute: 0);
    const afternoonTime = TimeOfDay(hour: 15, minute: 0);
    const nightTime = TimeOfDay(hour: 21, minute: 0);

    await _scheduleDailyReminder(
      'morning',
      morningTime,
      getText('morning_reminder_title'),
      getText('morning_reminder_body'),
    );
    await _scheduleDailyReminder(
      'afternoon',
      afternoonTime,
      getText('evening_reminder_title'),
      getText('evening_reminder_body'),
    );
    await _scheduleDailyReminder(
      'night',
      nightTime,
      getText('night_reminder_title'),
      getText('night_reminder_body'),
    );
  }

  Future<void> _scheduleNotification(String title, DateTime dateTime, String id,
      {bool reschedule = false}) async {
    try {
      final notificationId = id.hashCode.abs() % 100000;
      if (reschedule) {
        await _notificationsPlugin.cancel(notificationId);
      }
      final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
      if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          _getFormattedAppTitle(),
          title,
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'r',
              'রিমাইন্ডার',
              importance: Importance.max,
              priority: Priority.high,
              actions: [
                AndroidNotificationAction('done', 'সম্পন্ন করুন'),
                AndroidNotificationAction('snooze', 'পিছিয়ে দিন'),
              ],
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              categoryIdentifier: 'reminder_category',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          payload: '$id|',
        );
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> _markReminderDone(String id) async {
    await LocalDatabaseService().updateReminderCompleted(id, true);
    _loadDataFromHive();
    _showSnackBar(getText('reminder_completed'), Colors.green);
  }

  Future<void> _refreshNotices() async {
    await _syncRemoteNotices();
    if (mounted) setState(() {});
    _showSnackBar(getText('notices_refreshed'), Colors.green);
  }

  void _showSnoozeDialog(String reminderId) {
    final reminder = _allReminders.firstWhere((r) => r['key'] == reminderId);
    final oldDate = DateFormat('dd/MM/yyyy').parse(reminder['date']);
    final oldTime = _parseTimeOfDay(reminder['time']);
    DateTime oldDateTime = DateTime(
        oldDate.year, oldDate.month, oldDate.day, oldTime.hour, oldTime.minute);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(getText('snooze')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              title: Text(getText('snooze_1h')),
              onTap: () {
                Navigator.pop(c);
                _rescheduleReminder(
                    reminderId, oldDateTime.add(const Duration(hours: 1)));
              }),
          ListTile(
              title: Text(getText('snooze_1d')),
              onTap: () {
                Navigator.pop(c);
                _rescheduleReminder(
                    reminderId, oldDateTime.add(const Duration(days: 1)));
              }),
          ListTile(
              title: Text(getText('snooze_1w')),
              onTap: () {
                Navigator.pop(c);
                _rescheduleReminder(
                    reminderId, oldDateTime.add(const Duration(days: 7)));
              }),
        ]),
      ),
    );
  }

  Future<void> _rescheduleReminder(String id, DateTime newDateTime) async {
    final newDateStr = DateFormat('dd/MM/yyyy').format(newDateTime);
    final newTimeStr = DateFormat('h:mm a').format(newDateTime);
    await LocalDatabaseService().updateReminder(id, null, newDateStr, newTimeStr);
    await _scheduleNotification(
        _allReminders.firstWhere((r) => r['key'] == id)['note'],
        newDateTime,
        id,
        reschedule: true);
    _loadDataFromHive();
    _showSnackBar(getText('reminder_updated'), Colors.orange);
  }

  String _formatTime12Hour(TimeOfDay time, BuildContext context) {
    final now = DateTime(2020, 1, 1, time.hour, time.minute);
    String formatted = DateFormat('h:mm a', 'en_US').format(now);

    if (_selectedLanguage == 'bn') {
      String toBanglaNum(String input) {
        const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
        const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
        for (int i = 0; i < en.length; i++) {
          input = input.replaceAll(en[i], bn[i]);
        }
        return input;
      }

      final parts = formatted.split(' ');
      if (parts.length == 2) {
        final timePart = toBanglaNum(parts[0]);
        return '$timePart ${parts[1]}';
      }
      return formatted;
    }

    return formatted;
  }

  void _editReminder(String id, String oldNote, String oldDate, String oldTime) {
    final titleCtrl = TextEditingController(text: oldNote);
    DateTime selDate = DateFormat('dd/MM/yyyy').parse(oldDate);
    TimeOfDay selTime = _parseTimeOfDay(oldTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(c).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  getText('edit_reminder'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: getText('title'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: c,
                      initialDate: selDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Localizations.override(
                          context: context,
                          locale: Locale(_selectedLanguage),
                          child: child!,
                        );
                      },
                    );
                    if (p != null) s(() => selDate = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 10),
                        Text(
                          '${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selDate)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final p = await _show12HourTimePicker(c, initialTime: selTime);
                    if (p != null) s(() => selTime = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 10),
                        Text('${getText('time')}: ${_formatTime12Hour(selTime, c)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty) {
                      final newDate = DateFormat('dd/MM/yyyy').format(selDate);
                      final newTime = _formatTime12Hour(selTime, c);

                      await LocalDatabaseService().updateReminder(
                        id,
                        titleCtrl.text,
                        newDate,
                        newTime,
                      );
                      final newDateTime = DateTime(
                        selDate.year,
                        selDate.month,
                        selDate.day,
                        selTime.hour,
                        selTime.minute,
                      );
                      await _scheduleNotification(
                        titleCtrl.text,
                        newDateTime,
                        id,
                        reschedule: true,
                      );
                      Navigator.pop(c);
                      _showSnackBar(getText('reminder_updated'), Colors.green);
                      _loadDataFromHive();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(getText('save')),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReminderInput() {
    final titleCtrl = TextEditingController();
    DateTime selDate = _selectedDay ?? DateTime.now();
    TimeOfDay selTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(c).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  getText('add_reminder'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: getText('title'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: c,
                      initialDate: selDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Localizations.override(
                          context: context,
                          locale: Locale(_selectedLanguage),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) s(() => selDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 10),
                        Text(
                          '${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selDate)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await _show12HourTimePicker(c, initialTime: selTime);
                    if (picked != null) s(() => selTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 10),
                        Text('${getText('time')}: ${_formatTime12Hour(selTime, c)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      final rId = DateTime.now().millisecondsSinceEpoch.toString();
                      final timeStr = _formatTime12Hour(selTime, c);

                      final reminderTx = TransactionModel(
                        id: rId,
                        amount: 0,
                        note: titleCtrl.text,
                        type: 'Reminder',
                        date: DateFormat('dd/MM/yyyy').format(selDate),
                        category: '',
                        isArchived: false,
                        time: timeStr,
                      );
                      LocalDatabaseService().addTransaction(reminderTx);
                      LocalDatabaseService().updateReminderCompleted(rId, false);
                      final reminderDateTime = DateTime(
                        selDate.year,
                        selDate.month,
                        selDate.day,
                        selTime.hour,
                        selTime.minute,
                      );
                      _scheduleNotification(titleCtrl.text, reminderDateTime, rId);
                      Navigator.pop(c);
                      _showSnackBar(getText('notification_scheduled'), Colors.green);
                      _loadDataFromHive();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    getText('save'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDebtCreditDialog(String type) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final reminderCommentCtrl = TextEditingController();

    DateTime selectedTxDate;
    if (type == 'দেনা') {
      selectedTxDate = _lastDebtDate ?? DateTime.now();
    } else {
      selectedTxDate = _lastCreditDate ?? DateTime.now();
    }

    String title = type == 'দেনা'
        ? getText('debt')
        : (type == 'পাওনা' ? getText('credit') : getText('savings'));
    String engType = type == 'দেনা'
        ? 'Debt'
        : (type == 'পাওনা' ? 'Credit' : 'Savings');
    Color color = type == 'দেনা'
        ? Colors.orange
        : (type == 'পাওনা' ? Colors.purple : Colors.blue);
    bool addReminder = false;
    DateTime? reminderDate;
    TimeOfDay? reminderTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(c).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: c,
                      initialDate: selectedTxDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Localizations.override(
                          context: context,
                          locale: Locale(_selectedLanguage),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      s(() => selectedTxDate = picked);
                      if (type == 'দেনা') {
                        _lastDebtDate = picked;
                      } else {
                        _lastCreditDate = picked;
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selectedTxDate)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9০-৯٠-٩]+\.?[0-9০-৯٠-٩]*'),
                    ),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      String converted = _convertToScriptDigits(newValue.text);
                      return newValue.copyWith(
                        text: converted,
                        selection: TextSelection.collapsed(offset: converted.length),
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    labelText: getText('amount'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.money),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: getText('description'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: Text(getText('add_reminder')),
                  value: addReminder,
                  onChanged: (val) => s(() => addReminder = val!),
                  activeColor: Colors.blue,
                  contentPadding: EdgeInsets.zero,
                ),
                if (addReminder) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(getText('date')),
                          subtitle: Text(
                            reminderDate == null
                                ? (_selectedLanguage == 'en'
                                ? 'Select date'
                                : (_selectedLanguage == 'ar' ? 'اختر التاريخ' : 'নির্বাচন করুন'))
                                : DateFormat('dd/MM/yyyy').format(reminderDate!),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: c,
                              initialDate: reminderDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Localizations.override(
                                  context: context,
                                  locale: Locale(_selectedLanguage),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) s(() => reminderDate = picked);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(getText('time')),
                          subtitle: Text(
                            reminderTime == null
                                ? (_selectedLanguage == 'en'
                                ? 'Select time'
                                : (_selectedLanguage == 'ar' ? 'اختر الوقت' : 'নির্বাচন করুন'))
                                : reminderTime!.format(c),
                          ),
                          onTap: () async {
                            final picked = await _show12HourTimePicker(c, initialTime: reminderTime ?? TimeOfDay.now());
                            if (picked != null) s(() => reminderTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reminderCommentCtrl,
                    decoration: InputDecoration(
                      labelText: getText('reminder_comment'),
                      hintText: getText('enter_comment'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (amtCtrl.text.trim().isEmpty) {
                      _showSnackBar(getText('amount_error'), Colors.red);
                      return;
                    }
                    final rawAmount = _convertToEnglishDigits(amtCtrl.text.trim());
                    final amt = double.tryParse(rawAmount);
                    if (amt == null) {
                      _showSnackBar(getText('amount_error'), Colors.red);
                      return;
                    }
                    final debtTx = TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: amt,
                      note: noteCtrl.text.trim().isEmpty ? title : noteCtrl.text,
                      type: engType,
                      date: DateFormat('dd/MM/yyyy hh:mm a').format(selectedTxDate),
                      category: "other",
                      isArchived: false,
                    );
                    await LocalDatabaseService().addTransaction(debtTx);
                    if (addReminder && reminderDate != null && reminderTime != null) {
                      final reminderDateTime = DateTime(
                        reminderDate!.year,
                        reminderDate!.month,
                        reminderDate!.day,
                        reminderTime!.hour,
                        reminderTime!.minute,
                      );
                      final reminderId = DateTime.now().millisecondsSinceEpoch.toString();
                      final reminderNote = reminderCommentCtrl.text.trim().isNotEmpty
                          ? reminderCommentCtrl.text.trim()
                          : "${getText('reminder_debt_payment')}: ${noteCtrl.text}";
                      final reminderTx = TransactionModel(
                        id: reminderId,
                        amount: 0,
                        note: reminderNote,
                        type: 'Reminder',
                        date: DateFormat('dd/MM/yyyy').format(reminderDate!),
                        category: '',
                        isArchived: false,
                        time: _formatTime12Hour(reminderTime!, c),
                      );
                      await LocalDatabaseService().addTransaction(reminderTx);
                      await LocalDatabaseService().updateReminderCompleted(reminderId, false);
                      _scheduleNotification(reminderNote, reminderDateTime, reminderId);
                    }
                    Navigator.pop(c);
                    _showSnackBar('$title ${getText('save')}', color);
                    _loadDataFromHive();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    getText('save'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSavingsDialog() {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(c).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  getText('savings'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: c,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Localizations.override(
                          context: context,
                          locale: Locale(_selectedLanguage),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) s(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9০-৯٠-٩]+\.?[0-9০-৯٠-٩]*'),
                    ),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      String converted = _convertToScriptDigits(newValue.text);
                      return newValue.copyWith(
                        text: converted,
                        selection: TextSelection.collapsed(offset: converted.length),
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    labelText: getText('amount'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.money),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: getText('description'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      getText('savings_type'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            items: [
                              DropdownMenuItem(
                                value: 'cash',
                                child: Text(getText('cash')),
                              ),
                              DropdownMenuItem(
                                value: 'bank',
                                child: Text(getText('bank')),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) s(() => selectedType = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (amtCtrl.text.trim().isEmpty) {
                      _showSnackBar(getText('amount_error'), Colors.red);
                      return;
                    }
                    final rawAmount = _convertToEnglishDigits(amtCtrl.text.trim());
                    final amt = double.tryParse(rawAmount);
                    if (amt == null) {
                      _showSnackBar(getText('amount_error'), Colors.red);
                      return;
                    }
                    String finalNote = noteCtrl.text.trim().isEmpty
                        ? getText('savings')
                        : noteCtrl.text;
                    finalNote +=
                    ' [${selectedType == 'cash' ? getText('cash') : getText('bank')}]';
                    final savingsTx = TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: amt,
                      note: finalNote,
                      type: 'Savings',
                      date: DateFormat('dd/MM/yyyy hh:mm a').format(selectedDate),
                      category: selectedType == 'cash' ? 'cash_savings' : 'bank_savings',
                      isArchived: false,
                    );
                    LocalDatabaseService().addTransaction(savingsTx);
                    Navigator.pop(c);
                    _showSnackBar('${getText('savings')} ${getText('save')}', Colors.blue);
                    _loadDataFromHive();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    getText('save'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIncomeDialog() {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selCat = 'salary';
    DateTime selectedDate = DateTime.now();

    final incomeKeys = incomeCategories.map((cat) => cat['key'] as String).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(c).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(getText('add_income'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: c,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Localizations.override(context: context, locale: Locale(_selectedLanguage), child: child!),
                    );
                    if (picked != null) s(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 10),
                        Text('${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯٠-٩]+\.?[0-9০-৯٠-٩]*')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      String converted = _convertToScriptDigits(newValue.text);
                      return newValue.copyWith(text: converted, selection: TextSelection.collapsed(offset: converted.length));
                    }),
                  ],
                  decoration: InputDecoration(labelText: getText('amount'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(labelText: getText('description'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.note)),
                ),
                const SizedBox(height: 12),
                Text(getText('select_category'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CategoryDropdown(
                  selectedValue: selCat,
                  onChanged: (newValue) => s(() => selCat = newValue),
                  hintText: getText('select_category'),
                  showAddNew: true,
                  allowedKeys: incomeKeys,
                  filterType: 'Income',
                  getTranslatedName: (key) => getCategoryName(key),
                  addNewCategoryText: getText('add_new_category'),
                  dialogTitle: getText('add_new_category_dialog_title'),
                  categoryNameLabel: getText('category_name'),
                  addButtonText: getText('add'),
                  cancelButtonText: getText('cancel'),
                  editCategoryText: getText('edit_category'),
                  deleteCategoryText: getText('delete_category'),
                  deleteConfirmText: getText('delete_category_confirm'),
                  categoryExistsText: getText('category_exists'),
                  addSuccessText: getText('category_added'),
                  deleteSuccessText: getText('category_deleted'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (amtCtrl.text.trim().isEmpty) {
                      _showSnackBar(getText('amount_error'), Colors.red);
                      return;
                    }
                    final rawAmount = _convertToEnglishDigits(amtCtrl.text.trim());
                    final amt = double.tryParse(rawAmount);
                    if (amt == null) {
                      _showSnackBar(getText('amount_error'), Colors.red);
                      return;
                    }
                    final tx = TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: amt,
                      note: noteCtrl.text.isEmpty ? getCategoryName(selCat) : noteCtrl.text,
                      type: 'Income',
                      date: DateFormat('dd/MM/yyyy hh:mm a').format(selectedDate),
                      category: selCat,
                      isArchived: false,
                    );
                    LocalDatabaseService().addTransaction(tx);
                    Navigator.pop(c);
                    _showSnackBar('${getText('income')} ${getText('save')}', Colors.green);
                    _loadDataFromHive();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(getText('save'), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExpenseDialog() {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selCat = 'gas_bill';
    DateTime selectedDate = DateTime.now();

    final expenseKeys = expenseCategories.map((cat) => cat['key'] as String).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(getText('add_expense'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: c,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Localizations.override(context: context, locale: Locale(_selectedLanguage), child: child!),
                    );
                    if (picked != null) s(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 10),
                        Text('${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯٠-٩]+\.?[0-9০-৯٠-٩]*')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      String converted = _convertToScriptDigits(newValue.text);
                      return newValue.copyWith(text: converted, selection: TextSelection.collapsed(offset: converted.length));
                    }),
                  ],
                  decoration: InputDecoration(labelText: getText('amount'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(labelText: getText('description'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.note)),
                ),
                const SizedBox(height: 12),
                Text(getText('select_category'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CategoryDropdown(
                  selectedValue: selCat,
                  onChanged: (newValue) => s(() => selCat = newValue),
                  hintText: getText('select_category'),
                  showAddNew: true,
                  allowedKeys: expenseKeys,
                  filterType: 'Expense',
                  getTranslatedName: (key) => getCategoryName(key),
                  addNewCategoryText: getText('add_new_category'),
                  dialogTitle: getText('add_new_category_dialog_title'),
                  categoryNameLabel: getText('category_name'),
                  addButtonText: getText('add'),
                  cancelButtonText: getText('cancel'),
                  editCategoryText: getText('edit_category'),
                  deleteCategoryText: getText('delete_category'),
                  deleteConfirmText: getText('delete_category_confirm'),
                  categoryExistsText: getText('category_exists'),
                  addSuccessText: getText('category_added'),
                  deleteSuccessText: getText('category_deleted'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (amtCtrl.text.trim().isEmpty) {
                      _showSnackBar(getText('amount_error'), Colors.red);
                      return;
                    }
                    final rawAmount = _convertToEnglishDigits(amtCtrl.text.trim());
                    final amt = double.tryParse(rawAmount);
                    if (amt == null) {
                      _showSnackBar(getText('amount_error'), Colors.red);
                      return;
                    }
                    final tx = TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: amt,
                      note: noteCtrl.text.isEmpty ? getCategoryName(selCat) : noteCtrl.text,
                      type: 'Expense',
                      date: DateFormat('dd/MM/yyyy hh:mm a').format(selectedDate),
                      category: selCat,
                      isArchived: false,
                    );
                    LocalDatabaseService().addTransaction(tx);
                    Navigator.pop(c);
                    _showSnackBar('${getText('expense')} ${getText('save')}', Colors.red);
                    _loadDataFromHive();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(getText('save'), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating));
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(getText('delete')),
        content: Text(getText('delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(getText('no'))),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(c);
                await LocalDatabaseService().deleteTransaction(id);
                _loadDataFromHive();
                _showSnackBar(getText('delete'), Colors.red);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(getText('yes'),
                  style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _confirmArchive(String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(getText('archive')),
        content: const Text("আর্কাইভ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(getText('no'))),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(c);
                await LocalDatabaseService().archiveTransaction(id, true);
                _loadDataFromHive();
                _showSnackBar(getText('archive'), Colors.orange);
              },
              child: Text(getText('yes'))),
        ],
      ),
    );
  }

  void _showTransactionOptions(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
              leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(Icons.edit, color: Colors.blue)),
              title: Text(getText('edit'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(c);
                _showEditDialog(tx);
              }),
          ListTile(
              leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: Icon(Icons.archive, color: Colors.orange)),
              title: Text(getText('archive'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(c);
                _confirmArchive(tx['key']);
              }),
          ListTile(
              leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: Icon(Icons.delete, color: Colors.red)),
              title: Text(getText('delete'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(c);
                _confirmDelete(tx['key']);
              }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> tx) {
    final amtCtrl = TextEditingController(text: (tx['amount'] ?? '').toString());
    final noteCtrl = TextEditingController(text: tx['note'] ?? '');
    String type = tx['type'] ?? 'Income';
    String catKey = tx['category'] ?? (type == 'Income' ? 'salary' : 'gas_bill');

    List<String> allowedKeys;
    if (type == 'Income') {
      allowedKeys = incomeCategories.map((cat) => cat['key'] as String).toList();
    } else {
      allowedKeys = expenseCategories.map((cat) => cat['key'] as String).toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(getText('edit'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: getText('amount'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(labelText: getText('description'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.note)),
                ),
                const SizedBox(height: 12),
                Text(getText('select_category'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CategoryDropdown(
                  selectedValue: catKey,
                  onChanged: (newValue) => s(() => catKey = newValue),
                  hintText: getText('select_category'),
                  showAddNew: true,
                  allowedKeys: allowedKeys,
                  filterType: type,
                  getTranslatedName: (key) => getCategoryName(key),
                  addNewCategoryText: getText('add_new_category'),
                  dialogTitle: getText('add_new_category_dialog_title'),
                  categoryNameLabel: getText('category_name'),
                  addButtonText: getText('add'),
                  cancelButtonText: getText('cancel'),
                  editCategoryText: getText('edit_category'),
                  deleteCategoryText: getText('delete_category'),
                  deleteConfirmText: getText('delete_category_confirm'),
                  categoryExistsText: getText('category_exists'),
                  addSuccessText: getText('category_added'),
                  deleteSuccessText: getText('category_deleted'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (amtCtrl.text.isNotEmpty) {
                      final amt = double.tryParse(amtCtrl.text);
                      if (amt != null) {
                        LocalDatabaseService().updateTransaction(tx['key'], {
                          'amount': amt,
                          'note': noteCtrl.text.isEmpty ? getCategoryName(catKey) : noteCtrl.text,
                          'category': catKey,
                        });
                        Navigator.pop(c);
                        _showSnackBar('${getText('edit')} ${getText('save')}', Colors.green);
                        _loadDataFromHive();
                      }
                    } else {
                      _showSnackBar(getText('amount_error'), Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(getText('save'), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSecurityScreen() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SecurityScreen(
                selectedLanguage: _selectedLanguage,
                localizedText: _localizedText)));
  }

  // CALCULATOR
  void _openCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => Container(
          height: MediaQuery.of(c).size.height * 0.65,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: Text(_display, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w500)))),
                  IconButton(icon: const Icon(Icons.backspace, size: 28), onPressed: () => _onKeyPress("DEL", s)),
                ]),
              ),
              Expanded(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
                _buildCalcRow(["C", "±", "%", "÷"], s),
                _buildCalcRow(["7", "8", "9", "×"], s),
                _buildCalcRow(["4", "5", "6", "-"], s),
                _buildCalcRow(["1", "2", "3", "+"], s),
                _buildCalcRow(["0", ".", "="], s),
              ]))),
              Padding(padding: const EdgeInsets.all(10), child: SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(c), style: TextButton.styleFrom(backgroundColor: Colors.grey[200], padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text(getText('cancel'), style: const TextStyle(fontSize: 16))))),
            ],
          ),
        ),
      ),
    );
  }

  void _onKeyPress(String v, StateSetter s) {
    s(() {
      if (v == "C") { _display = "0"; _firstValue = null; _operator = null; _shouldResetDisplay = false; _isNewNumber = true; }
      else if (v == "DEL") { _display = _display.length > 1 ? _display.substring(0, _display.length - 1) : "0"; _isNewNumber = _display == "0"; }
      else if (v == "+" || v == "-" || v == "×" || v == "÷") { if (_operator != null && !_isNewNumber) _calculate(); _firstValue = double.tryParse(_display); _operator = v; _shouldResetDisplay = true; _isNewNumber = true; }
      else if (v == "=") { _calculate(); _operator = null; _firstValue = null; _shouldResetDisplay = true; _isNewNumber = true; }
      else if (v == "±") { if (_display != "0") _display = _display.startsWith("-") ? _display.substring(1) : "-$_display"; }
      else if (v == ".") { if (!_display.contains(".")) { _display += "."; _isNewNumber = false; } }
      else { if (_shouldResetDisplay || _display == "0" || _isNewNumber) { _display = v; _shouldResetDisplay = false; _isNewNumber = false; } else { _display += v; } }
    });
  }

  void _calculate() {
    if (_firstValue != null && _operator != null) {
      double sv = double.tryParse(_display) ?? 0, r = 0;
      switch (_operator) { case "+": r = _firstValue! + sv; break; case "-": r = _firstValue! - sv; break; case "×": r = _firstValue! * sv; break; case "÷": r = sv != 0 ? _firstValue! / sv : 0; break; }
      _display = r % 1 == 0 ? r.toInt().toString() : r.toStringAsFixed(2);
      _firstValue = r; _shouldResetDisplay = true;
    }
  }

  Widget _buildCalcRow(List<String> k, StateSetter s) => Expanded(child: Row(children: k.map((x) => Expanded(child: _buildCalcButton(x, s))).toList()));
  Widget _buildCalcButton(String t, StateSetter s) {
    Color bg = Colors.grey[100]!, tc = Colors.black87;
    if (t == "C") { bg = Colors.red[400]!; tc = Colors.white; }
    else if (t == "÷" || t == "×" || t == "-" || t == "+" || t == "=") { bg = Colors.blue.shade700; tc = Colors.white; }
    return Padding(padding: const EdgeInsets.all(4), child: Material(color: bg, borderRadius: BorderRadius.circular(12), child: InkWell(onTap: () => _onKeyPress(t, s), borderRadius: BorderRadius.circular(12), child: Container(height: double.infinity, alignment: Alignment.center, child: Text(t, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: tc))))));
  }

  // ========== DAILY REMINDER ==========
  Future<void> _scheduleDailyReminder(String id, TimeOfDay time, String title, String body) async {
    try {
      final notificationId = id.hashCode.abs() % 100000;
      await _notificationsPlugin.cancel(notificationId);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'দৈনিক রিমাইন্ডার',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: id,
      );
      print('Scheduled $id at ${scheduledDate.toLocal()}');
    } catch (e) {
      print('Error scheduling daily reminder ($id): $e');
    }
  }

  Future<void> _loadDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('daily_reminder_hour');
    final minute = prefs.getInt('daily_reminder_minute');
    if (hour != null && minute != null) {
      await _scheduleDailyReminder(
        'user_daily',
        TimeOfDay(hour: hour, minute: minute),
        getText('daily_reminder_title'),
        getText('daily_reminder_body'),
      );
    }
  }

  Future<void> _showDailyReminderPicker() async {
    final prefs = await SharedPreferences.getInstance();
    final currentHour = prefs.getInt('daily_reminder_hour') ?? 9;
    final currentMinute = prefs.getInt('daily_reminder_minute') ?? 0;

    final time = await _show12HourTimePicker(
      context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );

    if (time != null) {
      await _scheduleDailyReminder(
        'user_daily',
        time,
        getText('daily_reminder_title'),
        getText('daily_reminder_body'),
      );
      await prefs.setInt('daily_reminder_hour', time.hour);
      await prefs.setInt('daily_reminder_minute', time.minute);
      _showSnackBar(getText('reminder_set'), Colors.green);
    }
  }

  // ========== REMOTE NOTICES ==========
  Future<List<RemoteNotice>> _fetchRemoteNotices() async {
    const String noticesUrl = 'https://raw.githubusercontent.com/mizanuruplink-design/Amar_Hisab/main/notices.json';
    try {
      final response = await http.get(Uri.parse(noticesUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => RemoteNotice.fromJson(j)).toList();
      } else {
        print('Failed to fetch notices: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching remote notices: $e');
    }
    return [];
  }

  Future<void> _syncRemoteNotices() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getString('last_notice_fetch') ?? '2000-01-01T00:00:00Z';
    final lastFetchDate = DateTime.parse(lastFetch);

    final allNotices = await _fetchRemoteNotices();
    if (allNotices.isEmpty) return;

    final List<String> storedJson = prefs.getStringList('all_notices') ?? [];
    List<RemoteNotice> existingNotices = storedJson
        .map((s) => RemoteNotice.fromJson(jsonDecode(s)))
        .toList();

    bool isSameDate(DateTime d1, DateTime d2) {
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    }

    bool hasNew = false;
    for (var newNotice in allNotices) {
      if (!existingNotices.any((e) =>
      e.title == newNotice.title && isSameDate(e.date, newNotice.date))) {
        existingNotices.add(newNotice);
        await _showNoticeNotification(newNotice.title, newNotice.body);
        hasNew = true;
      }
    }

    final updatedJson = existingNotices.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList('all_notices', updatedJson);
    await prefs.setString('last_notice_fetch', DateTime.now().toIso8601String());

    _remoteNotices = existingNotices;
    if (mounted) setState(() {});
  }

  Future<void> _showNoticeNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'notice_channel',
      'নতুন নোটিশ',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '${_getFormattedAppTitle()} • $title',
      body,
      details,
    );
  }

  Future<void> _loadRemoteNotices() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('all_notices');
    if (stored != null) {
      _remoteNotices = stored
          .map((s) => RemoteNotice.fromJson(jsonDecode(s)))
          .toList();
      setState(() {});
    }
  }

  // ========== PROFILE & SETTINGS ==========
  void _showProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _changeProfilePhoto(),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: _profileImagePath != null &&
                            File(_profileImagePath!).existsSync()
                            ? FileImage(File(_profileImagePath!))
                            : null,
                        child: (_profileImagePath == null)
                            ? const Icon(Icons.person, size: 50, color: Colors.blue)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: (_profileImagePath != null &&
                          File(_profileImagePath!).existsSync())
                          ? 60
                          : 0,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                    if (_profileImagePath != null &&
                        File(_profileImagePath!).existsSync())
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('profileImagePath');
                            setState(() => _profileImagePath = null);
                            s(() => _profileImagePath = null);
                            _showSnackBar("প্রোফাইল পিকচার রিমুভ করা হয়েছে", Colors.red);
                          },
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.delete, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: getText('user_name'),
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) {
                      _userName = v;
                      s(() {});
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _userName.isNotEmpty ? _userName : getText('default_user'),
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildSettingsCard(s),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(c);
                          _openSecurityScreen();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade700],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.security, color: Colors.white, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                getText('security_settings'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          _userName = nameCtrl.text.trim();
                          await _saveUserSettings();
                          setState(() {});
                          Navigator.pop(c);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          getText('save'),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              getText('change_photo'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildPhotoOption(
              icon: Icons.camera_alt,
              label: getText('take_photo'),
              color: Colors.blue,
              onTap: () async {
                Navigator.pop(c);
                final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                if (picked != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('profileImagePath', picked.path);
                  setState(() => _profileImagePath = picked.path);
                }
              },
            ),
            _buildPhotoOption(
              icon: Icons.photo_library,
              label: getText('choose_gallery'),
              color: Colors.green,
              onTap: () async {
                Navigator.pop(c);
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('profileImagePath', picked.path);
                  setState(() => _profileImagePath = picked.path);
                }
              },
            ),
            if (_profileImagePath != null && File(_profileImagePath!).existsSync())
              _buildPhotoOption(
                icon: Icons.delete_forever,
                label: getText('remove_photo'),
                color: Colors.red,
                onTap: () async {
                  Navigator.pop(c);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('profileImagePath');
                  setState(() => _profileImagePath = null);
                  _showSnackBar(getText('profile_pic_removed'), Colors.red);
                },
              ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: Text(
                getText('cancel'),
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () => Navigator.pop(c),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSettingsCard(StateSetter s) {
    return Container(
      decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: _isDarkMode ? Colors.grey[700]! : Colors.grey[200]!)),
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.brightness_6, size: 20, color: Colors.purple),
          const SizedBox(width: 10),
          Text(getText('dark_mode'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
        ]),
        SwitchListTile(
            value: _isDarkMode,
            onChanged: (v) => s(() => _isDarkMode = v),
            activeColor: Colors.purple,
            dense: true,
            contentPadding: EdgeInsets.zero),
        const Divider(),
        Row(children: [
          Icon(Icons.language, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Text(getText('language'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _lc('বাংলা', 'bn', s),
          const SizedBox(width: 8),
          _lc('English', 'en', s),
          const SizedBox(width: 8),
          _lc('العربية', 'ar', s)
        ]),
        const SizedBox(height: 15),
        Row(children: [
          Icon(Icons.currency_exchange, size: 20, color: Colors.green),
          const SizedBox(width: 10),
          Text(getText('currency'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          _cc('BDT', '৳', s),
          _cc('USD', '\$', s),
          _cc('EUR', '€', s),
          _cc('GBP', '£', s),
          _cc('INR', '₹', s)
        ]),
        const SizedBox(height: 15),
        Row(children: [
          Icon(Icons.calendar_today, size: 20, color: Colors.orange),
          const SizedBox(width: 10),
          Text(getText('calendar_settings'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
        ]),
        SwitchListTile(
            title: Text(getText('show_hijri')),
            value: _showHijriDate,
            onChanged: (v) => s(() => _showHijriDate = v),
            activeColor: Colors.blue.shade700,
            dense: true,
            contentPadding: EdgeInsets.zero),
        SwitchListTile(
            title: Text(getText('show_bengali')),
            value: _showBengaliDate,
            onChanged: (v) => s(() => _showBengaliDate = v),
            activeColor: Colors.blue.shade700,
            dense: true,
            contentPadding: EdgeInsets.zero),
      ]),
    );
  }

  Widget _lc(String l, String code, StateSetter s) {
    bool sel = _selectedLanguage == code;
    return Expanded(
      child: InkWell(
        onTap: () async {
          if (code != _selectedLanguage) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(getText('translating')),
                  ],
                ),
              ),
            );
            s(() => _selectedLanguage = code);
            await _saveUserSettings();
            await _translateAllUserData(code);
            await _loadDataFromHive();
            Navigator.of(context).pop();
            setState(() {});
          } else {
            s(() => _selectedLanguage = code);
            await _saveUserSettings();
            setState(() {});
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel
                ? Colors.blue.shade700
                : (_isDarkMode ? Colors.grey[800] : Colors.white),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: sel
                  ? Colors.blue.shade700
                  : (_isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
            ),
          ),
          child: Center(
            child: Text(
              l,
              style: TextStyle(
                color: sel
                    ? Colors.white
                    : (_isDarkMode ? Colors.white : Colors.black87),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cc(String code, String sym, StateSetter s) {
    bool sel = _selectedCurrency == code;
    return InkWell(
        onTap: () => s(() => _selectedCurrency = code),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: sel
                    ? Colors.blue.shade700
                    : (_isDarkMode ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                    color: sel
                        ? Colors.blue.shade700
                        : (_isDarkMode ? Colors.grey[700]! : Colors.grey[300]!))),
            child: Text('$code ($sym)',
                style: TextStyle(
                    color: sel
                        ? Colors.white
                        : (_isDarkMode ? Colors.white : Colors.black87)))));
  }

  void _changeProfilePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', picked.path);
      setState(() => _profileImagePath = picked.path);
    }
  }

  // ==================== BACKUP / RESTORE (FIXED) ====================
  Future<Directory> _getBackupFolder() async {
    Directory backupDir;

    if (Platform.isAndroid) {
      // Public Documents folder — one predictable path, no nested Android/data/... paths
      backupDir = Directory('/storage/emulated/0/Documents/Amar_Hisab_Backups');
    } else {
      // iOS: app's Documents dir (shows in Files app if file sharing is enabled)
      final appDocDir = await getApplicationDocumentsDirectory();
      backupDir = Directory('${appDocDir.path}/Amar_Hisab_Backups');
    }

    try {
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir;
    } catch (e) {
      // Fallback only if the public path can't be written to (e.g. missing permission)
      print('Could not access $backupDir: $e');
      final appDocDir = await getApplicationDocumentsDirectory();
      final fallback = Directory('${appDocDir.path}/Amar_Hisab_Backups');
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      return fallback;
    }
  }

  Future<void> _cleanOldBackups(Directory backupDir, {int keepCount = 5}) async {
    try {
      final files = await backupDir.list()
          .where((entity) => entity is File)
          .map((entity) => entity as File)
          .toList();

      if (files.length <= keepCount) return;

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      for (var i = keepCount; i < files.length; i++) {
        await files[i].delete();
      }
    } catch (e) {
      print('Error cleaning old backups: $e');
    }
  }

  Future<String?> _createLocalBackup({bool silent = false}) async {
    try {
      final txBox = Hive.box<TransactionModel>('transactions');
      final budgetBox = Hive.box<BudgetModel>('budgets');
      final recurringBox = Hive.box<RecurringTransactionModel>('recurring');

      final backupData = {
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': txBox.values.map(_transactionToJson).toList(),
        'budgets': budgetBox.values.map(_budgetToJson).toList(),
        'recurring': recurringBox.values.map(_recurringToJson).toList(),
        'settings': {
          'language': _selectedLanguage,
          'darkMode': _isDarkMode,
          'userName': _userName,
          'profileImagePath': _profileImagePath,
          'currency': _selectedCurrency,
          'showHijriDate': _showHijriDate,
          'showBengaliDate': _showBengaliDate,
        },
      };

      final jsonString = jsonEncode(backupData);
      final fileName = 'backup_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.json';

      final backupDir = await _getBackupFolder();
      final file = File('${backupDir.path}/$fileName');
      await file.writeAsString(jsonString);

      await _cleanOldBackups(backupDir, keepCount: 5);

      return file.path;
    } catch (e) {
      if (!silent) _showSnackBar('${getText('backup')} ${getText('failed')}: $e', Colors.red);
      return null;
    }
  }

  Future<void> _openBackupFolder() async {
    final backupDir = await _getBackupFolder();
    final files = await backupDir.list()
        .where((entity) => entity is File)
        .map((entity) => entity as File)
        .toList();

    if (files.isNotEmpty) {
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latestFile = files.first.path;
      final result = await OpenFile.open(latestFile);
      if (result.type != ResultType.done) {
        _showFolderPathDialog(backupDir.path);
      }
    } else {
      _showFolderPathDialog(backupDir.path);
    }
  }

  void _showFolderPathDialog(String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(getText('backup_location')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backup files are stored at:'),
            const SizedBox(height: 8),
            SelectableText(path, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('(You can copy this path and paste it in your file manager.)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _copyToClipboard(path);
            },
            child: const Text('Copy Path'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(getText('close')),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Path copied to clipboard', Colors.green);
  }

  Widget _buildBackupSuccessDialog(String filePath) {
    final folderPath = filePath.substring(0, filePath.lastIndexOf('/'));
    final fileName = filePath.split('/').last;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green, Colors.teal],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              getText('backup_success'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    getText('backup_location'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📂 $fileName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    folderPath,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(getText('close')),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openBackupFolder();
                  },
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Open File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Share.shareXFiles(
                      [XFile(filePath)],
                      text: getText('backup_share_message'),
                    );
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(getText('share')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _copyToClipboard(folderPath);
              },
              child: Text(
                'Copy Path',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupLoadingDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isDarkMode ? Colors.grey.shade800 : Colors.white,
              _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.backup,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              getText('saving'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 12),
            Text(
              getText('please_wait'),
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreLoadingDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isDarkMode ? Colors.grey.shade800 : Colors.white,
              _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.red],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restore,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              getText('restore'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 12),
            Text(
              getText('please_wait'),
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade400,
              Colors.teal.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restore,
                      color: Colors.green,
                      size: 56,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              getText('restore'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              getText('restore_success'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(getText('ok')),
            ),
          ],
        ),
      ),
    );
  }

  // ========== BACKUP TO GOOGLE DRIVE ==========
  Future<void> _backupToGoogleDrive() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'https://www.googleapis.com/auth/drive.file',
        ],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _showSnackBar(getText('sign_in_google'), Colors.orange);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken!;

      final filePath = await _createLocalBackup();
      if (filePath == null) return;

      final file = File(filePath);
      final fileName = file.path.split('/').last;
      final fileContent = await file.readAsString();

      final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $accessToken';

      final metadata = {'name': fileName};
      request.files.add(http.MultipartFile.fromString(
        'metadata',
        jsonEncode(metadata),
        contentType: MediaType('application', 'json'),
      ));

      request.files.add(http.MultipartFile.fromString(
        'file',
        fileContent,
        filename: fileName,
        contentType: MediaType('application', 'json'),
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        _showSnackBar(getText('google_drive_backup'), Colors.green);
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Google Drive upload error: ${response.statusCode} - $errorBody');
        _showSnackBar('${getText('google_drive_backup')} ${getText('failed')}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('${getText('google_drive_backup')} ${getText('failed')}: $e', Colors.red);
    }
  }

  Future<void> _backupData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildBackupLoadingDialog(),
    );

    final filePath = await _createLocalBackup(silent: false);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (filePath != null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _buildBackupSuccessDialog(filePath),
      );
    }
  }

  Future<void> _restoreData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                getText('restore'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            getText('restore_confirmation'),
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(getText('no')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(getText('yes')),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildRestoreLoadingDialog(),
      );

      await Hive.box<TransactionModel>('transactions').clear();
      await Hive.box<BudgetModel>('budgets').clear();
      await Hive.box<RecurringTransactionModel>('recurring').clear();

      for (var txMap in data['transactions']) {
        final tx = TransactionModel(
          id: txMap['id'],
          amount: (txMap['amount'] as num).toDouble(),
          type: txMap['type'],
          category: txMap['category'],
          date: txMap['date'],
          note: txMap['note'],
          refundDate: txMap['refundDate'],
          isPaid: txMap['isPaid'] ?? false,
          isArchived: txMap['isArchived'] ?? false,
          time: txMap['time'],
        );
        await Hive.box<TransactionModel>('transactions').put(tx.id, tx);
      }

      for (var bMap in data['budgets']) {
        final budget = BudgetModel(
          id: bMap['id'],
          category: bMap['category'],
          budgetAmount: (bMap['budgetAmount'] as num).toDouble(),
          spentAmount: (bMap['spentAmount'] as num).toDouble(),
          period: bMap['period'],
          month: bMap['month'],
          isActive: bMap['isActive'] ?? true,
        );
        await Hive.box<BudgetModel>('budgets').put(budget.id, budget);
      }

      for (var rMap in data['recurring']) {
        final recurring = RecurringTransactionModel(
          id: rMap['id'],
          note: rMap['note'],
          amount: (rMap['amount'] as num).toDouble(),
          type: rMap['type'],
          category: rMap['category'],
          frequency: rMap['frequency'],
          startDate: DateTime.parse(rMap['startDate']),
          endDate: rMap['endDate'] != null ? DateTime.parse(rMap['endDate']) : null,
          isActive: rMap['isActive'] ?? true,
          lastProcessed: rMap['lastProcessed'] != null
              ? DateTime.parse(rMap['lastProcessed'])
              : null,
          nextDueDate: DateTime.parse(rMap['nextDueDate']),
        );
        await Hive.box<RecurringTransactionModel>('recurring')
            .put(recurring.id, recurring);
      }

      final settings = data['settings'];
      if (settings != null) {
        final prefs = await SharedPreferences.getInstance();
        if (settings['language'] != null)
          await prefs.setString('language', settings['language']);
        if (settings['darkMode'] != null)
          await prefs.setBool('darkMode', settings['darkMode']);
        if (settings['userName'] != null)
          await prefs.setString('userName', settings['userName']);
        if (settings['profileImagePath'] != null && settings['profileImagePath'] != '')
          await prefs.setString('profileImagePath', settings['profileImagePath']);
        if (settings['currency'] != null)
          await prefs.setString('currency', settings['currency']);
        if (settings['showHijriDate'] != null) {
          _showHijriDate = settings['showHijriDate'];
          await prefs.setBool('showHijriDate', _showHijriDate);
        }
        if (settings['showBengaliDate'] != null) {
          _showBengaliDate = settings['showBengaliDate'];
          await prefs.setBool('showBengaliDate', _showBengaliDate);
        }
        _loadUserSettings();
      }

      _loadDataFromHive();

      if (mounted) Navigator.of(context).pop();

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _buildRestoreSuccessDialog(),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar('${getText('restore')} ${getText('failed')}: $e', Colors.red);
    }
  }

  Map<String, dynamic> _transactionToJson(TransactionModel tx) => {
    'id': tx.id,
    'amount': tx.amount,
    'type': tx.type,
    'category': tx.category,
    'date': tx.date,
    'note': tx.note,
    'refundDate': tx.refundDate,
    'isPaid': tx.isPaid,
    'isArchived': tx.isArchived,
    'time': tx.time,
  };

  Map<String, dynamic> _budgetToJson(BudgetModel b) => {
    'id': b.id,
    'category': b.category,
    'budgetAmount': b.budgetAmount,
    'spentAmount': b.spentAmount,
    'period': b.period,
    'month': b.month,
    'isActive': b.isActive,
  };

  Map<String, dynamic> _recurringToJson(RecurringTransactionModel r) => {
    'id': r.id,
    'note': r.note,
    'amount': r.amount,
    'type': r.type,
    'category': r.category,
    'frequency': r.frequency,
    'startDate': r.startDate.toIso8601String(),
    'endDate': r.endDate?.toIso8601String(),
    'isActive': r.isActive,
    'lastProcessed': r.lastProcessed?.toIso8601String(),
    'nextDueDate': r.nextDueDate.toIso8601String(),
  };

  // ========== Auto Backup on Internet ==========
  void _startAutoBackupListener() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      if (results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.mobile)) {
        print('Internet available – performing auto-backup and syncing remote notices');
        await _createLocalBackup(silent: true);
        await _syncRemoteNotices();
      }
    });
  }

  // ========== LOGOUT ==========
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    SystemNavigator.pop();
  }

  // ==================== NOTEBOOK ====================
  Widget _buildNotebookBody() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(getText('text_note')), icon: Icon(Icons.note)),
              ButtonSegment(value: 1, label: Text(getText('drawing')), icon: Icon(Icons.brush)),
            ],
            selected: {_notebookMode},
            onSelectionChanged: (Set<int> newSelection) => setState(() => _notebookMode = newSelection.first),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.blue.shade700 : Colors.grey.shade200),
              foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.white : Colors.black87),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: _notebookMode == 0 ? () => _openTextNoteEditor() : () => _openDrawingNotebook(),
            icon: const Icon(Icons.add_circle, size: 28),
            label: Text(_notebookMode == 0 ? getText('add_note') : getText('add_drawing')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Flexible(
          child: SingleChildScrollView(
            child: _notebookMode == 0
                ? (_textNotes.isEmpty ? Center(child: Text(getText('no_notes'))) : Column(children: _textNotes.map((note) => _buildTextNoteCard(note)).toList()))
                : (_drawingNotes.isEmpty ? Center(child: Text(getText('no_drawing'))) : Column(children: _drawingNotes.map((drawing) => _buildDrawingNoteCard(drawing)).toList())),
          ),
        ),
      ],
    );
  }

  Widget _buildTextNoteCard(Map<String, dynamic> note) {
    String extraRaw = note['category'] ?? '';
    int bgColorValue = Colors.yellow.shade100.value;
    List<String> imagePaths = [];
    try {
      if (extraRaw.startsWith('{')) {
        Map<String, dynamic> extra = json.decode(extraRaw);
        bgColorValue = (extra['bgColor'] as int?) ?? Colors.yellow.shade100.value;
        imagePaths = List<String>.from(extra['imagePaths'] ?? []);
      } else {
        bgColorValue = int.tryParse(extraRaw) ?? Colors.yellow.shade100.value;
      }
    } catch (_) {}
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Color(bgColorValue), borderRadius: BorderRadius.circular(20)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openTextNoteEditor(existingNote: note, key: note['key']),
          onLongPress: () => _confirmDelete(note['key']),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.note, size: 18, color: Colors.black45),
                    const Spacer(),
                    if (imagePaths.isNotEmpty) Icon(Icons.image, size: 18, color: Colors.black45),
                    const SizedBox(width: 8),
                    Text(note['date'] ?? "", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 15),
                Text(note['note'] ?? "", style: const TextStyle(fontSize: 16), maxLines: 10, overflow: TextOverflow.ellipsis),
                if (imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: imagePaths.map((path) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), height: 80, width: 80, fit: BoxFit.cover)),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingNoteCard(Map<String, dynamic> noteData) {
    String extraRaw = noteData['category']?.toString() ?? '';
    int bgColorValue = Colors.yellow.shade100.value;
    List<String> imagePaths = [];
    bool hasDrawing = false;
    try {
      if (extraRaw.startsWith('{')) {
        Map<String, dynamic> extra = json.decode(extraRaw);
        bgColorValue = (extra['bgColor'] as int?) ?? Colors.yellow.shade100.value;
        imagePaths = List<String>.from(extra['imagePaths'] ?? []);
        hasDrawing = extra['hasDrawing'] == true;
      } else {
        bgColorValue = int.tryParse(extraRaw) ?? Colors.yellow.shade100.value;
      }
    } catch (_) {}
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Color(bgColorValue), borderRadius: BorderRadius.circular(20)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDrawingNotebook(existingNote: noteData, key: noteData['key']),
          onLongPress: () => _confirmDelete(noteData['key']),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.push_pin, size: 18, color: Colors.black45)),
                    const Spacer(),
                    if (hasDrawing) Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.brush, size: 18, color: Colors.black45)),
                    if (imagePaths.isNotEmpty) Icon(Icons.image, size: 18, color: Colors.black45),
                    const SizedBox(width: 8),
                    Text(noteData['date'] ?? "", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 15),
                Text(noteData['note'] ?? "", style: const TextStyle(fontSize: 16), maxLines: 10, overflow: TextOverflow.ellipsis),
                if (imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: imagePaths.map((path) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), height: 80, width: 80, fit: BoxFit.cover)),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTextNoteEditor({Map<String, dynamic>? existingNote, String? key}) {
    if (_isNoteEditorOpen) return;
    setState(() => _isNoteEditorOpen = true);
    final TextEditingController tc = TextEditingController(text: existingNote?['note'] ?? "");
    List<Color> bgs = [Colors.yellow.shade100, Colors.green.shade100, Colors.blue.shade100, Colors.pink.shade100, Colors.purple.shade100, Colors.orange.shade100];
    int selectedBg = Colors.yellow.shade100.value;
    List<String> existingImages = [];
    if (existingNote != null) {
      String extraRaw = existingNote['category'] ?? '';
      try {
        if (extraRaw.startsWith('{')) {
          Map<String, dynamic> extra = json.decode(extraRaw);
          selectedBg = (extra['bgColor'] as int?) ?? Colors.yellow.shade100.value;
          existingImages = List<String>.from(extra['imagePaths'] ?? []);
        } else {
          selectedBg = int.tryParse(extraRaw) ?? Colors.yellow.shade100.value;
        }
      } catch (_) {}
    }
    Color selBg = Color(selectedBg);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, s) => Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: selBg,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 40, left: 8, right: 8, bottom: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green, size: 32),
                        onPressed: () async {
                          if (tc.text.trim().isEmpty) {
                            _showSnackBar(getText('write_note_hint'), Colors.red);
                            return;
                          }
                          Map<String, dynamic> extra = {
                            'bgColor': selBg.value,
                            'imagePaths': existingImages,
                            'hasDrawing': false,
                          };
                          final newNote = TransactionModel(
                            id: key ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            amount: 0,
                            note: tc.text,
                            type: "Note",
                            category: json.encode(extra),
                            date: DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()),
                            isArchived: false,
                          );
                          _isNoteEditorOpen = false;
                          Navigator.of(context).pop();
                          await LocalDatabaseService().addTransaction(newNote);
                          final newNoteMap = {
                            'key': newNote.id,
                            'note': newNote.note,
                            'date': newNote.date,
                            'category': newNote.category,
                          };
                          if (mounted) {
                            setState(() {
                              if (key != null) {
                                _textNotes.removeWhere((note) => note['key'] == key);
                              }
                              _textNotes.insert(0, newNoteMap);
                            });
                          }
                          _showSnackBar(getText('save'), Colors.green);
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getText('editing'),
                              style: const TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                            Text(
                              DateFormat('dd/MM/yy h:mm a').format(DateTime.now()),
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'backup') {
                            await _backupData();
                          } else if (value == 'restore') {
                            await _restoreData();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'backup',
                            child: Row(
                              children: [
                                Icon(Icons.backup, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Backup'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'restore',
                            child: Row(
                              children: [
                                Icon(Icons.restore, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Restore'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: NotepadLinesPainter())),
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: tc,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(fontSize: 18, color: Colors.black87, height: 1.66),
                              decoration: InputDecoration(
                                hintText: getText('write_note_hint'),
                                hintStyle: const TextStyle(color: Colors.black38),
                                border: InputBorder.none,
                                filled: false,
                              ),
                            ),
                            if (existingImages.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: existingImages.map((path) => Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(path),
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => s(() => existingImages.remove(path)),
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.black54,
                                            child: Icon(Icons.close, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.black.withOpacity(0.03),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
                              if (picked != null) s(() => existingImages.add(picked.path));
                            },
                            icon: const Icon(Icons.photo_library, size: 20),
                            label: Text(getText('gallery')),
                          ),
                          const SizedBox(width: 20),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await _imagePicker.pickImage(source: ImageSource.camera);
                              if (picked != null) s(() => existingImages.add(picked.path));
                            },
                            icon: const Icon(Icons.camera_alt, size: 20),
                            label: Text(getText('camera')),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: bgs.length,
                          itemBuilder: (c, i) => GestureDetector(
                            onTap: () => s(() {
                              selBg = bgs[i];
                              selectedBg = bgs[i].value;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: CircleAvatar(
                                backgroundColor: bgs[i],
                                radius: 18,
                                child: selBg == bgs[i]
                                    ? const Icon(Icons.check, color: Colors.black54, size: 18)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => setState(() => _isNoteEditorOpen = false));
  }

  void _openDrawingNotebook({Map<String, dynamic>? existingNote, String? key}) {
    if (_isDrawingEditorOpen) return;
    setState(() => _isDrawingEditorOpen = true);
    List<Color> bgs = [Colors.yellow.shade100, Colors.green.shade100, Colors.blue.shade100, Colors.pink.shade100, Colors.purple.shade100, Colors.orange.shade100];
    String extraRaw = existingNote?['category']?.toString() ?? '';
    int selectedBg = Colors.yellow.shade100.value;
    List<String> existingImages = [];
    List<List<Offset>> completedStrokes = [];
    List<Color> strokeColors = [];
    List<double> strokeWidths = [];
    try {
      if (extraRaw.startsWith('{')) {
        Map<String, dynamic> extra = json.decode(extraRaw);
        selectedBg = (extra['bgColor'] as int?) ?? Colors.yellow.shade100.value;
        existingImages = List<String>.from(extra['imagePaths'] ?? []);
        List<dynamic> strokesRaw = extra['strokes'] ?? [];
        for (var stroke in strokesRaw) {
          List<dynamic> points = stroke['points'] ?? [];
          List<Offset> strokePoints = points.map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble())).toList();
          completedStrokes.add(strokePoints);
          strokeColors.add(Color(stroke['color'] ?? Colors.black.value));
          strokeWidths.add((stroke['width'] ?? 4.0).toDouble());
        }
      } else {
        selectedBg = int.tryParse(extraRaw) ?? Colors.yellow.shade100.value;
      }
    } catch (_) {}
    Color selBg = Color(selectedBg);
    List<Offset> currentStroke = [];
    Color currentColor = Colors.black;
    double currentWidth = 4.0;
    bool isEraser = false;
    List<List<List<Offset>>> undoStrokes = [];
    List<List<Color>> undocolors = [];
    List<List<double>> undoWidths = [];
    List<List<List<Offset>>> redoStrokes = [];
    List<List<Color>> redocolors = [];
    List<List<double>> redoWidths = [];
    void saveToUndo() { undoStrokes.add(completedStrokes.map((s) => s.map((p) => Offset(p.dx, p.dy)).toList()).toList()); undocolors.add(List.from(strokeColors)); undoWidths.add(List.from(strokeWidths)); redoStrokes.clear(); redocolors.clear(); redoWidths.clear(); }
    void undo() { if (undoStrokes.isNotEmpty) { redoStrokes.add(completedStrokes.map((s) => s.map((p) => Offset(p.dx, p.dy)).toList()).toList()); redocolors.add(List.from(strokeColors)); redoWidths.add(List.from(strokeWidths)); completedStrokes = undoStrokes.removeLast().map((s) => s.map((p) => Offset(p.dx, p.dy)).toList()).toList(); strokeColors = List.from(undocolors.removeLast()); strokeWidths = List.from(undoWidths.removeLast()); if (mounted) setState(() {}); } }
    void redo() { if (redoStrokes.isNotEmpty) { undoStrokes.add(completedStrokes.map((s) => s.map((p) => Offset(p.dx, p.dy)).toList()).toList()); undocolors.add(List.from(strokeColors)); undoWidths.add(List.from(strokeWidths)); completedStrokes = redoStrokes.removeLast().map((s) => s.map((p) => Offset(p.dx, p.dy)).toList()).toList(); strokeColors = List.from(redocolors.removeLast()); strokeWidths = List.from(redoWidths.removeLast()); if (mounted) setState(() {}); } }
    void clearAll() { if (completedStrokes.isEmpty) return; saveToUndo(); completedStrokes.clear(); strokeColors.clear(); strokeWidths.clear(); if (mounted) setState(() {}); }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => Container(
          height: MediaQuery.of(c).size.height * 0.92,
          decoration: BoxDecoration(color: selBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.close, size: 28), onPressed: () { _isDrawingEditorOpen = false; Navigator.pop(c); }),
                    Text(existingNote == null ? getText('drawing_create') : getText('drawing_edit'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.undo), onPressed: () { undo(); s(() {}); }),
                      IconButton(icon: const Icon(Icons.redo), onPressed: () { redo(); s(() {}); }),
                      IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: () { clearAll(); s(() {}); }),
                      ElevatedButton(onPressed: () async {
                        Map<String, dynamic> extra = {
                          'bgColor': selBg.value, 'imagePaths': existingImages,
                          'strokes': completedStrokes.asMap().entries.map((e) => {
                            'points': e.value.map((off) => {'dx': off.dx, 'dy': off.dy}).toList(),
                            'color': strokeColors[e.key].value, 'width': strokeWidths[e.key],
                          }).toList(),
                          'hasDrawing': completedStrokes.isNotEmpty,
                        };
                        final newNote = TransactionModel(
                          id: key ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: 0, note: "🎨 ${getText('drawing')}", type: "Note", category: json.encode(extra),
                          date: DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()), isArchived: false,
                        );
                        await LocalDatabaseService().addTransaction(newNote);
                        final newNoteMap = {'key': newNote.id, 'note': newNote.note, 'date': newNote.date, 'category': newNote.category};
                        if (mounted) {
                          setState(() {
                            if (key != null) {
                              _drawingNotes.removeWhere((drawing) => drawing['key'] == key);
                            }
                            _drawingNotes.insert(0, newNoteMap);
                          });
                        }
                        _isDrawingEditorOpen = false;
                        Navigator.pop(c);
                        _showSnackBar(getText('drawing_saved'), Colors.green);
                      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text(getText('save'))),
                    ]),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    onPanStart: (details) => s(() => currentStroke = [details.localPosition]),
                    onPanUpdate: (details) => s(() => currentStroke = List.from(currentStroke)..add(details.localPosition)),
                    onPanEnd: (details) => s(() {
                      if (currentStroke.isNotEmpty) {
                        saveToUndo();
                        completedStrokes = List.from(completedStrokes)..add(List.from(currentStroke));
                        strokeColors = List.from(strokeColors)..add(isEraser ? selBg : currentColor);
                        strokeWidths = List.from(strokeWidths)..add(isEraser ? 20.0 : currentWidth);
                        currentStroke = [];
                      }
                    }),
                    child: Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: CustomPaint(
                        painter: FullDrawingPainter(
                          completedStrokes: completedStrokes,
                          strokeColors: strokeColors,
                          strokeWidths: strokeWidths,
                          currentStroke: currentStroke,
                          currentColor: isEraser ? selBg : currentColor,
                          currentWidth: isEraser ? 20.0 : currentWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                      _buildColorCircle(Colors.black, currentColor, s, () { isEraser = false; currentColor = Colors.black; }),
                      _buildColorCircle(Colors.red, currentColor, s, () { isEraser = false; currentColor = Colors.red; }),
                      _buildColorCircle(Colors.blue, currentColor, s, () { isEraser = false; currentColor = Colors.blue; }),
                      _buildColorCircle(Colors.green, currentColor, s, () { isEraser = false; currentColor = Colors.green; }),
                      _buildColorCircle(Colors.orange, currentColor, s, () { isEraser = false; currentColor = Colors.orange; }),
                      _buildColorCircle(Colors.purple, currentColor, s, () { isEraser = false; currentColor = Colors.purple; }),
                      _buildColorCircle(Colors.pink, currentColor, s, () { isEraser = false; currentColor = Colors.pink; }),
                      _buildColorCircle(Colors.brown, currentColor, s, () { isEraser = false; currentColor = Colors.brown; }),
                      GestureDetector(
                        onTap: () => s(() { isEraser = !isEraser; }),
                        child: Container(margin: const EdgeInsets.symmetric(horizontal: 5), width: 40, height: 40, decoration: BoxDecoration(color: isEraser ? Colors.grey.shade300 : Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey)), child: Icon(Icons.brush, color: isEraser ? Colors.grey : Colors.black)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [const Icon(Icons.line_weight), const SizedBox(width: 8), Expanded(child: Slider(value: currentWidth, min: 2.0, max: 20.0, onChanged: (v) => s(() { currentWidth = v; isEraser = false; }))), Text("${currentWidth.toInt()}px")]),
                    const SizedBox(height: 8),
                    Wrap(spacing: 16, runSpacing: 8, alignment: WrapAlignment.center, children: [
                      ElevatedButton.icon(onPressed: () async { final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80); if (picked != null) s(() => existingImages = List.from(existingImages)..add(picked.path)); }, icon: const Icon(Icons.photo_library), label: Text(getText('gallery'))),
                      ElevatedButton.icon(onPressed: () async { final picked = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80); if (picked != null) s(() => existingImages = List.from(existingImages)..add(picked.path)); }, icon: const Icon(Icons.camera_alt), label: Text(getText('camera'))),
                    ]),
                  ],
                ),
              ),
              Container(
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: bgs.length, itemBuilder: (c, i) => GestureDetector(
                  onTap: () => s(() { selBg = bgs[i]; selectedBg = bgs[i].value; }),
                  child: Padding(padding: const EdgeInsets.all(8), child: CircleAvatar(backgroundColor: bgs[i], radius: 28, child: selBg == bgs[i] ? const Icon(Icons.check, color: Colors.black54, size: 28) : null)),
                )),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ).then((_) => _isDrawingEditorOpen = false);
  }

  Widget _buildColorCircle(Color color, Color currentColor, StateSetter s, VoidCallback onTap) => GestureDetector(
    onTap: () { onTap(); s(() {}); },
    child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 40, height: 40, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: color == currentColor ? Border.all(color: Colors.white, width: 3) : null, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))])),
  );

  // ========== MAIN BUILD ==========
  @override
  Widget build(BuildContext context) {
    final bool isDark = _isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: _isDarkMode
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF1E40AF), const Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 360;
                return Stack(children: [
                  Positioned(
                    top: 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                                child: Text(getText('app_title'),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: isSmall ? 15 : 17,
                                        letterSpacing: 0.5,
                                        shadows: const [
                                          Shadow(
                                              color: Colors.black26,
                                              offset: Offset(0, 1.5),
                                              blurRadius: 3)
                                        ]),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1)),
                            const SizedBox(width: 5),
                            const SizedBox(width: 8),
                          ]),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(children: [
                                GestureDetector(
                                  onTap: () => setState(() => _currentIndex = 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white54, width: 1.5),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: Offset(0, 2))
                                        ]),
                                    child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.white24,
                                        child: () {
                                          if (_profileImagePath != null &&
                                              File(_profileImagePath!).existsSync()) {
                                            return ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(18),
                                                child: Image.file(
                                                  File(_profileImagePath!),
                                                  width: 36,
                                                  height: 36,
                                                  fit: BoxFit.cover,
                                                ));
                                          }
                                          return const Icon(Icons.person,
                                              color: Colors.white, size: 20);
                                        }()),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(children: [
                                        Icon(_getGreetingIcon(),
                                            color: Colors.amberAccent, size: 11),
                                        const SizedBox(width: 3),
                                        Text(_getCurrentGreeting(),
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500))
                                      ]),
                                      const SizedBox(height: 1),
                                      SizedBox(
                                          width: isSmall ? 85 : 110,
                                          child: Text(
                                              _userName.isNotEmpty
                                                  ? _userName
                                                  : getText('user_name'),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1)),
                                    ]),
                              ]),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.white),
                                onSelected: (value) async {
                                  if (value == 'backup') {
                                    await _backupData();
                                  } else if (value == 'restore') {
                                    await _restoreData();
                                  } else if (value == 'gdrive_backup') {
                                    await _backupToGoogleDrive();
                                  } else if (value == 'logout') {
                                    _logout();
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                      value: 'backup',
                                      child: Row(children: [
                                        Icon(Icons.backup, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text(getText('backup'))
                                      ])),
                                  PopupMenuItem(
                                      value: 'restore',
                                      child: Row(children: [
                                        Icon(Icons.restore, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        Text(getText('restore'))
                                      ])),
                                  PopupMenuItem(
                                      value: 'gdrive_backup',
                                      child: Row(children: [
                                        Icon(Icons.cloud_upload,
                                            color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text(getText('google_drive_backup'))
                                      ])),
                                  PopupMenuItem(
                                      value: 'logout',
                                      child: Row(children: [
                                        Icon(Icons.logout, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text(getText('logout'))
                                      ])),
                                ],
                              ),
                            ]),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 6,
        backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8),
        onPressed: _openCalculator,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 28),
      ),
      body: IndexedStack(index: _currentIndex, children: [
        _buildMainBody(),
        _buildCalendarBody(),
        _buildNoticeBody(),
        _buildNotebookBody(),
        _buildProfileBody()
      ]),
      // 🔥 এখানে MagicNavigationBar ব্যবহার করা হয়েছে
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: MagicNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          isDarkMode: isDark,
        ),
      ),
    );
  }

  // ========== MAIN BODY ==========
  Widget _buildMainBody() {
    String symbol = _currencySymbols[_selectedCurrency] ?? '৳';
    final db = LocalDatabaseService();
    return ValueListenableBuilder(
      valueListenable: db.transactionsBox.listenable(),
      builder: (context, Box<TransactionModel> box, _) {
        final allList = box.values.toList();
        final filtered = allList.where((tx) => tx.type != 'Note' && tx.type != 'Reminder' && !tx.isArchived).toList();
        filtered.sort((a, b) => b.date.compareTo(a.date));

        double inc = filtered.where((t) => t.type == 'Income').fold(0, (s, t) => s + t.amount);
        double exp = filtered.where((t) => t.type == 'Expense').fold(0, (s, t) => s + t.amount);
        double sav = filtered.where((t) => t.type == 'Savings').fold(0, (s, t) => s + t.amount);
        double dbt = filtered.where((t) => t.type == 'Debt').fold(0, (s, t) => s + t.amount);
        double crd = filtered.where((t) => t.type == 'Credit').fold(0, (s, t) => s + t.amount);

        return RefreshIndicator(
          onRefresh: () async => _loadDataFromHive(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfessionalSummaryGrid(inc, exp, sav, dbt, crd, symbol),
                const SizedBox(height: 20),
                _buildProfessionalActionButtons(),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildBudgetOverviewCard()),
                const SizedBox(height: 20),
                _buildProfessionalSectionTitle(getText('income_expense_stats'), Icons.bar_chart),
                const SizedBox(height: 12),
                _buildProfessionalDashboardStatsGrid(),
                const SizedBox(height: 20),
                _buildProfessionalSectionTitle(getText('other_accounts'), Icons.account_balance_wallet),
                const SizedBox(height: 12),
                _buildProfessionalOtherAccountsGrid(),
                const SizedBox(height: 20),
                _buildFeatureButtonsRow(),
                const SizedBox(height: 20),
                _buildProfessionalSectionTitle(getText('recent_transactions'), Icons.history),
                const SizedBox(height: 12),
                _buildTransactionHistory(
                  filtered.map((tx) => {
                    'key': tx.id,
                    'amount': tx.amount,
                    'note': tx.note,
                    'type': tx.type,
                    'date': tx.date,
                    'category': tx.category,
                    'isArchived': tx.isArchived,
                    'time': tx.time,
                  }).toList(),
                  symbol,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // UI COMPONENTS
  Widget _buildProfessionalSummaryGrid(double inc, double exp, double sav, double dbt, double crd, String symbol) {
    final items = [
      {'label': getText('income'), 'value': inc, 'color': Colors.green, 'icon': Icons.trending_up},
      {'label': getText('expense'), 'value': exp, 'color': Colors.red, 'icon': Icons.trending_down},
      {'label': getText('savings'), 'value': sav, 'color': Colors.blue, 'icon': Icons.savings},
      {'label': getText('debt'), 'value': dbt, 'color': Colors.deepOrange, 'icon': Icons.money_off},
      {'label': getText('credit'), 'value': crd, 'color': Colors.deepPurple, 'icon': Icons.attach_money},
      {'label': getText('balance'), 'value': inc - exp + sav - dbt + crd, 'color': Colors.teal, 'icon': Icons.account_balance},
    ];
    return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 0.8, children: items.map((item) => _buildGradientCard(item['label'] as String, item['value'] as double, item['color'] as Color, item['icon'] as IconData, symbol)).toList());
  }

  Widget _buildGradientCard(String label, double value, Color color, IconData icon, String symbol) => AnimatedBorderCard(baseColor: color, child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(height: 2), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)), const SizedBox(height: 1), Text(_formatAmount(value), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))])));

  Widget _buildProfessionalActionButtons() => Row(children: [Expanded(child: _buildGradientButton(getText('income'), Icons.add, Colors.green, _showIncomeDialog)), const SizedBox(width: 12), Expanded(child: _buildGradientButton(getText('expense'), Icons.remove, Colors.red, _showExpenseDialog))]);

  Widget _buildGradientButton(String label, IconData icon, Color color, VoidCallback onPressed) => Expanded(child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.transparent, elevation: 0, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), minimumSize: const Size(0, 52)), child: Ink(decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(30)), child: Container(alignment: Alignment.center, height: 52, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 24), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))])))));

  Widget _buildProfessionalSectionTitle(String title, IconData icon) => Row(children: [Icon(icon, color: Colors.blue.shade700, size: 22), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _isDarkMode ? Colors.white : Colors.blueGrey.shade800))]);

  Widget _buildProfessionalDashboardStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.today,
            getText('daily'),
            Colors.orange,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyStatsScreen(
                  selectedLanguage: _selectedLanguage,
                  localizedText: _localizedText,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.calendar_month,
            getText('monthly'),
            Colors.red,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MonthlyStatsScreen(
                  selectedLanguage: _selectedLanguage,
                  localizedText: _localizedText,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.history,
            getText('yearly'),
            Colors.teal,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => YearlyStatsScreen(
                  selectedLanguage: _selectedLanguage,
                  localizedText: _localizedText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherAccountCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalOtherAccountsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildOtherAccountCard(
            Icons.money_off,
            getText('debt'),
            Colors.deepOrange,
                () => _showDebtCreditDialog("দেনা"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOtherAccountCard(
            Icons.attach_money,
            getText('credit'),
            Colors.deepPurple,
                () => _showDebtCreditDialog("পাওনা"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOtherAccountCard(
            Icons.savings,
            getText('savings'),
            Colors.blue,
                () => _showSavingsDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureButtonsRow() => Row(
    children: [
      Expanded(
        child: _buildFeatureButton(
          getText('budget_management'),
          Icons.account_balance_wallet,
          Colors.teal,
              () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BudgetScreen(
                selectedLanguage: _selectedLanguage,
                localizedText: _localizedText,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildFeatureButton(
          getText('recurring_transactions'),
          Icons.repeat,
          Colors.purple,
              () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecurringScreen(
                selectedLanguage: _selectedLanguage,
                localizedText: _localizedText,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildFeatureButton(
          getText('export_report'),
          Icons.download,
          Colors.indigo,
              () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExportScreen(
                selectedLanguage: _selectedLanguage,
                selectedCurrency: _selectedCurrency,
                currencySymbol: _currencySymbols[_selectedCurrency] ?? '৳',
                localizedText: _localizedText,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildFeatureButton(String label, IconData icon, Color color, VoidCallback onTap) => ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: color, elevation: 2, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 20), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))]));

  Widget _buildTransactionHistory(List<Map<String, dynamic>> list, String symbol) {
    if (list.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(getText('no_transactions'), style: TextStyle(fontSize: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey))));
    return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: list.length, itemBuilder: (context, i) {
      final tx = list[i];
      final isInc = tx['type'] == 'Income';
      final ac = isInc ? Colors.green : Colors.red;
      double amt = 0.0; var raw = tx['amount']; if (raw is double) amt = raw; else if (raw is int) amt = raw.toDouble(); else if (raw is String) amt = double.tryParse(raw) ?? 0.0;
      return Card(margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6), elevation: 1.5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: _isDarkMode ? Colors.grey[850] : Colors.white, child: ListTile(
        leading: CircleAvatar(backgroundColor: ac.withOpacity(0.15), child: Icon(isInc ? Icons.arrow_downward : Icons.arrow_upward, color: ac)),
        title: Text(tx['note'] ?? "", style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text("${getCategoryName(tx['category'] ?? 'other')} • ${tx['date'] ?? ""}", style: TextStyle(fontSize: 11, color: _isDarkMode ? Colors.grey[400] : Colors.grey)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(_formatAmount(amt), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ac)), const SizedBox(width: 12), Icon(Icons.more_vert, color: Colors.grey)]),
        onTap: () => _showTransactionOptions(tx),
      ));
    });
  }

  // ==================== BUDGET OVERVIEW CARD ====================
  Widget _buildBudgetOverviewCard() {
    String symbol = _currencySymbols[_selectedCurrency] ?? '৳';
    String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    return ValueListenableBuilder(
      valueListenable: Hive.box<BudgetModel>('budgets').listenable(),
      builder: (context, Box<BudgetModel> budgetBox, _) {
        final allBudgets = budgetBox.values.toList();
        final monthBudgets = allBudgets.where((b) => b.month == currentMonth).toList();

        if (monthBudgets.isEmpty) {
          return const SizedBox.shrink();
        }

        double totalBudget = monthBudgets.fold(0, (sum, b) => sum + b.budgetAmount);
        double totalSpent = monthBudgets.fold(0, (sum, b) => sum + b.spentAmount);
        double remaining = totalBudget - totalSpent;
        double percentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

        Color statusColor = percentage >= 100 ? Colors.red :
        percentage >= 80 ? Colors.orange :
        Colors.teal;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BudgetScreen(
              selectedLanguage: _selectedLanguage,
              localizedText: _localizedText,
            )),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.8), statusColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          getText('monthly_budget'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatAmount(totalSpent),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          getText('budget_spent'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatAmount(totalBudget),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          getText('total_budget'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}% ${getText('used')}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '${getText('remaining')}: ${_formatAmount(remaining)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                if (percentage >= 100)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.white, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          '${getText('budget_exceeded')}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== CALENDAR BODY ====================
  Widget _buildCalendarBody() {
    DateTime sd = _selectedDay ?? DateTime.now();
    String? holiday = BDHolidays.getHoliday(sd);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: TableCalendar(
                      locale: _selectedLanguage,
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                      onDaySelected: (sd2, fd) {
                        setState(() {
                          _selectedDay = sd2;
                          _focusedDay = fd;
                        });
                      },
                      calendarFormat: _calendarFormat,
                      onFormatChanged: (f) => setState(() => _calendarFormat = f),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        weekendTextStyle: const TextStyle(color: Colors.red),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                        weekendStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      eventLoader: (d) => _events[d] ?? [],
                    ),
                  ),
                ),
                _buildDateInfoCard(),
                if (holiday != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${getText('government_holiday')}: $holiday',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                _buildAddReminderButton(),
                if (_events[sd]?.isEmpty ?? true)
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(getText('no_reminders')),
                      ],
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfoCard() {
    DateTime sd = _selectedDay ?? DateTime.now();
    return Container(margin: const EdgeInsets.symmetric(horizontal: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.purple.shade600]), borderRadius: BorderRadius.circular(20)), child: Column(children: [
      Row(children: [const Icon(Icons.calendar_today, color: Colors.white), const SizedBox(width: 10), Text(DateFormat('EEEE, d MMMM yyyy').format(sd), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
      if (_showBengaliDate) ...[const SizedBox(height: 8), Row(children: [const Icon(Icons.calendar_month, color: Colors.white, size: 18), const SizedBox(width: 10), Text('বাংলা: ${BengaliCalendar.getBengaliDate(sd)}, ${BengaliCalendar.getBengaliDay(sd.weekday)}', style: const TextStyle(color: Colors.white))])],
      if (_showHijriDate) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_view_month, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'হিজরি: ${HijriCalendar.getHijriDate(sd, _selectedLanguage)}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ],
    ]));
  }

  Widget _buildAddReminderButton() => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: ElevatedButton.icon(onPressed: _showReminderInput, icon: const Icon(Icons.add_alert), label: Text(getText('add_reminder')), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5)));

  Widget _buildNoticeBody() {
    if (_allReminders.isEmpty && _remoteNotices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              getText('no_notices'),
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshNotices,
              icon: const Icon(Icons.refresh),
              label: Text(getText('refresh')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNotices,
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getText('notice'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshNotices,
                tooltip: getText('refresh'),
              ),
            ],
          ),
          if (_allReminders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                getText('reminders'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            ..._allReminders.map((reminder) => _buildReminderCard(reminder)),
          ],
          if (_remoteNotices.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                getText('miscellaneous_notices'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            ..._remoteNotices.map((notice) => _buildRemoteNoticeCard(notice)),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final targetDate = DateFormat('dd/MM/yyyy').parse(reminder['date']);
    final targetTime = _parseTimeOfDay(reminder['time']);
    final targetDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, targetTime.hour, targetTime.minute);
    final timeLeftText = _getTimeLeftString(targetDateTime);
    final isOverdue = targetDateTime.isBefore(DateTime.now());
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: _isDarkMode ? Colors.grey[850] : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.orange),
        title: Text(reminder['note'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${reminder['date']} ⏰ ${reminder['time']}"),
            const SizedBox(height: 4),
            Text(
              timeLeftText,
              style: TextStyle(color: isOverdue ? Colors.red : Colors.green, fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _editReminder(reminder['key'], reminder['note'], reminder['date'], reminder['time']),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _markReminderDone(reminder['key']),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(reminder['key']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteNoticeCard(RemoteNotice notice) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _isDarkMode ? Colors.grey[850] : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.announcement, color: Colors.purple),
        title: Text(
          notice.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice.body),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().format(notice.date),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PROFILE BODY ====================
  Widget _buildProfileBody() {
    String cs = _currencySymbols[_selectedCurrency] ?? '৳';
    String ln = _selectedLanguage == 'bn' ? 'বাংলা' : (_selectedLanguage == 'ar' ? 'العربية' : 'English');

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _showProfilePhotoOptions,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: _profileImagePath != null && File(_profileImagePath!).existsSync()
                        ? FileImage(File(_profileImagePath!))
                        : null,
                    child: _profileImagePath == null
                        ? const Icon(Icons.person, size: 50, color: Colors.blue)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userName.isNotEmpty ? _userName : getText('default_user'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              getText('user_name'),
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    ln,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Icon(Icons.currency_exchange, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    "$_selectedCurrency ($cs)",
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showProfileDialog,
              icon: const Icon(Icons.settings),
              label: Text(getText('change_settings')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _openSecurityScreen,
              icon: const Icon(Icons.security),
              label: Text(getText('security_settings')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: Text(getText('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// ==================== HELPER CLASSES ====================
class AnimatedBorderCard extends StatelessWidget {
  final Widget child;
  final Color baseColor;

  const AnimatedBorderCard({
    super.key,
    required this.child,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    // স্থির (Static) গ্রেডিয়েন্ট, কোনো লুপিং অ্যানিমেশন নেই
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withOpacity(0.9),
            baseColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FullDrawingPainter extends CustomPainter {
  final List<List<Offset>> completedStrokes;
  final List<Color> strokeColors;
  final List<double> strokeWidths;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentWidth;

  FullDrawingPainter({
    required this.completedStrokes,
    required this.strokeColors,
    required this.strokeWidths,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < completedStrokes.length; i++) {
      Color strokeColor = (i < strokeColors.length) ? strokeColors[i] : currentColor;
      double strokeWidth = (i < strokeWidths.length) ? strokeWidths[i] : currentWidth;

      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      if (completedStrokes[i].isNotEmpty) {
        path.moveTo(completedStrokes[i][0].dx, completedStrokes[i][0].dy);
        for (int j = 1; j < completedStrokes[i].length; j++) {
          path.lineTo(completedStrokes[i][j].dx, completedStrokes[i][j].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    if (currentStroke.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FullDrawingPainter oldDelegate) {
    return oldDelegate.completedStrokes != completedStrokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentWidth != currentWidth ||
        oldDelegate.strokeColors != strokeColors ||
        oldDelegate.strokeWidths != strokeWidths;
  }
}

class NotepadLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.0;
    const double lineHeight = 30.0;
    int lines = (size.height / lineHeight).ceil();
    for (int i = 1; i <= lines; i++) {
      double y = i * lineHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== MagicNavigationBar (Modern & Fast) ====================
class MagicNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDarkMode;

  const MagicNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDarkMode,
  });

  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.home_outlined, 'label': 'হোম'},
    {'icon': Icons.calendar_month_outlined, 'label': 'ক্যালেন্ডার'},
    {'icon': Icons.notifications_none_outlined, 'label': 'নোটিশ'},
    {'icon': Icons.book_outlined, 'label': 'নোটবুক'},
    {'icon': Icons.person_outline_outlined, 'label': 'প্রোফাইল'},
  ];

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary নেভিগেশন বারের অ্যানিমেশনকে আলাদা করে দেয়, ফলে বাকি অ্যাপ ল্যাগ করে না
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_menuItems.length, (index) {
            return _MagicNavButton(
              index: index,
              selectedIndex: currentIndex,
              onTap: () => onTap(index),
              icon: _menuItems[index]['icon'],
              label: _menuItems[index]['label'],
              isDarkMode: isDarkMode,
            );
          }),
        ),
      ),
    );
  }
}

class _MagicNavButton extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isDarkMode;

  const _MagicNavButton({
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == selectedIndex;

    final Color activeColor = const Color(0xFF2ecc71);
    final Color iconColor = isSelected
        ? Colors.white
        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600);
    final Color textColor = isSelected
        ? (isDarkMode ? Colors.white : Colors.blue.shade700)
        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AnimatedSlide দ্রুত এবং স্মুথ উপরে ওঠার জন্য ব্যবহার করা হয়েছে
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack, // হালকা বাউন্স ইফেক্ট
            offset: isSelected ? const Offset(0, -0.5) : Offset.zero,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : null,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}