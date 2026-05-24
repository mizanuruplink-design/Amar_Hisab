import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/transaction_model.dart';
import 'daily_stats_screen.dart';
import 'monthly_stats_screen.dart';
import 'yearly_stats_screen.dart';
import 'recurring_screen.dart';
import 'export_screen.dart';
import 'security_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'budget_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==================== Helper Classes ====================
class HijriCalendar {
  static Map<int, String> hijriMonths = {
    1: 'মুহাররম', 2: 'সফর', 3: 'রবিউল আউয়াল', 4: 'রবিউস সানি',
    5: 'জমাদিউল আউয়াল', 6: 'জমাদিউস সানি', 7: 'রজব', 8: 'শাবান',
    9: 'রমজান', 10: 'শাওয়াল', 11: 'জিলকদ', 12: 'জিলহজ',
  };
  static String getHijriDate(DateTime date) {
    double hijriYear = date.year - 622 + (date.month - 1) / 12;
    int hijriYearInt = hijriYear.floor();
    int hijriMonth = ((hijriYear - hijriYearInt) * 12).floor() + 1;
    int hijriDay = date.day;
    if (hijriMonth > 12) { hijriMonth = 1; hijriYearInt++; }
    return '${hijriDay} ${hijriMonths[hijriMonth]} $hijriYearInt হিজরি';
  }
}

class BengaliCalendar {
  static Map<int, String> bengaliMonths = {
    1: 'বৈশাখ', 2: 'জ্যৈষ্ঠ', 3: 'আষাঢ়', 4: 'শ্রাবণ',
    5: 'ভাদ্র', 6: 'আশ্বিন', 7: 'কার্তিক', 8: 'অগ্রহায়ণ',
    9: 'পৌষ', 10: 'মাঘ', 11: 'ফাল্গুন', 12: 'চৈত্র',
  };
  static String getBengaliDate(DateTime date) {
    int bengaliYear = date.year - 593;
    int bengaliMonth = date.month;
    int bengaliDay = date.day;
    if (date.month <= 3) {
      bengaliYear--;
      bengaliMonth += 9;
    } else {
      bengaliMonth -= 3;
    }
    if (bengaliMonth > 12) {
      bengaliMonth -= 12;
    }
    return '${bengaliDay} ${bengaliMonths[bengaliMonth]} $bengaliYear';
  }
  static String getBengaliDay(int weekday) {
    Map<int, String> days = {1: 'সোমবার', 2: 'মঙ্গলবার', 3: 'বুধবার', 4: 'বৃহস্পতিবার', 5: 'শুক্রবার', 6: 'শনিবার', 7: 'রবিবার'};
    return days[weekday] ?? '';
  }
}

