import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/local_database_service.dart';
import '../models/recurring_transaction_model.dart';
import '../services/category_service.dart';
import '../widgets/category_dropdown.dart';

class RecurringScreen extends StatefulWidget {
  final String selectedLanguage;
  final Map<String, Map<String, String>> localizedText;

  const RecurringScreen({
    super.key,
    required this.selectedLanguage,
    required this.localizedText,
  });

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final LocalDatabaseService _db = LocalDatabaseService();
  final CategoryService _categoryService = CategoryService();

  // ==================== DIGIT CONVERSION ====================
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

  String _formatAmount(double amount) {
    String formatted = amount.toStringAsFixed(0);
    return _convertToScriptDigits(formatted);
  }

  // ==================== HELPERS ====================
  IconData _getCategoryIcon(String categoryKey, String type) {
    final allCats = _categoryService.allCategories;
    final matching = allCats.where((c) => c['key'] == categoryKey).toList();
    if (matching.isNotEmpty) {
      return matching.first['icon'] as IconData? ?? Icons.category;
    }
    return Icons.category;
  }

  Color _getCategoryColor(String categoryKey, String type) {
    final allCats = _categoryService.allCategories;
    final matching = allCats.where((c) => c['key'] == categoryKey).toList();
    if (matching.isNotEmpty) {
      return matching.first['color'] as Color? ?? Colors.grey;
    }
    return Colors.grey;
  }

  String getText(String key) {
    final translated = widget.localizedText[widget.selectedLanguage]?[key];
    if (translated != null && translated.isNotEmpty) return translated;

    // Fallback (including new keys)
    final fallbacks = {
      'recurring_transactions': 'Recurring Transactions',
      'add_recurring': 'Add Recurring',
      'no_recurring': 'No recurring transactions',
      'add_new_hint': 'Click + button to add new',
      'next_due': 'Next Due',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'type': 'Type',
      'income': 'Income',
      'expense': 'Expense',
      'amount': 'Amount',
      'description': 'Description',
      'category': 'Category',
      'frequency': 'Frequency',
      'start_date': 'Start Date',
      'add': 'Add',
      'cancel': 'Cancel',
      'added_successfully': 'Added successfully',
      'delete': 'Delete',
      'delete_recurring_confirm': 'Are you sure you want to delete?',
      'deleted_successfully': 'Deleted successfully',
      'yes': 'Yes',
      'no': 'No',
    };
    if (fallbacks.containsKey(key)) {
      final val = fallbacks[key]!;
      if (widget.selectedLanguage == 'bn') {
        switch (key) {
          case 'recurring_transactions': return 'রিকারিং ট্রানজেকশন';
          case 'add_recurring': return 'রিকারিং যোগ করুন';
          case 'no_recurring': return 'কোনো রিকারিং ট্রানজেকশন নেই';
          case 'add_new_hint': return 'নতুন যোগ করতে + বাটনে ক্লিক করুন';
          case 'next_due': return 'পরবর্তী';
          case 'daily': return 'দৈনিক';
          case 'weekly': return 'সাপ্তাহিক';
          case 'monthly': return 'মাসিক';
          case 'yearly': return 'বার্ষিক';
          case 'type': return 'টাইপ';
          case 'income': return 'আয়';
          case 'expense': return 'ব্যয়';
          case 'amount': return 'টাকা';
          case 'description': return 'বিবরণ';
          case 'category': return 'ক্যাটাগরি';
          case 'frequency': return 'ফ্রিকোয়েন্সি';
          case 'start_date': return 'শুরুর তারিখ';
          case 'add': return 'যোগ করুন';
          case 'cancel': return 'বাতিল';
          case 'added_successfully': return 'সফলভাবে যোগ করা হয়েছে';
          case 'delete': return 'মুছুন';
          case 'delete_recurring_confirm': return 'আপনি কি নিশ্চিতভাবে মুছতে চান?';
          case 'deleted_successfully': return 'মুছে ফেলা হয়েছে';
          case 'yes': return 'হ্যাঁ';
          case 'no': return 'না';
        }
      } else if (widget.selectedLanguage == 'ar') {
        switch (key) {
          case 'recurring_transactions': return 'المعاملات المتكررة';
          case 'add_recurring': return 'إضافة معاملة متكررة';
          case 'no_recurring': return 'لا توجد معاملات متكررة';
          case 'add_new_hint': return 'انقر على زر + لإضافة جديدة';
          case 'next_due': return 'الاستحقاق القادم';
          case 'daily': return 'يومياً';
          case 'weekly': return 'أسبوعياً';
          case 'monthly': return 'شهرياً';
          case 'yearly': return 'سنوياً';
          case 'type': return 'النوع';
          case 'income': return 'دخل';
          case 'expense': return 'مصروف';
          case 'amount': return 'المبلغ';
          case 'description': return 'الوصف';
          case 'category': return 'الفئة';
          case 'frequency': return 'التكرار';
          case 'start_date': return 'تاريخ البدء';
          case 'add': return 'إضافة';
          case 'cancel': return 'إلغاء';
          case 'added_successfully': return 'تمت الإضافة بنجاح';
          case 'delete': return 'حذف';
          case 'delete_recurring_confirm': return 'هل أنت متأكد من الحذف؟';
          case 'deleted_successfully': return 'تم الحذف بنجاح';
          case 'yes': return 'نعم';
          case 'no': return 'لا';
        }
      }
      return val;
    }
    return widget.localizedText['bn']?[key] ?? key;
  }

