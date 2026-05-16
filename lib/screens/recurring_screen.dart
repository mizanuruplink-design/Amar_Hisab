import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/recurring_transaction_model.dart';
import 'package:firebase_database/firebase_database.dart';

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

  String getText(String key) {
    return widget.localizedText[widget.selectedLanguage]?[key] ??
        widget.localizedText['bn']?[key] ?? key;
  }

  String getCategoryName(String key) => getText(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Text(
          getText('recurring_transactions') ?? 'রিকারিং ট্রানজেকশন',
          style: const TextStyle(color: Colors.white),
        ),
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
      body: StreamBuilder<DatabaseEvent>(
        stream: _db.getRecurringTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    getText('no_recurring') ?? 'কোনো রিকারিং ট্রানজেকশন নেই',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'নতুন যোগ করতে + বাটনে ক্লিক করুন',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<RecurringTransactionModel> list = [];

          data.forEach((k, v) {
            try {
              list.add(RecurringTransactionModel.fromMap(
                k.toString(),
                Map<String, dynamic>.from(v),
              ));
            } catch (e) {
              print('Error parsing recurring: $e');
            }
          });

          list.sort((a, b) => b.nextDueDate.compareTo(a.nextDueDate));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (c, i) => _buildRecurringCard(list[i]),
          );
        },
      ),
    );
  }

  Widget _buildRecurringCard(RecurringTransactionModel rt) {
    bool isIncome = rt.type == 'Income';
    Color typeColor = isIncome ? Colors.green : Colors.red;

    String freqText = 'মাসিক';
    switch (rt.frequency) {
      case 'daily': freqText = 'দৈনিক'; break;
      case 'weekly': freqText = 'সাপ্তাহিক'; break;
      case 'monthly': freqText = 'মাসিক'; break;
      case 'yearly': freqText = 'বাৎসরিক'; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: typeColor.withOpacity(0.15),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: typeColor,
            ),
          ),
          title: Text(rt.note, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('৳ ${rt.amount.toStringAsFixed(0)} • $freqText'),
              Text(
                'পরবর্তী: ${DateFormat('dd/MM/yyyy').format(rt.nextDueDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Switch(
            value: rt.isActive,
            activeColor: Colors.green,
            onChanged: (v) {
              _db.updateRecurringTransaction(rt.id, {'isActive': v});
            },
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
          title: Text(
            getText('add_recurring') ?? 'রিকারিং যোগ করুন',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type Dropdown
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
                      hint: const Text('টাইপ'),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'Expense',
                          child: Text('ব্যয়'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Income',
                          child: Text('আয়'),
                        ),
                      ],
                      onChanged: (String? v) {
                        if (v != null) {
                          setDialogState(() {
                            selType = v;
                            selCat = v == 'Income' ? 'salary' : 'gas_bill';
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Amount
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: getText('amount') ?? 'টাকা',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.money),
                  ),
                ),
                const SizedBox(height: 12),

                // Note
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: getText('description') ?? 'বিবরণ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Dropdown
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
                      hint: const Text('ক্যাটাগরি'),
                      items: (selType == 'Income'
                          ? widget.incomeCategories
                          : widget.expenseCategories
                      ).map<DropdownMenuItem<String>>((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['key'] as String,
                          child: Text(getCategoryName(cat['key'] as String)),
                        );
                      }).toList(),
                      onChanged: (String? v) {
                        if (v != null) setDialogState(() => selCat = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Frequency Dropdown
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
                      hint: const Text('ফ্রিকোয়েন্সি'),
                      items: const [
                        DropdownMenuItem<String>(value: 'daily', child: Text('দৈনিক')),
                        DropdownMenuItem<String>(value: 'weekly', child: Text('সাপ্তাহিক')),
                        DropdownMenuItem<String>(value: 'monthly', child: Text('মাসিক')),
                        DropdownMenuItem<String>(value: 'yearly', child: Text('বাৎসরিক')),
                      ],
                      onChanged: (String? v) {
                        if (v != null) setDialogState(() => selFreq = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Start Date
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
                        Text(
                          '${getText('start_date') ?? 'শুরুর তারিখ'}: ${DateFormat('dd/MM/yyyy').format(selDate)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(getText('cancel') ?? 'বাতিল'),
            ),
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
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(getText('added_successfully') ?? 'সফলভাবে যোগ করা হয়েছে'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(getText('add') ?? 'যোগ করুন'),
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
        title: Text(getText('delete') ?? 'ডিলিট'),
        content: Text(getText('delete_recurring_confirm') ?? 'আপনি কি নিশ্চিতভাবে ডিলিট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(getText('no') ?? 'না'),
          ),
          ElevatedButton(
            onPressed: () {
              _db.deleteRecurringTransaction(id);
              Navigator.pop(c);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(getText('deleted_successfully') ?? 'ডিলিট করা হয়েছে'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              getText('yes') ?? 'হ্যাঁ',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}