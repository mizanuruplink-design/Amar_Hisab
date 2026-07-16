import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/local_database_service.dart';
import '../services/notification_service.dart';

class EntryScreen extends StatefulWidget {
  final String selectedLanguage;
  final Map<String, Map<String, String>> localizedText;

  const EntryScreen({
    super.key,
    required this.selectedLanguage,
    required this.localizedText,
  });

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final LocalDatabaseService _db = LocalDatabaseService();

  String _selectedType = 'Expense';
  DateTime _selectedDate = DateTime.now();
  DateTime? _reminderDateTime;
  int _selectedColor = 0xFF009688;

  final List<int> _noteColors = [
    0xFF009688, // Teal
    0xFFFF8A80, // Light Red
    0xFF80D8FF, // Light Blue
    0xFFFFFF8D, // Yellow
    0xFFCCFF90, // Light Green
    0xFFCFD8DC, // Blue Grey
  ];

  // ==================== DIGIT CONVERSION HELPERS ====================
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
    if (widget.selectedLanguage == 'bn') {
      target = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    } else if (widget.selectedLanguage == 'ar') {
      target = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    } else {
      return input;
    }
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], target[i]);
    }
    return input;
  }

  // ==================== LOCALIZATION ====================
  String getText(String key) {
    final translated = widget.localizedText[widget.selectedLanguage]?[key];
    if (translated != null && translated.isNotEmpty) return translated;

    // Fallback (for keys used in this screen)
    switch (key) {
      case 'new_entry':
        if (widget.selectedLanguage == 'bn') return 'নতুন এন্ট্রি';
        if (widget.selectedLanguage == 'ar') return 'إدخال جديد';
        return 'New Entry';
      case 'income':
        if (widget.selectedLanguage == 'bn') return 'জমা';
        if (widget.selectedLanguage == 'ar') return 'دخل';
        return 'Income';
      case 'expense':
        if (widget.selectedLanguage == 'bn') return 'খরচ';
        if (widget.selectedLanguage == 'ar') return 'مصروف';
        return 'Expense';
      case 'debt':
        if (widget.selectedLanguage == 'bn') return 'দেনা';
        if (widget.selectedLanguage == 'ar') return 'دين';
        return 'Debt';
      case 'note':
        if (widget.selectedLanguage == 'bn') return 'নোট';
        if (widget.selectedLanguage == 'ar') return 'ملاحظة';
        return 'Note';
      case 'amount':
        if (widget.selectedLanguage == 'bn') return 'টাকার পরিমাণ';
        if (widget.selectedLanguage == 'ar') return 'المبلغ';
        return 'Amount';
      case 'title':
        if (widget.selectedLanguage == 'bn') return 'শিরোনাম';
        if (widget.selectedLanguage == 'ar') return 'العنوان';
        return 'Title';
      case 'note_title_hint':
        if (widget.selectedLanguage == 'bn') return 'নোট বা মিটিংয়ের শিরোনাম';
        if (widget.selectedLanguage == 'ar') return 'عنوان الملاحظة أو الاجتماع';
        return 'Note or meeting title';
      case 'choose_note_color':
        if (widget.selectedLanguage == 'bn') return 'নোটের কালার পছন্দ করুন:';
        if (widget.selectedLanguage == 'ar') return 'اختر لون الملاحظة:';
        return 'Choose note color:';
      case 'set_date_time':
        if (widget.selectedLanguage == 'bn') return 'তারিখ ও সময় সেট করুন';
        if (widget.selectedLanguage == 'ar') return 'حدد التاريخ والوقت';
        return 'Set date & time';
      case 'note_details':
        if (widget.selectedLanguage == 'bn') return 'নোটের বিস্তারিত...';
        if (widget.selectedLanguage == 'ar') return 'تفاصيل الملاحظة...';
        return 'Note details...';
      case 'transaction_details':
        if (widget.selectedLanguage == 'bn') return 'লেনদেনের বিবরণ...';
        if (widget.selectedLanguage == 'ar') return 'تفاصيل المعاملة...';
        return 'Transaction details...';
      case 'save_all':
        if (widget.selectedLanguage == 'bn') return 'সব তথ্য সেভ করুন';
        if (widget.selectedLanguage == 'ar') return 'حفظ جميع البيانات';
        return 'Save all';
      case 'enter_amount':
        if (widget.selectedLanguage == 'bn') return 'টাকার পরিমাণ লিখুন';
        if (widget.selectedLanguage == 'ar') return 'أدخل المبلغ';
        return 'Enter amount';
      case 'enter_title':
        if (widget.selectedLanguage == 'bn') return 'নোটের টাইটেল লিখুন';
        if (widget.selectedLanguage == 'ar') return 'أدخل عنوان الملاحظة';
        return 'Enter note title';
      case 'saved_successfully':
        if (widget.selectedLanguage == 'bn') return 'সফলভাবে সেভ হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تم الحفظ بنجاح';
        return 'Saved successfully';
      case 'debt_reminder_title':
        if (widget.selectedLanguage == 'bn') return 'টাকা ফেরতের রিমাইন্ডার';
        if (widget.selectedLanguage == 'ar') return 'تذكير بإعادة المال';
        return 'Debt repayment reminder';
      case 'note_reminder_title':
        if (widget.selectedLanguage == 'bn') return 'নোট রিমাইন্ডার';
        if (widget.selectedLanguage == 'ar') return 'تذكير الملاحظة';
        return 'Note reminder';
      case 'transaction_reminder_title':
        if (widget.selectedLanguage == 'bn') return 'লেনদেন রিমাইন্ডার';
        if (widget.selectedLanguage == 'ar') return 'تذكير المعاملة';
        return 'Transaction reminder';
      case 'you_have_reminder':
        if (widget.selectedLanguage == 'bn') return 'আপনার একটি রিমাইন্ডার আছে';
        if (widget.selectedLanguage == 'ar') return 'لديك تذكير';
        return 'You have a reminder';
      default:
        return widget.localizedText['bn']?[key] ?? key;
    }
  }

  // ==================== DATE/TIME PICKER (locale removed, now uses screen-wide locale) ====================
  Future<void> _pickDateTime() async {
    // Locale is now set via Localizations.override wrapping the Scaffold,
    // so we don't need to pass it explicitly.
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _reminderDateTime = DateTime(
            date.year, date.month, date.day, time.hour, time.minute,
          );
          _selectedDate = date;
        });
      }
    }
  }

  // ==================== SAVE LOGIC ====================
  void _saveEntry() async {
    if (_selectedType != 'Note' && _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getText('enter_amount'))),
      );
      return;
    }

    if (_selectedType == 'Note' && _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getText('enter_title'))),
      );
      return;
    }

    try {
      if (_selectedType != 'Note') {
        final rawAmount = _convertToEnglishDigits(_amountController.text);
        final amount = double.tryParse(rawAmount) ?? 0;

        final tx = TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount,
          type: _selectedType,
          category: "General",
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          note: _noteController.text.isEmpty ? _selectedType : _noteController.text,
          refundDate: _reminderDateTime?.toString(),
          isPaid: false,
        );
        await _db.addTransaction(tx);
      } else {
        // Save note as TransactionModel with type 'Note'
        final noteTx = TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: 0,
          note: _titleController.text,
          type: 'Note',
          date: DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()),
          category: jsonEncode({
            'content': _noteController.text,
            'colorValue': _selectedColor,
            'reminderTime': _reminderDateTime?.toString(),
          }),
          isArchived: false,
        );
        await _db.addTransaction(noteTx);
      }

      if (_reminderDateTime != null) {
        String notificationTitle = "";
        if (_selectedType == 'Debt') {
          notificationTitle = getText('debt_reminder_title');
        } else if (_selectedType == 'Note') {
          notificationTitle = "${getText('note_reminder_title')}: ${_titleController.text}";
        } else {
          notificationTitle = getText('transaction_reminder_title');
        }

        await NotificationService.scheduleReminder(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          notificationTitle,
          _noteController.text.isEmpty ? getText('you_have_reminder') : _noteController.text,
          _reminderDateTime!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getText('saved_successfully'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    // 🔥 পুরো Scaffold কে Localizations.override দিয়ে মোড়ানো হয়েছে
    // যাতে showDatePicker ও showTimePicker স্বয়ংক্রিয়ভাবে সিলেক্টেড ভাষায় দেখায়
    return Localizations.override(
      context: context,
      locale: Locale(widget.selectedLanguage),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "${getText('new_entry')} ${_selectedType == 'Income' ? getText('income') : _selectedType == 'Expense' ? getText('expense') : _selectedType == 'Debt' ? getText('debt') : getText('note')}",
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Type selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'Income', label: Text(getText('income'))),
                    ButtonSegment(value: 'Expense', label: Text(getText('expense'))),
                    ButtonSegment(value: 'Debt', label: Text(getText('debt'))),
                    ButtonSegment(value: 'Note', label: Text(getText('note'))),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (val) => setState(() => _selectedType = val.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Colors.teal,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Amount field (digit conversion)
              if (_selectedType != 'Note')
                TextField(
                  controller: _amountController,
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: getText('amount'),
                    prefixText: "৳ ",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),

              if (_selectedType == 'Note')
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: getText('title'),
                    hintText: getText('note_title_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

              const SizedBox(height: 20),

              // Note color picker
              if (_selectedType == 'Note') ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    getText('choose_note_color'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _noteColors.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = _noteColors[index]),
                      child: Container(
                        width: 45,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Color(_noteColors[index]),
                          shape: BoxShape.circle,
                          border: _selectedColor == _noteColors[index]
                              ? Border.all(color: Colors.black, width: 3)
                              : Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Date/time picker tile
              ListTile(
                tileColor: Colors.teal.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.calendar_today, color: Colors.teal),
                trailing: const Icon(Icons.access_time, color: Colors.teal),
                title: Text(
                  _reminderDateTime == null
                      ? getText('set_date_time')
                      : DateFormat('dd MMMM, yyyy - hh:mm a').format(_reminderDateTime!),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: _pickDateTime,
              ),

              const SizedBox(height: 20),

              // Note/description
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _selectedType == 'Note'
                      ? getText('note_details')
                      : getText('transaction_details'),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 35),

              // Save button
              ElevatedButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.save),
                label: Text(
                  getText('save_all'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}