class BDHolidays {
  static Map<String, String> holidays = {
    '21/02': 'শহীদ দিবস', '17/03': 'বঙ্গবন্ধুর জন্মদিন', '26/03': 'স্বাধীনতা দিবস',
    '14/04': 'পহেলা বৈশাখ', '01/05': 'মে দিবস', '15/08': 'শোক দিবস', '16/12': 'বিজয় দিবস', '25/12': 'বড়দিন',
  };
  static String? getHoliday(DateTime date) {
    String key = DateFormat('dd/MM').format(date);
    return holidays[key];
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==================== NOTEBOOK SEPARATION ====================
  List<Map<String, dynamic>> _textNotes = [];
  List<Map<String, dynamic>> _drawingNotes = [];
  int _notebookMode = 0;
  bool _isNoteEditorOpen = false;
  bool _isDrawingEditorOpen = false;
  String? _localProfilePicPath;

  // ==================== EXISTING VARIABLES ====================
  int _currentIndex = 0;
  String _selectedLanguage = 'bn';
  String _selectedCurrency = 'BDT';
  bool _showHijriDate = true;
  bool _showBengaliDate = true;
  bool _isDarkMode = false;
  String _userName = '';
  String? _profileImagePath;
  final ImagePicker _imagePicker = ImagePicker();
  late final FlutterLocalNotificationsPlugin _notificationsPlugin;
  late final Stream<bool> _connectionStream;

  Map<String, String> _currencySymbols = {'BDT': '৳', 'USD': '\$', 'EUR': '€', 'GBP': '£', 'INR': '₹'};

  // ==================== LOCALIZATION (full 3 languages) ====================
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
      'faq_q3': 'আমার ফোনের ডাটা হারিয়ে যাওয়ার ভয় আছে কি?',
      'faq_a3': 'না। আপনার ডাটা অনলাইন সিঙ্ক সুবিধায় সুরক্ষিত থাকে। ফোন পরিবর্তন বা অ্যাপ আনইনস্টল করলেও একই অ্যাকাউন্টে লগইন করে সব ডাটা ফিরে পাবেন।',
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
      'debt': 'Debt',
      'credit': 'Credit',
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
      'faq_q3': 'Will I lose my data if I change my phone?',
      'faq_a3': 'No. Your data is safely stored in your account. After logging in on a new device, all your records will be restored.',
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
      'reminder_debt_payment': 'Reminder: Debt payment',
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
      'debt': 'دين',
      'credit': 'ائتمان',
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
      'faq_q3': 'هل سأفقد بياناتي إذا غيرت هاتفي؟',
      'faq_a3': 'لا. يتم تخزين بياناتك بأمان في حسابك. بعد تسجيل الدخول على جهاز جديد، سيتم استعادة جميع سجلاتك.',
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
      'reminder_debt_payment': 'تذكير: سداد الدين',
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

  String getCategoryName(String key) => getText(key);

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

  // ========== Greeting with icon ==========
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

  // ========== Helper: parse time string ==========
  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final format = DateFormat('h:mm a');
      final date = format.parse(timeStr);
      return TimeOfDay(hour: date.hour, minute: date.minute);
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

  // LIFECYCLE
  @override
  void initState() {
    super.initState();
    _connectionStream = DatabaseService().connectionStatus;
    _listenToConnection();
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _loadUserSettings();
    _loadCurrentUserProfilePic();
  }

  void _listenToConnection() {
    _connectionStream.listen((isOnline) {
      if (mounted && isOnline) _syncOfflineData();
    });
  }

  void _loadCurrentUserProfilePic() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        setState(() => _localProfilePicPath = prefs.getString('profile_pic_${user.uid}'));
      } else {
        setState(() => _localProfilePicPath = null);
      }
    });
  }

  Future<void> _syncOfflineData() async {
    final count = await DatabaseService().syncOfflineToOnline();
    if (count > 0 && mounted) {
      _showSnackBar('$count টি অফলাইন ডাটা সিঙ্ক হয়েছে', Colors.green);
      setState(() {});
    }
  }

  @override
  void dispose() { super.dispose(); }

  // USER SETTINGS
  void _loadUserSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _userName = prefs.getString('userName') ?? '';
      _profileImagePath = prefs.getString('profileImagePath');
      _selectedLanguage = prefs.getString('language') ?? 'bn';
      _selectedCurrency = prefs.getString('currency') ?? 'BDT';
    });
  }

  Future<void> _saveUserSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setString('userName', _userName);
    if (_profileImagePath != null) await prefs.setString('profileImagePath', _profileImagePath!);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('currency', _selectedCurrency);
    if (mounted) setState(() {});
  }

  // NOTIFICATIONS
  void _initializeNotifications() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iOSSettings);
    await _notificationsPlugin.initialize(settings, onDidReceiveNotificationResponse: (r) {
      if (mounted) {
        setState(() => _currentIndex = 2);
        if (r.payload != null) {
          final parts = r.payload!.split('|');
          if (parts.length == 2) {
            final reminderId = parts[0];
            final action = parts[1];
            if (action == 'done') _markReminderDone(reminderId);
            else if (action == 'snooze') _showSnoozeDialog(reminderId);
          }
        }
      }
    });
    if (Platform.isAndroid) {
      final p = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await p?.requestNotificationsPermission();
    }
  }

  Future<void> _scheduleNotification(String title, DateTime dateTime, String id, {bool reschedule = false}) async {
    try {
      if (reschedule) await _notificationsPlugin.cancel(id.hashCode.abs() % 100000);
      final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
      if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
        await _notificationsPlugin.zonedSchedule(
          id.hashCode.abs() % 100000,
          getText('app_title'),
          title,
          scheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'r', 'রিমাইন্ডার',
              importance: Importance.max,
              priority: Priority.high,
              actions: [
                AndroidNotificationAction('done', getText('mark_done')),
                AndroidNotificationAction('snooze', getText('snooze')),
              ],
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true,
              categoryIdentifier: 'reminder_category',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: '$id|',
        );
      }
    } catch (e) {}
  }

  void _showTodayReminders() {} // placeholder

  Future<void> _markReminderDone(String id) async {
    await DatabaseService().updateReminderCompleted(id, true);
    setState(() {
      final index = _allReminders.indexWhere((r) => r['key'] == id);
      if (index != -1) _allReminders[index]['completed'] = true;
    });
    _showSnackBar(getText('reminder_completed'), Colors.green);
  }

  void _showSnoozeDialog(String reminderId) {
    final reminder = _allReminders.firstWhere((r) => r['key'] == reminderId);
    final oldDate = DateFormat('dd/MM/yyyy').parse(reminder['date']);
    final oldTime = _parseTimeOfDay(reminder['time']);
    DateTime oldDateTime = DateTime(oldDate.year, oldDate.month, oldDate.day, oldTime.hour, oldTime.minute);

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(getText('snooze')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(getText('snooze_1h')), onTap: () { Navigator.pop(c); _rescheduleReminder(reminderId, oldDateTime.add(const Duration(hours: 1))); }),
            ListTile(title: Text(getText('snooze_1d')), onTap: () { Navigator.pop(c); _rescheduleReminder(reminderId, oldDateTime.add(const Duration(days: 1))); }),
            ListTile(title: Text(getText('snooze_1w')), onTap: () { Navigator.pop(c); _rescheduleReminder(reminderId, oldDateTime.add(const Duration(days: 7))); }),
          ],
        ),
      ),
    );
  }

  Future<void> _rescheduleReminder(String id, DateTime newDateTime) async {
    final newDateStr = DateFormat('dd/MM/yyyy').format(newDateTime);
    final newTimeStr = DateFormat('h:mm a').format(newDateTime);
    await DatabaseService().updateReminder(id, null, newDateStr, newTimeStr);
    await _scheduleNotification(
      _allReminders.firstWhere((r) => r['key'] == id)['note'],
      newDateTime, id, reschedule: true,
    );
    setState(() {});
    _showSnackBar(getText('reminder_updated'), Colors.orange);
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
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
            decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[850] : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(getText('edit_reminder'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: getText('title'), border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    DateTime? p = await showDatePicker(context: c, initialDate: selDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (p != null) s(() => selDate = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [const Icon(Icons.calendar_today), const SizedBox(width: 10), Text('${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selDate)}')]),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    TimeOfDay? p = await showTimePicker(context: c, initialTime: selTime);
                    if (p != null) s(() => selTime = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [const Icon(Icons.access_time), const SizedBox(width: 10), Text('${getText('time')}: ${selTime.format(c)}')]),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty) {
                      final newDate = DateFormat('dd/MM/yyyy').format(selDate);
                      final newTime = selTime.format(c);
                      await DatabaseService().updateReminder(id, titleCtrl.text, newDate, newTime);
                      final newDateTime = DateTime(selDate.year, selDate.month, selDate.day, selTime.hour, selTime.minute);
                      await _scheduleNotification(titleCtrl.text, newDateTime, id, reschedule: true);
                      Navigator.pop(c);
                      _showSnackBar(getText('reminder_updated'), Colors.green);
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, minimumSize: const Size(double.infinity, 50)),
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
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(getText('add_reminder'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: getText('title'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.title))),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    DateTime? p = await showDatePicker(context: c, initialDate: selDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (p != null) s(() => selDate = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [const Icon(Icons.calendar_today), const SizedBox(width: 10), Text('${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selDate)}')]),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    TimeOfDay? p = await showTimePicker(context: c, initialTime: selTime);
                    if (p != null) s(() => selTime = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [const Icon(Icons.access_time), const SizedBox(width: 10), Text('${getText('time')}: ${selTime.format(c)}')]),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      String rId = DateTime.now().millisecondsSinceEpoch.toString();
                      final reminderTx = TransactionModel(
                        id: rId,
                        amount: 0,
                        note: titleCtrl.text,
                        type: 'Reminder',
                        date: DateFormat('dd/MM/yyyy').format(selDate),
                        category: '',
                        isArchived: false,
                        time: selTime.format(c),
                      );
                      DatabaseService().addTransaction(reminderTx);
                      DatabaseService().updateReminderCompleted(rId, false);
                      final reminderDateTime = DateTime(selDate.year, selDate.month, selDate.day, selTime.hour, selTime.minute);
                      _scheduleNotification(titleCtrl.text, reminderDateTime, rId);
                      Navigator.pop(c);
                      _showSnackBar(getText('notification_scheduled'), Colors.green);
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  void _showDebtCreditDialog(String type) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedTxDate = DateTime.now();
    String title = type == 'দেনা' ? getText('debt') : (type == 'পাওনা' ? getText('credit') : getText('savings'));
    String engType = type == 'দেনা' ? 'Debt' : (type == 'পাওনা' ? 'Credit' : 'Savings');
    Color color = type == 'দেনা' ? Colors.orange : (type == 'পাওনা' ? Colors.purple : Colors.blue);

    bool addReminder = false;
    DateTime? reminderDate;
    TimeOfDay? reminderTime;
    String reminderComment = '';

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
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(context: c, initialDate: selectedTxDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) s(() => selectedTxDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [const Icon(Icons.calendar_today, size: 18), const SizedBox(width: 10), Text('${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selectedTxDate)}')]),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: getText('amount'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)), autofocus: true),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, decoration: InputDecoration(labelText: getText('description'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.note))),
                const SizedBox(height: 20),
                CheckboxListTile(title: Text(getText('add_reminder')), value: addReminder, onChanged: (val) => s(() => addReminder = val!), activeColor: Colors.blue, contentPadding: EdgeInsets.zero),
                if (addReminder) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(getText('date')),
                          subtitle: Text(reminderDate == null ? getText('select_date') : DateFormat('dd/MM/yyyy').format(reminderDate!)),
                          onTap: () async {
                            final picked = await showDatePicker(context: c, initialDate: reminderDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                            if (picked != null) s(() => reminderDate = picked);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(getText('time')),
                          subtitle: Text(reminderTime == null ? getText('select_time') : reminderTime!.format(c)),
                          onTap: () async {
                            final picked = await showTimePicker(context: c, initialTime: reminderTime ?? TimeOfDay.now());
                            if (picked != null) s(() => reminderTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: TextEditingController()..text = reminderComment,
                    decoration: InputDecoration(labelText: getText('reminder_comment'), hintText: getText('enter_comment'), border: const OutlineInputBorder()),
                    onChanged: (val) => reminderComment = val,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (amtCtrl.text.isNotEmpty) {
                      double? amt = double.tryParse(amtCtrl.text);
                      if (amt != null) {
                        final debtTx = TransactionModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: amt,
                          note: noteCtrl.text.isEmpty ? title : noteCtrl.text,
                          type: engType,
                          date: DateFormat('dd/MM/yyyy hh:mm a').format(selectedTxDate),
                          category: "other",
                          isArchived: false,
                        );
                        await DatabaseService().addTransaction(debtTx);
                        if (addReminder && reminderDate != null && reminderTime != null) {
                          final reminderDateTime = DateTime(reminderDate!.year, reminderDate!.month, reminderDate!.day, reminderTime!.hour, reminderTime!.minute);
                          final reminderId = DateTime.now().millisecondsSinceEpoch.toString();
                          final reminderNote = reminderComment.isNotEmpty ? reminderComment : "${getText('reminder_debt_payment')}: ${noteCtrl.text}";
                          final reminderTx = TransactionModel(
                            id: reminderId, amount: 0, note: reminderNote, type: 'Reminder',
                            date: DateFormat('dd/MM/yyyy').format(reminderDate!), category: '', isArchived: false,
                            time: reminderTime!.format(c),
                          );
                          await DatabaseService().addTransaction(reminderTx);
                          await DatabaseService().updateReminderCompleted(reminderId, false);
                          _scheduleNotification(reminderNote, reminderDateTime, reminderId);
                        }
                        Navigator.pop(c);
                        _showSnackBar('$title ${getText('save')}', color);
                        setState(() {});
                      }
                    } else {
                      _showSnackBar(getText('amount_error'), Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  // ========== Savings Dialog with Cash/Bank dropdown ==========
  void _showSavingsDialog() {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'cash'; // 'cash' or 'bank'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[850] : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(getText('savings'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(context: c, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) s(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [const Icon(Icons.calendar_today, size: 18), const SizedBox(width: 10), Text('${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selectedDate)}')]),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: getText('amount'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)), autofocus: true),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, decoration: InputDecoration(labelText: getText('description'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.note))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(getText('savings_type'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            items: [
                              DropdownMenuItem(value: 'cash', child: Text(getText('cash'))),
                              DropdownMenuItem(value: 'bank', child: Text(getText('bank'))),
                            ],
                            onChanged: (val) { if (val != null) s(() => selectedType = val); },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (amtCtrl.text.isNotEmpty) {
                      double? amt = double.tryParse(amtCtrl.text);
                      if (amt != null) {
                        String finalNote = noteCtrl.text.trim().isEmpty ? getText('savings') : noteCtrl.text;
                        finalNote += ' [${selectedType == 'cash' ? getText('cash') : getText('bank')}]';
                        final savingsTx = TransactionModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: amt,
                          note: finalNote,
                          type: 'Savings',
                          date: DateFormat('dd/MM/yyyy hh:mm a').format(selectedDate),
                          category: selectedType == 'cash' ? 'cash_savings' : 'bank_savings',
                          isArchived: false,
                        );
                        DatabaseService().addTransaction(savingsTx);
                        Navigator.pop(c);
                        _showSnackBar('${getText('savings')} ${getText('save')}', Colors.blue);
                        setState(() {});
                      }
                    } else {
                      _showSnackBar(getText('amount_error'), Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  void _showIncomeDialog() {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selCat = 'salary';
    DateTime selectedDate = DateTime.now();

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
                Text(getText('add_income'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(context: c, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) s(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [const Icon(Icons.calendar_today, size: 18), const SizedBox(width: 10), Text('${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selectedDate)}')]),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: getText('amount'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)), autofocus: true),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, decoration: InputDecoration(labelText: getText('description'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.note))),
                const SizedBox(height: 12),
                Text(getText('select_category'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selCat,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: incomeCategories.map((cat) => DropdownMenuItem<String>(
                        value: cat['key'],
                        child: Row(children: [Icon(cat['icon'], size: 20, color: cat['color']), const SizedBox(width: 10), Text(getCategoryName(cat['key']))]),
                      )).toList(),
                      onChanged: (v) { if (v != null) s(() => selCat = v); },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (amtCtrl.text.isNotEmpty) {
                      double? amt = double.tryParse(amtCtrl.text);
                      if (amt != null) {
                        DatabaseService().addTransaction(TransactionModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: amt,
                          note: noteCtrl.text.isEmpty ? getCategoryName(selCat) : noteCtrl.text,
                          type: 'Income',
                          date: DateFormat('dd/MM/yyyy hh:mm a').format(selectedDate),
                          category: selCat,
                          isArchived: false,
                        ));
                        Navigator.pop(c);
                        _showSnackBar('${getText('income')} ${getText('save')}', Colors.green);
                        setState(() {});
                      }
                    } else {
                      _showSnackBar(getText('amount_error'), Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                    DateTime? picked = await showDatePicker(context: c, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) s(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [const Icon(Icons.calendar_today, size: 18), const SizedBox(width: 10), Text('${getText('date')}: ${DateFormat('dd/MM/yyyy').format(selectedDate)}')]),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: getText('amount'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)), autofocus: true),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, decoration: InputDecoration(labelText: getText('description'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.note))),
                const SizedBox(height: 12),
                Text(getText('select_category'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selCat,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: expenseCategories.map((cat) => DropdownMenuItem<String>(
                        value: cat['key'],
                        child: Row(children: [Icon(cat['icon'], size: 20, color: cat['color']), const SizedBox(width: 10), Text(getCategoryName(cat['key']))]),
                      )).toList(),
                      onChanged: (v) { if (v != null) s(() => selCat = v); },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (amtCtrl.text.isNotEmpty) {
                      double? amt = double.tryParse(amtCtrl.text);
                      if (amt != null) {
                        DatabaseService().addTransaction(TransactionModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: amt,
                          note: noteCtrl.text.isEmpty ? getCategoryName(selCat) : noteCtrl.text,
                          type: 'Expense',
                          date: DateFormat('dd/MM/yyyy hh:mm a').format(selectedDate),
                          category: selCat,
                          isArchived: false,
                        ));
                        Navigator.pop(c);
                        _showSnackBar('${getText('expense')} ${getText('save')}', Colors.red);
                        setState(() {});
                      }
                    } else {
                      _showSnackBar(getText('amount_error'), Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  void _showSnackBar(String m, Color c) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating)); }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(getText('delete')),
        content: Text(getText('delete_confirm') ?? 'ডিলিট?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(getText('no'))),
          ElevatedButton(onPressed: () async {
            Navigator.pop(c);
            if (mounted) setState(() {
              _textNotes.removeWhere((note) => note['key'] == id);
              _drawingNotes.removeWhere((note) => note['key'] == id);
              _allReminders.removeWhere((r) => r['key'] == id);
            });
            await DatabaseService().deleteTransaction(id);
            _showSnackBar(getText('delete'), Colors.red);
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text(getText('yes'), style: const TextStyle(color: Colors.white))),
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
          ElevatedButton(onPressed: () async {
            Navigator.pop(c);
            if (mounted) setState(() {
              _textNotes.removeWhere((note) => note['key'] == id);
              _drawingNotes.removeWhere((note) => note['key'] == id);
            });
            await DatabaseService().archiveTransaction(id);
            _showSnackBar(getText('archive'), Colors.orange);
          }, child: Text(getText('yes'))),
        ],
      ),
    );
  }

  void _showTransactionOptions(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, width: 40, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(Icons.edit, color: Colors.blue)), title: Text(getText('edit'), style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(c); _showEditDialog(tx); }),
            ListTile(leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.1), child: Icon(Icons.archive, color: Colors.orange)), title: Text(getText('archive'), style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(c); _confirmArchive(tx['key']); }),
            ListTile(leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.1), child: Icon(Icons.delete, color: Colors.red)), title: Text(getText('delete'), style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(c); _confirmDelete(tx['key']); }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> tx) {
    final amtCtrl = TextEditingController(text: (tx['amount'] ?? '').toString());
    final noteCtrl = TextEditingController(text: tx['note'] ?? '');
    String type = tx['type'] ?? 'Income', catKey = tx['category'] ?? (type == 'Income' ? 'salary' : 'gas_bill');
    List<Map<String, dynamic>> cats = type == 'Income' ? incomeCategories : expenseCategories;
    if (!cats.any((c) => c['key'] == catKey)) catKey = type == 'Income' ? 'salary' : 'gas_bill';
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
                TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: getText('amount'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)), autofocus: true),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, decoration: InputDecoration(labelText: getText('description'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.note))),
                const SizedBox(height: 12),
                Text(getText('select_category'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: catKey,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: cats.map((cat) => DropdownMenuItem<String>(
                        value: cat['key'],
                        child: Row(children: [Icon(cat['icon'], size: 20, color: cat['color']), const SizedBox(width: 10), Text(getCategoryName(cat['key']))]),
                      )).toList(),
                      onChanged: (v) { if (v != null) s(() => catKey = v); },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (amtCtrl.text.isNotEmpty) {
                      double? amt = double.tryParse(amtCtrl.text);
                      if (amt != null) {
                        DatabaseService().updateTransaction(tx['key'], {
                          'amount': amt,
                          'note': noteCtrl.text.isEmpty ? getCategoryName(catKey) : noteCtrl.text,
                          'category': catKey,
                        });
                        Navigator.pop(c);
                        _showSnackBar('${getText('edit')} ${getText('save')}', Colors.green);
                        setState(() {});
                      }
                    } else {
                      _showSnackBar(getText('amount_error'), Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => SecurityScreen(selectedLanguage: _selectedLanguage, localizedText: _localizedText)));
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

  // ========== PROFILE & SETTINGS (FIXED SAVE BUTTON) ==========
  void _showProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, s) => Container(
          decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[850] : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(margin: const EdgeInsets.only(top: 12), height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _changeProfilePhoto(),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: _profileImagePath != null && File(_profileImagePath!).existsSync()
                            ? FileImage(File(_profileImagePath!))
                            : (FirebaseAuth.instance.currentUser?.photoURL != null && FirebaseAuth.instance.currentUser!.photoURL!.isNotEmpty
                            ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!) as ImageProvider
                            : null),
                        child: (_profileImagePath == null && (FirebaseAuth.instance.currentUser?.photoURL == null || FirebaseAuth.instance.currentUser!.photoURL!.isEmpty))
                            ? const Icon(Icons.person, size: 50, color: Colors.blue)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: (_profileImagePath != null && File(_profileImagePath!).existsSync()) ? 60 : 0,
                      child: const CircleAvatar(radius: 18, backgroundColor: Colors.blue, child: Icon(Icons.camera_alt, size: 18, color: Colors.white)),
                    ),
                    if (_profileImagePath != null && File(_profileImagePath!).existsSync())
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove('profile_pic_${user.uid}');
                              setState(() { _profileImagePath = null; });
                              s(() { _profileImagePath = null; });
                              _showSnackBar(getText('profile_pic_removed') ?? "প্রোফাইল পিকচার রিমুভ করা হয়েছে", Colors.red);
                            }
                          },
                          child: const CircleAvatar(radius: 18, backgroundColor: Colors.red, child: Icon(Icons.delete, size: 18, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: getText('user_name'), prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    onChanged: (v) => _userName = v,
                  ),
                ),
                const SizedBox(height: 10),
                Text(AuthService().currentUser?.email ?? "User", style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.white70 : Colors.grey[600])),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildSettingsCard(s),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () { Navigator.pop(c); _openSecurityScreen(); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade700]), borderRadius: BorderRadius.circular(15)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.security, color: Colors.white, size: 24), const SizedBox(width: 10), Text(getText('security_settings'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))]),
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () async {
                          await _saveUserSettings();
                          Navigator.pop(c);
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(getText('save'), style: const TextStyle(color: Colors.white, fontSize: 16)),
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

  Widget _buildSettingsCard(StateSetter s) {
    return Container(
      decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[800] : Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: _isDarkMode ? Colors.grey[700]! : Colors.grey[200]!)),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.brightness_6, size: 20, color: Colors.purple), const SizedBox(width: 10), Text(getText('dark_mode'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          SwitchListTile(value: _isDarkMode, onChanged: (v) => s(() => _isDarkMode = v), activeColor: Colors.purple, dense: true, contentPadding: EdgeInsets.zero),
          const Divider(),
          Row(children: [Icon(Icons.language, size: 20, color: Colors.blue), const SizedBox(width: 10), Text(getText('language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 8),
          Row(children: [_lc('বাংলা', 'bn', s), const SizedBox(width: 8), _lc('English', 'en', s), const SizedBox(width: 8), _lc('العربية', 'ar', s)]),
          const SizedBox(height: 15),
          Row(children: [Icon(Icons.currency_exchange, size: 20, color: Colors.green), const SizedBox(width: 10), Text(getText('currency'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [_cc('BDT', '৳', s), _cc('USD', '\$', s), _cc('EUR', '€', s), _cc('GBP', '£', s), _cc('INR', '₹', s)]),
          const SizedBox(height: 15),
          Row(children: [Icon(Icons.calendar_today, size: 20, color: Colors.orange), const SizedBox(width: 10), Text(getText('calendar_settings'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          SwitchListTile(title: Text(getText('show_hijri')), value: _showHijriDate, onChanged: (v) => s(() => _showHijriDate = v), activeColor: Colors.blue.shade700, dense: true, contentPadding: EdgeInsets.zero),
          SwitchListTile(title: Text(getText('show_bengali')), value: _showBengaliDate, onChanged: (v) => s(() => _showBengaliDate = v), activeColor: Colors.blue.shade700, dense: true, contentPadding: EdgeInsets.zero),
        ],
      ),
    );
  }

  Widget _lc(String l, String code, StateSetter s) {
    bool sel = _selectedLanguage == code;
    return Expanded(child: InkWell(onTap: () => s(() => _selectedLanguage = code), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: sel ? Colors.blue.shade700 : (_isDarkMode ? Colors.grey[800] : Colors.white), borderRadius: BorderRadius.circular(25), border: Border.all(color: sel ? Colors.blue.shade700 : (_isDarkMode ? Colors.grey[700]! : Colors.grey[300]!))), child: Center(child: Text(l, style: TextStyle(color: sel ? Colors.white : (_isDarkMode ? Colors.white : Colors.black87), fontWeight: FontWeight.w500))))));
  }

  Widget _cc(String code, String sym, StateSetter s) {
    bool sel = _selectedCurrency == code;
    return InkWell(onTap: () => s(() => _selectedCurrency = code), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: sel ? Colors.blue.shade700 : (_isDarkMode ? Colors.grey[800] : Colors.white), borderRadius: BorderRadius.circular(25), border: Border.all(color: sel ? Colors.blue.shade700 : (_isDarkMode ? Colors.grey[700]! : Colors.grey[300]!))), child: Text('$code ($sym)', style: TextStyle(color: sel ? Colors.white : (_isDarkMode ? Colors.white : Colors.black87)))));
  }

  void _changeProfilePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_pic_${user.uid}', picked.path);
        if (mounted) setState(() => _profileImagePath = picked.path);
      }
    }
  }

  // ==================== NOTEBOOK IMPLEMENTATION (FULL with localisation) ====================
  Widget _buildTextNotesList() {
    if (_textNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(getText('no_notes')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _textNotes.length,
      itemBuilder: (c, i) {
        final note = _textNotes[i];
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
      },
    );
  }

  Widget _buildDrawingNotesList() {
    if (_drawingNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.brush, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(getText('no_drawing')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _drawingNotes.length,
      itemBuilder: (c, i) {
        final noteData = _drawingNotes[i];
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
      },
    );
  }

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
                Container(padding: const EdgeInsets.only(top: 40, left: 8, right: 8, bottom: 8), child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.check, color: Colors.green, size: 32), onPressed: () async {
                      if (tc.text.trim().isEmpty) { _showSnackBar(getText('write_note_hint'), Colors.red); return; }
                      Map<String, dynamic> extra = {'bgColor': selBg.value, 'imagePaths': existingImages, 'hasDrawing': false};
                      final newNote = TransactionModel(
                        id: key ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        amount: 0, note: tc.text, type: "Note", category: json.encode(extra),
                        date: DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()), isArchived: false,
                      );
                      _isNoteEditorOpen = false;
                      Navigator.of(context).pop();
                      await DatabaseService().addTransaction(newNote);
                      final newNoteMap = {'key': newNote.id, 'note': newNote.note, 'date': newNote.date, 'category': newNote.category};
                      if (mounted) setState(() => _textNotes.insert(0, newNoteMap));
                      _showSnackBar(getText('save'), Colors.green);
                    }),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(getText('editing'), style: const TextStyle(color: Colors.black54, fontSize: 14)),
                      Text(DateFormat('dd/MM/yy h:mm a').format(DateTime.now()), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ])),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      onSelected: (value) { if (value == 'close') { _isNoteEditorOpen = false; Navigator.pop(context); } },
                      itemBuilder: (context) => [PopupMenuItem(value: 'close', child: Row(children: [const Icon(Icons.close, color: Colors.red, size: 20), const SizedBox(width: 8), Text(getText('close'))]))],
                    ),
                  ],
                )),
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
                              decoration: InputDecoration(hintText: getText('write_note_hint'), hintStyle: const TextStyle(color: Colors.black38), border: InputBorder.none, filled: false),
                            ),
                            if (existingImages.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: existingImages.map((path) => Stack(
                                    children: [
                                      Padding(padding: const EdgeInsets.only(right: 8.0), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), height: 100, width: 100, fit: BoxFit.cover))),
                                      Positioned(top: 0, right: 8, child: GestureDetector(
                                        onTap: () => s(() => existingImages.remove(path)),
                                        child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                                      )),
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
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        TextButton.icon(onPressed: () async { final picked = await _imagePicker.pickImage(source: ImageSource.gallery); if (picked != null) s(() => existingImages.add(picked.path)); }, icon: const Icon(Icons.photo_library, size: 20), label: Text(getText('gallery'))),
                        const SizedBox(width: 20),
                        TextButton.icon(onPressed: () async { final picked = await _imagePicker.pickImage(source: ImageSource.camera); if (picked != null) s(() => existingImages.add(picked.path)); }, icon: const Icon(Icons.camera_alt, size: 20), label: Text(getText('camera'))),
                      ]),
                      SizedBox(height: 50, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: bgs.length, itemBuilder: (c, i) => GestureDetector(
                        onTap: () => s(() { selBg = bgs[i]; selectedBg = bgs[i].value; }),
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: CircleAvatar(backgroundColor: bgs[i], radius: 18, child: selBg == bgs[i] ? const Icon(Icons.check, color: Colors.black54, size: 18) : null)),
                      ))),
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
                        await DatabaseService().addTransaction(newNote);
                        final newNoteMap = {'key': newNote.id, 'note': newNote.note, 'date': newNote.date, 'category': newNote.category};
                        if (mounted) setState(() => _drawingNotes.insert(0, newNoteMap));
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

  // ========== MAIN BUILD METHOD (responsive app bar, dark mode, greeting icon) ==========
  @override
  Widget build(BuildContext context) {
    final bool isDark = _isDarkMode;

    return MaterialApp(
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),

        // ==================== PREMIUM APP BAR ====================
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(85),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF1E40AF), const Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 360;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ========== বাম পাশের অংশ (প্রোফাইল ছবি + গ্রিটিং + নাম) ==========
                        GestureDetector(
                          onTap: () => setState(() => _currentIndex = 4),
                          child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white54, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ]),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white24,
                              child: () {
                                if (_localProfilePicPath != null &&
                                    _localProfilePicPath!.isNotEmpty) {
                                  final file = File(_localProfilePicPath!);
                                  if (file.existsSync()) {
                                    return ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.file(file,
                                            width: 40, height: 40, fit: BoxFit.cover));
                                  }
                                }
                                final googlePhotoUrl =
                                    FirebaseAuth.instance.currentUser?.photoURL;
                                if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
                                  return ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        googlePhotoUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.person,
                                            color: Colors.white, size: 22),
                                      ));
                                }
                                return const Icon(Icons.person,
                                    color: Colors.white, size: 22);
                              }(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // গ্রিটিং ও নামের কলাম (এটিকে Expanded না দিয়ে নির্দিষ্ট জায়গা দিন)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(_getGreetingIcon(),
                                    color: Colors.amberAccent, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  _getCurrentGreeting(),
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              width: isSmall ? 90 : 110,
                              child: Text(
                                _userName.isNotEmpty ? _userName : getText('user_name'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        // ========== মাঝখানের অংশ (অ্যাপ টাইটেল – সেন্টারড) ==========
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    getText('app_title'),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: isSmall ? 16 : 18,
                                        letterSpacing: 0.5,
                                        shadows: const [
                                          Shadow(
                                              color: Colors.black26,
                                              offset: Offset(0, 2),
                                              blurRadius: 4)
                                        ]),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                StreamBuilder<bool>(
                                  stream: _connectionStream,
                                  builder: (context, snapshot) {
                                    bool isOnline = snapshot.data ?? false;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isOnline
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isOnline
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444))
                                                  .withOpacity(0.6),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            )
                                          ]),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ========== ডান পাশের অংশ (লগআউট বাটন) ==========
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white, size: 18),
                            onPressed: () async {
                              setState(() => _localProfilePicPath = null);
                              await AuthService().signOut();
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // ==================== FAB & BODY ====================
        floatingActionButton: FloatingActionButton(
            elevation: 6,
            backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8),
            onPressed: _openCalculator,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 28)
        ),

        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildMainBody(),
            _buildCalendarBody(),
            _buildNoticeBody(),
            _buildNotebookBody(),
            _buildProfileBody(),
          ],
        ),

        // ==================== PREMIUM BOTTOM NAVIGATION BAR ====================
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedItemColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
            unselectedItemColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.2),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11), // এখানে পরিবর্তন করা হয়েছে (medium ফিক্সড)
            onTap: (i) => setState(() => _currentIndex = i),
            items: [
              BottomNavigationBarItem(
                  icon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
                  activeIcon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
                  label: getText('home')
              ),
              BottomNavigationBarItem(
                  icon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.calendar_month_outlined)),
                  activeIcon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.calendar_month_rounded)),
                  label: getText('calendar')
              ),
              BottomNavigationBarItem(
                  icon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.notifications_none_rounded)),
                  activeIcon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.notifications_rounded)),
                  label: getText('notice')
              ),
              BottomNavigationBarItem(
                  icon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.book_outlined)),
                  activeIcon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.book_rounded)),
                  label: getText('notebook')
              ),
              BottomNavigationBarItem(
                  icon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline_rounded)),
                  activeIcon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
                  label: getText('profile')
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MAIN BODY (without weather)
  Widget _buildMainBody() {
    String symbol = _currencySymbols[_selectedCurrency] ?? '৳';
    return StreamBuilder<List<TransactionModel>>(
      stream: DatabaseService().transactionsStream,
      builder: (context, snap) {
        double inc = 0, exp = 0, sav = 0, dbt = 0, crd = 0;
        List<Map<String, dynamic>> firebaseList = [];
        Map<DateTime, List<Map<String, dynamic>>> newEvents = {};
        List<Map<String, dynamic>> reminders = [];
        List<Map<String, dynamic>> textNotes = [];
        List<Map<String, dynamic>> drawingNotes = [];

        if (snap.hasData) {
          final transactions = snap.data!;
          for (var tx in transactions) {
            final Map<String, dynamic> txMap = tx.toMap();
            txMap['key'] = tx.id;
            if (tx.type == 'Reminder' && !(txMap['isArchived'] ?? false) && (txMap['completed'] != true)) {
              String dateStr = txMap['date'] ?? '';
              String timeStr = txMap['time'] ?? '12:00 AM';
              if (dateStr.isNotEmpty) {
                try {
                  DateTime date = DateFormat('dd/MM/yyyy').parse(dateStr);
                  newEvents.putIfAbsent(date, () => []);
                  newEvents[date]!.add({'key': tx.id, 'note': tx.note ?? '', 'time': timeStr, 'completed': txMap['completed'] ?? false});
                  reminders.add({'key': tx.id, 'note': tx.note ?? '', 'date': dateStr, 'time': timeStr, 'completed': txMap['completed'] ?? false});
                } catch (_) {}
              }
            }
            if (tx.type == 'Note' && !(txMap['isArchived'] ?? false)) {
              bool hasDrawing = false;
              String category = tx.category ?? '';
              if (category.startsWith('{')) {
                try {
                  Map<String, dynamic> extra = json.decode(category);
                  hasDrawing = extra['hasDrawing'] == true;
                } catch (_) {}
              }
              Map<String, dynamic> noteMap = {'key': tx.id, 'note': tx.note ?? '', 'date': tx.date ?? '', 'category': category};
              if (hasDrawing) drawingNotes.add(noteMap);
              else textNotes.add(noteMap);
            }
            if (tx.type != 'Note' && tx.type != 'Reminder' && !(txMap['isArchived'] ?? false)) {
              firebaseList.add(txMap);
            }
          }
          firebaseList.sort((a, b) => (b['id'] ?? b['key']).compareTo((a['id'] ?? a['key'])));
        }
        final offlineTxs = OfflineService.getOfflineTransactions();
        List<Map<String, dynamic>> offlineList = offlineTxs.map((tx) => {
          'key': tx.id, 'id': tx.id, 'amount': tx.amount, 'note': tx.note,
          'type': tx.type, 'date': tx.date, 'category': tx.category, 'isArchived': tx.isArchived,
        }).toList();
        List<Map<String, dynamic>> allList = [...firebaseList, ...offlineList];
        allList.sort((a, b) => (b['id'] ?? b['key']).compareTo((a['id'] ?? a['key'])));
        inc = exp = sav = dbt = crd = 0;
        for (var tx in allList) {
          double amt = tx['amount'] ?? 0;
          String type = tx['type'] ?? '';
          if (type == 'Income') inc += amt;
          else if (type == 'Expense') exp += amt;
          else if (type == 'Savings') sav += amt;
          else if (type == 'Debt') dbt += amt;
          else if (type == 'Credit') crd += amt;
        }
        if (_events.length != newEvents.length || _allReminders.length != reminders.length || _textNotes.length != textNotes.length || _drawingNotes.length != drawingNotes.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {
              _events = newEvents;
              _allReminders = reminders;
              _textNotes = textNotes;
              _drawingNotes = drawingNotes;
            });
          });
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
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
                _buildTransactionHistory(allList, symbol),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // UI COMPONENTS (unchanged but with dark mode support)
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
  Widget _buildGradientCard(String label, double value, Color color, IconData icon, String symbol) => AnimatedBorderCard(baseColor: color, child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(height: 2), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)), const SizedBox(height: 1), Text("$symbol ${value.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))])));
  Widget _buildProfessionalActionButtons() => Row(children: [Expanded(child: _buildGradientButton(getText('income'), Icons.add, Colors.green, _showIncomeDialog)), const SizedBox(width: 12), Expanded(child: _buildGradientButton(getText('expense'), Icons.remove, Colors.red, _showExpenseDialog))]);
  Widget _buildGradientButton(String label, IconData icon, Color color, VoidCallback onPressed) => Expanded(child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.transparent, elevation: 0, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), minimumSize: const Size(0, 52)), child: Ink(decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(30)), child: Container(alignment: Alignment.center, height: 52, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 24), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))])))));
  Widget _buildProfessionalSectionTitle(String title, IconData icon) => Row(children: [Icon(icon, color: Colors.blue.shade700, size: 22), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _isDarkMode ? Colors.white : Colors.blueGrey.shade800))]);
  Widget _buildProfessionalDashboardStatsGrid() => Row(children: [_buildStatCard(Icons.today, getText('daily'), Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DailyStatsScreen(selectedLanguage: _selectedLanguage, localizedText: _localizedText)))), const SizedBox(width: 12), _buildStatCard(Icons.calendar_month, getText('monthly'), Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonthlyStatsScreen(selectedLanguage: _selectedLanguage, localizedText: _localizedText)))), const SizedBox(width: 12), _buildStatCard(Icons.history, getText('yearly'), Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => YearlyStatsScreen(selectedLanguage: _selectedLanguage, localizedText: _localizedText))))]);
  Widget _buildStatCard(IconData icon, String label, Color color, VoidCallback onTap) => Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), child: Column(children: [Icon(icon, color: color, size: 30), const SizedBox(height: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14))]))));
  Widget _buildProfessionalOtherAccountsGrid() => Row(children: [_buildOtherAccountCard(Icons.money_off, getText('debt'), Colors.deepOrange, () => _showDebtCreditDialog("দেনা")), const SizedBox(width: 12), _buildOtherAccountCard(Icons.attach_money, getText('credit'), Colors.deepPurple, () => _showDebtCreditDialog("পাওনা")), const SizedBox(width: 12), _buildOtherAccountCard(Icons.savings, getText('savings'), Colors.blue, () => _showSavingsDialog())]);
  Widget _buildOtherAccountCard(IconData icon, String label, Color color, VoidCallback onTap) => Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), child: Column(children: [Icon(icon, color: color, size: 30), const SizedBox(height: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14))]))));
  Widget _buildFeatureButtonsRow() => Row(children: [Expanded(child: _buildFeatureButton(getText('budget_management'), Icons.account_balance_wallet, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetScreen(selectedLanguage: _selectedLanguage, localizedText: _localizedText))))), const SizedBox(width: 12), Expanded(child: _buildFeatureButton(getText('recurring_transactions'), Icons.repeat, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecurringScreen(selectedLanguage: _selectedLanguage, localizedText: _localizedText, incomeCategories: incomeCategories, expenseCategories: expenseCategories))))), const SizedBox(width: 12), Expanded(child: _buildFeatureButton(getText('export_report'), Icons.download, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExportScreen(selectedLanguage: _selectedLanguage, selectedCurrency: _selectedCurrency, currencySymbol: _currencySymbols[_selectedCurrency] ?? '৳', localizedText: _localizedText)))))]);
  Widget _buildFeatureButton(String label, IconData icon, Color color, VoidCallback onTap) => ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: color, elevation: 2, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 20), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))]));
  Widget _buildTransactionHistory(List<Map<String, dynamic>> list, String symbol) {
    if (list.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(getText('no_transactions'), style: TextStyle(fontSize: 16, color: _isDarkMode ? Colors.grey[400] : Colors.grey))));
    return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: list.length, itemBuilder: (context, i) {
      final tx = list[i];
      final bool isInc = tx['type'] == 'Income';
      final Color ac = isInc ? Colors.green : Colors.red;
      double amt = 0.0; var raw = tx['amount']; if (raw is double) amt = raw; else if (raw is int) amt = raw.toDouble(); else if (raw is String) amt = double.tryParse(raw) ?? 0.0;
      return Card(margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6), elevation: 1.5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: _isDarkMode ? Colors.grey[850] : Colors.white, child: ListTile(
        leading: CircleAvatar(backgroundColor: ac.withOpacity(0.15), child: Icon(isInc ? Icons.arrow_downward : Icons.arrow_upward, color: ac)),
        title: Text(tx['note'] ?? "", style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text("${getCategoryName(tx['category'] ?? 'other')} • ${tx['date'] ?? ""}", style: TextStyle(fontSize: 11, color: _isDarkMode ? Colors.grey[400] : Colors.grey)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text("$symbol ${amt.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ac)), const SizedBox(width: 12), Icon(Icons.more_vert, color: Colors.grey)]),
        onTap: () => _showTransactionOptions(tx),
      ));
    });
  }
  Widget _buildBudgetOverviewCard() {
    String cm = DateFormat('yyyy-MM').format(DateTime.now());
    return FutureBuilder<Map<String, dynamic>>(future: DatabaseService().getBudgetSummary(cm), builder: (context, snap) {
      if (!snap.hasData) return const SizedBox.shrink();
      double tb = (snap.data!['totalBudget'] ?? 0).toDouble();
      double ts = (snap.data!['totalSpent'] ?? 0).toDouble();
      double p = (snap.data!['percentage'] ?? 0).toDouble();
      if (tb == 0) return const SizedBox.shrink();
      Color sc = p >= 100 ? Colors.red : p >= 80 ? Colors.orange : Colors.teal;
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetScreen(selectedLanguage: _selectedLanguage, localizedText: _localizedText))),
        child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [sc.withOpacity(0.8), sc]), borderRadius: BorderRadius.circular(20)), child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24), const SizedBox(width: 10), Text(getText('monthly_budget'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]), const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('৳ ${ts.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text(getText('budget_spent'), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12))]), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('৳ ${tb.toStringAsFixed(0)}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18)), Text(getText('total_budget'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12))])]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: p / 100, backgroundColor: Colors.white.withOpacity(0.3), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 8)),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${p.toStringAsFixed(1)}% ${getText('used')}', style: const TextStyle(color: Colors.white, fontSize: 12)), Text('${getText('remaining')}: ৳ ${(tb - ts).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 12))]),
            if (p >= 100) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.warning, color: Colors.white, size: 18), const SizedBox(width: 5), Text('${getText('budget_exceeded')}!', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))])),
          ],
        )),
      );
    });
  }
  Widget _buildCalendarBody() {
    DateTime sd = _selectedDay ?? DateTime.now(); String? holiday = BDHolidays.getHoliday(sd);
    return Column(children: [Expanded(child: SingleChildScrollView(child: Column(children: [
      const SizedBox(height: 10), Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[800] : Colors.white, borderRadius: BorderRadius.circular(24)), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: TableCalendar(firstDay: DateTime(2020), lastDay: DateTime(2030), focusedDay: _focusedDay, selectedDayPredicate: (d) => isSameDay(_selectedDay, d), onDaySelected: (sd2, fd) { if (mounted) setState(() { _selectedDay = sd2; _focusedDay = fd; }); }, calendarFormat: _calendarFormat, onFormatChanged: (f) { if (mounted) setState(() => _calendarFormat = f); }, calendarStyle: CalendarStyle(selectedDecoration: BoxDecoration(color: Colors.blue.shade700, shape: BoxShape.circle), todayDecoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle), weekendTextStyle: const TextStyle(color: Colors.red)), headerStyle: const HeaderStyle(formatButtonVisible: true, titleCentered: true, titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)), daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(fontWeight: FontWeight.bold), weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), eventLoader: (d) => _events[d] ?? []))),
      _buildDateInfoCard(), if (holiday != null) Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.celebration, color: Colors.red), const SizedBox(width: 10), Expanded(child: Text('${getText('government_holiday')}: $holiday', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)))])),
      const SizedBox(height: 10), _buildAddReminderButton(), if (_events[sd]?.isEmpty ?? true) Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(30), child: Column(children: [Icon(Icons.event_busy, size: 60, color: Colors.grey[400]), const SizedBox(height: 10), Text(getText('no_reminders'))])), const SizedBox(height: 80),
    ])))]);
  }
  Widget _buildDateInfoCard() {
    DateTime sd = _selectedDay ?? DateTime.now();
    return Container(margin: const EdgeInsets.symmetric(horizontal: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.purple.shade600]), borderRadius: BorderRadius.circular(20)), child: Column(children: [Row(children: [const Icon(Icons.calendar_today, color: Colors.white), const SizedBox(width: 10), Text(DateFormat('EEEE, d MMMM yyyy').format(sd), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]), if (_showBengaliDate) ...[const SizedBox(height: 8), Row(children: [const Icon(Icons.calendar_month, color: Colors.white, size: 18), const SizedBox(width: 10), Text('বাংলা: ${BengaliCalendar.getBengaliDate(sd)}, ${BengaliCalendar.getBengaliDay(sd.weekday)}', style: const TextStyle(color: Colors.white))])], if (_showHijriDate) ...[const SizedBox(height: 8), Row(children: [const Icon(Icons.calendar_view_month, color: Colors.white, size: 18), const SizedBox(width: 10), Text('হিজরি: ${HijriCalendar.getHijriDate(sd)}', style: const TextStyle(color: Colors.white))])]]));
  }
  Widget _buildAddReminderButton() => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: ElevatedButton.icon(onPressed: _showReminderInput, icon: const Icon(Icons.add_alert), label: Text(getText('add_reminder')), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5)));
  Widget _buildNoticeBody() {
    if (_allReminders.isEmpty) return Center(child: Text(getText('no_notices'), style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54)));
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _allReminders.length,
      itemBuilder: (c, i) {
        final reminder = _allReminders[i];
        final DateTime targetDate = DateFormat('dd/MM/yyyy').parse(reminder['date']);
        final TimeOfDay targetTime = _parseTimeOfDay(reminder['time']);
        final DateTime targetDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, targetTime.hour, targetTime.minute);
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
                Text(timeLeftText, style: TextStyle(color: isOverdue ? Colors.red : Colors.green, fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _editReminder(reminder['key'], reminder['note'], reminder['date'], reminder['time'])),
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _markReminderDone(reminder['key'])),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(reminder['key'])),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildProfileBody() {
    String cs = _currencySymbols[_selectedCurrency] ?? '৳';
    String ln = _selectedLanguage == 'bn' ? 'বাংলা' : (_selectedLanguage == 'ar' ? 'العربية' : 'English');
    return Center(child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 40),
      GestureDetector(onTap: _changeProfilePhoto, child: Stack(children: [
        CircleAvatar(radius: 50, backgroundColor: Colors.blue.shade100, backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null, child: _profileImagePath == null ? const Icon(Icons.person, size: 50, color: Colors.blue) : null),
        Positioned(bottom: 0, right: 0, child: const CircleAvatar(radius: 18, backgroundColor: Colors.blue, child: Icon(Icons.camera_alt, size: 18, color: Colors.white))),
      ])),
      const SizedBox(height: 16),
      Text(_userName.isNotEmpty ? _userName : "User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87)),
      const SizedBox(height: 5),
      Text(AuthService().currentUser?.email ?? "", style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.white70 : Colors.grey[600])),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[800] : Colors.grey[100], borderRadius: BorderRadius.circular(25)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.language, size: 18, color: Colors.blue), const SizedBox(width: 8), Text(ln, style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)), const SizedBox(width: 20), const Icon(Icons.currency_exchange, size: 18, color: Colors.green), const SizedBox(width: 8), Text("$_selectedCurrency ($cs)", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87))])),
      const SizedBox(height: 30),
      ElevatedButton.icon(onPressed: _showProfileDialog, icon: const Icon(Icons.settings), label: Text(getText('change_settings')), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 3)),
      const SizedBox(height: 15),
      ElevatedButton.icon(onPressed: _openSecurityScreen, icon: const Icon(Icons.security), label: Text(getText('security_settings')), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 3)),
      const SizedBox(height: 15),
      ElevatedButton.icon(onPressed: () => AuthService().signOut(), icon: const Icon(Icons.logout), label: Text(getText('logout')), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 3)),
      const SizedBox(height: 50),
    ])));
  }
}