  String getCategoryName(String key) {
    final allCats = _categoryService.allCategories;
    final cat = allCats.firstWhere(
      (c) => c['key'] == key,
      orElse: () => <String, dynamic>{},
    );
    if (cat != null && cat['isCustom'] == true) {
      return cat['key']; // custom name
    }
    return getText(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Text(getText('recurring_transactions'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        onPressed: _showAddRecurringDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<RecurringTransactionModel>('recurring').listenable(),
        builder: (context, Box<RecurringTransactionModel> box, _) {
          final list = box.values.toList();
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(getText('no_recurring'), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(getText('add_new_hint'), style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            cacheExtent: 500,
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) => _buildRecurringCard(list[index]),
          );
        },
      ),
    );
  }

  Widget _buildRecurringCard(RecurringTransactionModel rt) {
    final isIncome = rt.type == 'Income';
    final categoryIcon = _getCategoryIcon(rt.category, rt.type);
    final categoryColor = _getCategoryColor(rt.category, rt.type);
    final freqText = getText(rt.frequency);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: categoryColor.withOpacity(0.15),
            child: Icon(categoryIcon, color: categoryColor),
          ),
          title: Text(rt.note, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatAmount(rt.amount)} • $freqText',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '${getText('next_due')}: ${DateFormat('dd/MM/yyyy').format(rt.nextDueDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          trailing: Switch(
            value: rt.isActive,
            activeColor: Colors.green,
            onChanged: (v) => _db.updateRecurringTransaction(rt.id, {'isActive': v}),
          ),
          onLongPress: () => _showDeleteConfirmation(rt.id),
        ),
      ),
    );
  }

  void _showAddRecurringDialog() {
    String selType = 'Expense';
    String selCat = 'gas_bill';
    String selFreq = 'monthly';
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(getText('add_recurring'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selType,
                      isExpanded: true,
                      hint: Text(getText('type')),
                      items: [
                        DropdownMenuItem(value: 'Expense', child: Text(getText('expense'))),
                        DropdownMenuItem(value: 'Income', child: Text(getText('income'))),
                      ],
                      onChanged: (String? v) {
                        if (v != null) setDialogState(() {
                          selType = v;
                          selCat = v == 'Income' ? 'salary' : 'gas_bill';
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Amount field
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.money),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: getText('description'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // ✅ Category dropdown with "Add New" feature - FIXED
               CategoryDropdown(
                 selectedValue: selCat,
                 onChanged: (newValue) => setState(() => selCat = newValue),
                 hintText: getText('select_category'),
                 showAddNew: true,
                 filterType: selType,   // ← 'Income' বা 'Expense' (বর্তমান সিলেক্টেড টাইপ)
                 getTranslatedName: (key) => getCategoryName(key),
                 addNewCategoryText: getText('add_new_category'),
                 dialogTitle: getText('add_new_category_dialog_title'),
                 categoryNameLabel: getText('category_name'),
                 addButtonText: getText('add'),
                 cancelButtonText: getText('cancel'),
               ),
                const SizedBox(height: 12),
                // Frequency dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selFreq,
                      isExpanded: true,
                      hint: Text(getText('frequency')),
                      items: [
                        DropdownMenuItem(value: 'daily', child: Text(getText('daily'))),
                        DropdownMenuItem(value: 'weekly', child: Text(getText('weekly'))),
                        DropdownMenuItem(value: 'monthly', child: Text(getText('monthly'))),
                        DropdownMenuItem(value: 'yearly', child: Text(getText('yearly'))),
                      ],
                      onChanged: (String? v) {
                        if (v != null) setDialogState(() => selFreq = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Start date picker
                InkWell(
                  onTap: () async {
                    DateTime? p = await showDatePicker(
                      context: dialogContext,
                      initialDate: selDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: Locale(widget.selectedLanguage),
                    );
                    if (p != null) setDialogState(() => selDate = p);
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
                        Text('${getText('start_date')}: ${DateFormat('dd/MM/yyyy').format(selDate)}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(getText('cancel'))),
            ElevatedButton(
              onPressed: () {
                if (amtCtrl.text.isNotEmpty) {
                  final rawAmount = _convertToEnglishDigits(amtCtrl.text);
                  final amount = double.tryParse(rawAmount);
                  if (amount != null) {
                    _db.addRecurringTransaction(RecurringTransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      note: noteCtrl.text.isNotEmpty ? noteCtrl.text : getCategoryName(selCat),
                      amount: amount,
                      type: selType,
                      category: selCat,
                      frequency: selFreq,
                      startDate: selDate,
                    ));
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(getText('added_successfully')),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(getText('add')),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(getText('delete')),
        content: Text(getText('delete_recurring_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(getText('no'))),
          ElevatedButton(
            onPressed: () {
              _db.deleteRecurringTransaction(id);
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(getText('deleted_successfully')),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(getText('yes'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}