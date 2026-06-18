import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/local_database_service.dart';
import '../models/recurring_transaction_model.dart';

class RecurringScreen extends StatefulWidget {
  final String selectedLanguage;
  final Map<String, Map<String, String>> localizedText;
  final List<Map<String, dynamic>> incomeCategories;
  final List<Map<String, dynamic>> expenseCategories;

  const RecurringScreen({
    super.key,
    required this.selectedLanguage,
    required this.localizedText,
    required this.incomeCategories,
    required this.expenseCategories,
  });

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final LocalDatabaseService _db = LocalDatabaseService();

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

  String _formatAmount(double amount) {
    String formatted = amount.toStringAsFixed(0);
    return _convertToScriptDigits(formatted);
  }

  // ==================== HELPERS ====================
  IconData _getCategoryIcon(String categoryKey, String type) {
    final List<Map<String, dynamic>> categories =
        type == 'Income' ? widget.incomeCategories : widget.expenseCategories;
    final cat = categories.firstWhere(
          (c) => c['key'] == categoryKey,
      orElse: () => {'icon': Icons.category, 'color': Colors.grey},
    );
    return cat['icon'] as IconData;
  }

  Color _getCategoryColor(String categoryKey, String type) {
    final List<Map<String, dynamic>> categories =
        type == 'Income' ? widget.incomeCategories : widget.expenseCategories;
    final cat = categories.firstWhere(
          (c) => c['key'] == categoryKey,
      orElse: () => {'icon': Icons.category, 'color': Colors.grey},
    );
    return cat['color'] as Color;
  }

