import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
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
  final DatabaseService _db = DatabaseService();

  // ✅ ক্যাটাগরি অনুযায়ী আইকন ও রঙ বের করার হেল্পার
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

    // ফলব্যাক ট্রান্সলেশন (আগের মতোই রাখা হয়েছে)
    switch (key) {
      case 'recurring_transactions':
        switch (widget.selectedLanguage) {
          case 'bn': return 'রিকারিং ট্রানজেকশন';
          case 'ar': return 'المعاملات المتكررة';
          default: return 'Recurring Transactions';
        }
      case 'add_recurring':
        switch (widget.selectedLanguage) {
          case 'bn': return 'রিকারিং যোগ করুন';
          case 'ar': return 'إضافة معاملة متكررة';
          default: return 'Add Recurring';
        }
      case 'no_recurring':
        switch (widget.selectedLanguage) {
          case 'bn': return 'কোনো রিকারিং ট্রানজেকশন নেই';
          case 'ar': return 'لا توجد معاملات متكررة';
          default: return 'No recurring transactions';
        }
      case 'add_new_hint':
        switch (widget.selectedLanguage) {
          case 'bn': return 'নতুন যোগ করতে + বাটনে ক্লিক করুন';
          case 'ar': return 'انقر على زر + لإضافة جديدة';
          default: return 'Click + button to add new';
        }
      case 'retry':
        switch (widget.selectedLanguage) {
          case 'bn': return 'আবার চেষ্টা করুন';
          case 'ar': return 'إعادة المحاولة';
          default: return 'Retry';
        }
      case 'next_due':
        switch (widget.selectedLanguage) {
          case 'bn': return 'পরবর্তী';
          case 'ar': return 'الاستحقاق القادم';
          default: return 'Next Due';
        }
      case 'daily':
        switch (widget.selectedLanguage) {
          case 'bn': return 'দৈনিক';
          case 'ar': return 'يومياً';
          default: return 'Daily';
        }
      case 'weekly':
        switch (widget.selectedLanguage) {
          case 'bn': return 'সাপ্তাহিক';
          case 'ar': return 'أسبوعياً';
          default: return 'Weekly';
        }
      case 'monthly':
        switch (widget.selectedLanguage) {
          case 'bn': return 'মাসিক';
          case 'ar': return 'شهرياً';
          default: return 'Monthly';
        }
      case 'yearly':
        switch (widget.selectedLanguage) {
          case 'bn': return 'বার্ষিক';
          case 'ar': return 'سنوياً';
          default: return 'Yearly';
        }
      case 'type':
        switch (widget.selectedLanguage) {
          case 'bn': return 'টাইপ';
          case 'ar': return 'النوع';
          default: return 'Type';
        }
      case 'income':
        switch (widget.selectedLanguage) {
          case 'bn': return 'আয়';
          case 'ar': return 'دخل';
          default: return 'Income';
        }
      case 'expense':
        switch (widget.selectedLanguage) {
          case 'bn': return 'ব্যয়';
          case 'ar': return 'مصروف';
          default: return 'Expense';
        }
      case 'amount':
        switch (widget.selectedLanguage) {
          case 'bn': return 'টাকা';
          case 'ar': return 'المبلغ';
          default: return 'Amount';
        }
      case 'description':
        switch (widget.selectedLanguage) {
          case 'bn': return 'বিবরণ';
          case 'ar': return 'الوصف';
          default: return 'Description';
        }
      case 'category':
        switch (widget.selectedLanguage) {
          case 'bn': return 'ক্যাটাগরি';
          case 'ar': return 'الفئة';
          default: return 'Category';
        }
      case 'frequency':
        switch (widget.selectedLanguage) {
          case 'bn': return 'ফ্রিকোয়েন্সি';
          case 'ar': return 'التكرار';
          default: return 'Frequency';
        }
      case 'start_date':
        switch (widget.selectedLanguage) {
          case 'bn': return 'শুরুর তারিখ';
          case 'ar': return 'تاريخ البدء';
          default: return 'Start Date';
        }
      case 'add':
        switch (widget.selectedLanguage) {
          case 'bn': return 'যোগ করুন';
          case 'ar': return 'إضافة';
          default: return 'Add';
        }
      case 'cancel':
        switch (widget.selectedLanguage) {
          case 'bn': return 'বাতিল';
          case 'ar': return 'إلغاء';
          default: return 'Cancel';
        }
      case 'added_successfully':
        switch (widget.selectedLanguage) {
          case 'bn': return 'সফলভাবে যোগ করা হয়েছে';
          case 'ar': return 'تمت الإضافة بنجاح';
          default: return 'Added successfully';
        }
      case 'delete':
        switch (widget.selectedLanguage) {
          case 'bn': return 'মুছুন';
          case 'ar': return 'حذف';
          default: return 'Delete';
        }
      case 'delete_recurring_confirm':
        switch (widget.selectedLanguage) {
          case 'bn': return 'আপনি কি নিশ্চিতভাবে মুছতে চান?';
          case 'ar': return 'هل أنت متأكد من الحذف؟';
          default: return 'Are you sure you want to delete?';
        }
      case 'deleted_successfully':
        switch (widget.selectedLanguage) {
          case 'bn': return 'মুছে ফেলা হয়েছে';
          case 'ar': return 'تم الحذف بنجاح';
          default: return 'Deleted successfully';
        }
      case 'yes':
        switch (widget.selectedLanguage) {
          case 'bn': return 'হ্যাঁ';
          case 'ar': return 'نعم';
          default: return 'Yes';
        }
      case 'no':
        switch (widget.selectedLanguage) {
          case 'bn': return 'না';
          case 'ar': return 'لا';
          default: return 'No';
        }
      default:
        return widget.localizedText['bn']?[key] ?? key;
    }
  }

  String getCategoryName(String key) => getText(key);

  @override
  void initState() {
    super.initState();
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
      body: StreamBuilder<List<RecurringTransactionModel>>(
        stream: _db.recurringStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 10),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: () => setState(() {}), child: Text(getText('retry'))),
                ],
              ),
            );
          }
          final list = snapshot.data ?? [];
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
              Text('৳ ${rt.amount.toStringAsFixed(0)} • $freqText', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
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
                InkWell(
                  onTap: () async {
                    DateTime? p = await showDatePicker(
                      context: dialogContext,
                      initialDate: selDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
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
                if (amtCtrl.text.isNotEmpty && double.tryParse(amtCtrl.text) != null) {
                  _db.addRecurringTransaction(RecurringTransactionModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    note: noteCtrl.text.isNotEmpty ? noteCtrl.text : getCategoryName(selCat),
                    amount: double.parse(amtCtrl.text),
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
                SnackBar(content: Text(getText('deleted_successfully')), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
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