// ==================== HELPER CLASSES ====================
class AnimatedBorderCard extends StatefulWidget {
  final Widget child; final Color baseColor;
  const AnimatedBorderCard({super.key, required this.child, required this.baseColor});
  @override State<AnimatedBorderCard> createState() => _AnimatedBorderCardState();
}
class _AnimatedBorderCardState extends State<AnimatedBorderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _animation;
  @override void initState() { super.initState(); _controller = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(reverse: true); _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _animation, builder: (context, _) { final opacity = 0.3 + (_animation.value * 0.4); final borderWidth = 1.5 + (_animation.value * 1.5); return Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [widget.baseColor.withOpacity(0.9), widget.baseColor]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: widget.baseColor.withOpacity(opacity), blurRadius: 12 + (_animation.value * 8), offset: Offset(0, 4 + (_animation.value * 4)))], border: Border.all(color: widget.baseColor.withOpacity(0.8), width: borderWidth)), child: widget.child); });
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
      final paint = Paint()
        ..color = strokeColors[i]
        ..strokeWidth = strokeWidths[i]
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
        oldDelegate.strokeWidths != strokeWidths;
  }
}
class NotepadLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) { final paint = Paint()..color = Colors.black26..strokeWidth = 1.0; const double lineHeight = 30.0; int lines = (size.height / lineHeight).ceil(); for (int i = 1; i <= lines; i++) { double y = i * lineHeight; canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); } }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}