  String getText(String key) {
    final translated = widget.localizedText[widget.selectedLanguage]?[key];
    if (translated != null && translated.isNotEmpty) return translated;

    // Fallback (many keys already covered; keep minimal)
    switch (key) {
      case 'recurring_transactions':
        if (widget.selectedLanguage == 'bn') return 'রিকারিং ট্রানজেকশন';
        if (widget.selectedLanguage == 'ar') return 'المعاملات المتكررة';
        return 'Recurring Transactions';
      case 'add_recurring':
        if (widget.selectedLanguage == 'bn') return 'রিকারিং যোগ করুন';
        if (widget.selectedLanguage == 'ar') return 'إضافة معاملة متكررة';
        return 'Add Recurring';
      case 'no_recurring':
        if (widget.selectedLanguage == 'bn') return 'কোনো রিকারিং ট্রানজেকশন নেই';
        if (widget.selectedLanguage == 'ar') return 'لا توجد معاملات متكررة';
        return 'No recurring transactions';
      case 'add_new_hint':
        if (widget.selectedLanguage == 'bn') return 'নতুন যোগ করতে + বাটনে ক্লিক করুন';
        if (widget.selectedLanguage == 'ar') return 'انقر على زر + لإضافة جديدة';
        return 'Click + button to add new';
      case 'next_due':
        if (widget.selectedLanguage == 'bn') return 'পরবর্তী';
        if (widget.selectedLanguage == 'ar') return 'الاستحقاق القادم';
        return 'Next Due';
      case 'daily':
        if (widget.selectedLanguage == 'bn') return 'দৈনিক';
        if (widget.selectedLanguage == 'ar') return 'يومياً';
        return 'Daily';
      case 'weekly':
        if (widget.selectedLanguage == 'bn') return 'সাপ্তাহিক';
        if (widget.selectedLanguage == 'ar') return 'أسبوعياً';
        return 'Weekly';
      case 'monthly':
        if (widget.selectedLanguage == 'bn') return 'মাসিক';
        if (widget.selectedLanguage == 'ar') return 'شهرياً';
        return 'Monthly';
      case 'yearly':
        if (widget.selectedLanguage == 'bn') return 'বার্ষিক';
        if (widget.selectedLanguage == 'ar') return 'سنوياً';
        return 'Yearly';
      case 'type':
        if (widget.selectedLanguage == 'bn') return 'টাইপ';
        if (widget.selectedLanguage == 'ar') return 'النوع';
        return 'Type';
      case 'income':
        if (widget.selectedLanguage == 'bn') return 'আয়';
        if (widget.selectedLanguage == 'ar') return 'دخل';
        return 'Income';
      case 'expense':
        if (widget.selectedLanguage == 'bn') return 'ব্যয়';
        if (widget.selectedLanguage == 'ar') return 'مصروف';
        return 'Expense';
      case 'amount':
        if (widget.selectedLanguage == 'bn') return 'টাকা';
        if (widget.selectedLanguage == 'ar') return 'المبلغ';
        return 'Amount';
      case 'description':
        if (widget.selectedLanguage == 'bn') return 'বিবরণ';
        if (widget.selectedLanguage == 'ar') return 'الوصف';
        return 'Description';
      case 'category':
        if (widget.selectedLanguage == 'bn') return 'ক্যাটাগরি';
        if (widget.selectedLanguage == 'ar') return 'الفئة';
        return 'Category';
      case 'frequency':
        if (widget.selectedLanguage == 'bn') return 'ফ্রিকোয়েন্সি';
        if (widget.selectedLanguage == 'ar') return 'التكرار';
        return 'Frequency';
      case 'start_date':
        if (widget.selectedLanguage == 'bn') return 'শুরুর তারিখ';
        if (widget.selectedLanguage == 'ar') return 'تاريخ البدء';
        return 'Start Date';
      case 'add':
        if (widget.selectedLanguage == 'bn') return 'যোগ করুন';
        if (widget.selectedLanguage == 'ar') return 'إضافة';
        return 'Add';
      case 'cancel':
        if (widget.selectedLanguage == 'bn') return 'বাতিল';
        if (widget.selectedLanguage == 'ar') return 'إلغاء';
        return 'Cancel';
      case 'added_successfully':
        if (widget.selectedLanguage == 'bn') return 'সফলভাবে যোগ করা হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تمت الإضافة بنجاح';
        return 'Added successfully';
      case 'delete':
        if (widget.selectedLanguage == 'bn') return 'মুছুন';
        if (widget.selectedLanguage == 'ar') return 'حذف';
        return 'Delete';
      case 'delete_recurring_confirm':
        if (widget.selectedLanguage == 'bn') return 'আপনি কি নিশ্চিতভাবে মুছতে চান?';
        if (widget.selectedLanguage == 'ar') return 'هل أنت متأكد من الحذف؟';
        return 'Are you sure you want to delete?';
      case 'deleted_successfully':
        if (widget.selectedLanguage == 'bn') return 'মুছে ফেলা হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تم الحذف بنجاح';
        return 'Deleted successfully';
      case 'yes':
        if (widget.selectedLanguage == 'bn') return 'হ্যাঁ';
        if (widget.selectedLanguage == 'ar') return 'نعم';
        return 'Yes';
      case 'no':
        if (widget.selectedLanguage == 'bn') return 'না';
        if (widget.selectedLanguage == 'ar') return 'لا';
        return 'No';
      default:
        return widget.localizedText['bn']?[key] ?? key;
    }
  }

  String getCategoryName(String key) => getText(key);

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
                '${_formatAmount(rt.amount)} • $freqText', // ✅ ডিজিট কনভার্ট
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
                // Amount field (বাংলা/আরবি ডিজিট সাপোর্ট)
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
                // Category dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selCat,
                      isExpanded: true,
                      hint: Text(getText('category')),
                      items: (selType == 'Income'
                          ? widget.incomeCategories
                          : widget.expenseCategories).map<DropdownMenuItem<String>>((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['key'] as String,
                          child: Row(
                            children: [
                              Icon(cat['icon'] as IconData, size: 20, color: cat['color'] as Color),
                              const SizedBox(width: 10),
                              Text(getCategoryName(cat['key'] as String)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? v) {
                        if (v != null) setDialogState(() => selCat = v);
                      },
                    ),
                  ),
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
                // Start date picker (locale added)
                InkWell(
                  onTap: () async {
                    DateTime? p = await showDatePicker(
                      context: dialogContext,
                      initialDate: selDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: Locale(widget.selectedLanguage), // ✅ ভাষা সাপোর্ট
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
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