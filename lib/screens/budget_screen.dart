import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/local_database_service.dart';
import '../models/budget_model.dart';

class BudgetScreen extends StatefulWidget {
  final String selectedLanguage;
  final Map<String, Map<String, String>> localizedText;

  const BudgetScreen({
    super.key,
    required this.selectedLanguage,
    required this.localizedText,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final LocalDatabaseService _db = LocalDatabaseService();

  List<Map<String, dynamic>> expenseCategories = [
    {'key': 'gas_bill', 'icon': Icons.electric_bolt, 'color': Colors.red},
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

  // ==================== LOCALISATION ====================
  String getText(String key) {
    final translated = widget.localizedText[widget.selectedLanguage]?[key];
    if (translated != null && translated.isNotEmpty) return translated;

    // Fallback
    switch (key) {
      case 'budget_management':
        if (widget.selectedLanguage == 'bn') return 'বাজেট ম্যানেজমেন্ট';
        if (widget.selectedLanguage == 'ar') return 'إدارة الميزانية';
        return 'Budget Management';
      case 'add_budget':
        if (widget.selectedLanguage == 'bn') return 'বাজেট যোগ করুন';
        if (widget.selectedLanguage == 'ar') return 'إضافة ميزانية';
        return 'Add Budget';
      case 'total_budget_overview':
        if (widget.selectedLanguage == 'bn') return 'মোট বাজেটের সারাংশ';
        if (widget.selectedLanguage == 'ar') return 'نظرة عامة على إجمالي الميزانية';
        return 'Total Budget Overview';
      case 'category_budget':
        if (widget.selectedLanguage == 'bn') return 'ক্যাটাগরি অনুযায়ী বাজেট';
        if (widget.selectedLanguage == 'ar') return 'الميزانية حسب الفئة';
        return 'Category-wise Budget';
      case 'budget_amount':
        if (widget.selectedLanguage == 'bn') return 'বাজেটের পরিমাণ';
        if (widget.selectedLanguage == 'ar') return 'مبلغ الميزانية';
        return 'Budget Amount';
      case 'select_category':
        if (widget.selectedLanguage == 'bn') return 'ক্যাটাগরি নির্বাচন করুন';
        if (widget.selectedLanguage == 'ar') return 'اختر الفئة';
        return 'Select Category';
      case 'monthly':
        if (widget.selectedLanguage == 'bn') return 'মাসিক';
        if (widget.selectedLanguage == 'ar') return 'شهرياً';
        return 'Monthly';
      case 'weekly':
        if (widget.selectedLanguage == 'bn') return 'সাপ্তাহিক';
        if (widget.selectedLanguage == 'ar') return 'أسبوعياً';
        return 'Weekly';
      case 'yearly':
        if (widget.selectedLanguage == 'bn') return 'বার্ষিক';
        if (widget.selectedLanguage == 'ar') return 'سنوياً';
        return 'Yearly';
      case 'add':
        if (widget.selectedLanguage == 'bn') return 'যোগ করুন';
        if (widget.selectedLanguage == 'ar') return 'إضافة';
        return 'Add';
      case 'cancel':
        if (widget.selectedLanguage == 'bn') return 'বাতিল';
        if (widget.selectedLanguage == 'ar') return 'إلغاء';
        return 'Cancel';
      case 'edit':
        if (widget.selectedLanguage == 'bn') return 'সম্পাদনা';
        if (widget.selectedLanguage == 'ar') return 'تعديل';
        return 'Edit';
      case 'delete':
        if (widget.selectedLanguage == 'bn') return 'মুছুন';
        if (widget.selectedLanguage == 'ar') return 'حذف';
        return 'Delete';
      case 'budget':
        if (widget.selectedLanguage == 'bn') return 'বাজেট';
        if (widget.selectedLanguage == 'ar') return 'الميزانية';
        return 'Budget';
      case 'remaining':
        if (widget.selectedLanguage == 'bn') return 'বাকি';
        if (widget.selectedLanguage == 'ar') return 'المتبقي';
        return 'Remaining';
      case 'used':
        if (widget.selectedLanguage == 'bn') return 'ব্যবহৃত';
        if (widget.selectedLanguage == 'ar') return 'المستخدم';
        return 'Used';
      case 'budget_exceeded':
        if (widget.selectedLanguage == 'bn') return 'বাজেট অতিক্রম';
        if (widget.selectedLanguage == 'ar') return 'تجاوز الميزانية';
        return 'Budget Exceeded';
      case 'overspent':
        if (widget.selectedLanguage == 'bn') return 'অতিরিক্ত খরচ';
        if (widget.selectedLanguage == 'ar') return 'إنفاق زائد';
        return 'Overspent';
      case 'warning':
        if (widget.selectedLanguage == 'bn') return 'সতর্কতা';
        if (widget.selectedLanguage == 'ar') return 'تحذير';
        return 'Warning';
      case 'half_used':
        if (widget.selectedLanguage == 'bn') return 'অর্ধেক ব্যবহৃত';
        if (widget.selectedLanguage == 'ar') return 'نصف المستخدم';
        return 'Half Used';
      case 'safe':
        if (widget.selectedLanguage == 'bn') return 'নিরাপদ';
        if (widget.selectedLanguage == 'ar') return 'آمن';
        return 'Safe';
      case 'no_budget_set':
        if (widget.selectedLanguage == 'bn') return 'কোনো বাজেট সেট করা নেই';
        if (widget.selectedLanguage == 'ar') return 'لم يتم تعيين ميزانية';
        return 'No budget set';
      case 'click_to_add_budget':
        if (widget.selectedLanguage == 'bn') return 'বাজেট যোগ করতে ক্লিক করুন';
        if (widget.selectedLanguage == 'ar') return 'انقر لإضافة ميزانية';
        return 'Click to add budget';
      case 'no_budget_this_month':
        if (widget.selectedLanguage == 'bn') return 'এই মাসের কোনো বাজেট নেই';
        if (widget.selectedLanguage == 'ar') return 'لا توجد ميزانية لهذا الشهر';
        return 'No budget for this month';
      case 'budget_added_success':
        if (widget.selectedLanguage == 'bn') return 'বাজেট সফলভাবে যোগ করা হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تمت إضافة الميزانية بنجاح';
        return 'Budget added successfully';
      case 'budget_updated_success':
        if (widget.selectedLanguage == 'bn') return 'বাজেট আপডেট করা হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تم تحديث الميزانية';
        return 'Budget updated successfully';
      case 'budget_deleted_success':
        if (widget.selectedLanguage == 'bn') return 'বাজেট মুছে ফেলা হয়েছে';
        if (widget.selectedLanguage == 'ar') return 'تم حذف الميزانية';
        return 'Budget deleted successfully';
      case 'edit_budget':
        if (widget.selectedLanguage == 'bn') return 'বাজেট সম্পাদনা';
        if (widget.selectedLanguage == 'ar') return 'تحرير الميزانية';
        return 'Edit Budget';
      case 'delete_budget':
        if (widget.selectedLanguage == 'bn') return 'বাজেট মুছুন';
        if (widget.selectedLanguage == 'ar') return 'حذف الميزانية';
        return 'Delete Budget';
      case 'delete_budget_confirm':
        if (widget.selectedLanguage == 'bn') return 'আপনি কি বাজেটটি মুছতে চান?';
        if (widget.selectedLanguage == 'ar') return 'هل تريد حذف هذه الميزانية؟';
        return 'Do you want to delete this budget?';
      case 'yes':
        if (widget.selectedLanguage == 'bn') return 'হ্যাঁ';
        if (widget.selectedLanguage == 'ar') return 'نعم';
        return 'Yes';
      case 'no':
        if (widget.selectedLanguage == 'bn') return 'না';
        if (widget.selectedLanguage == 'ar') return 'لا';
        return 'No';
      case 'update':
        if (widget.selectedLanguage == 'bn') return 'আপডেট';
        if (widget.selectedLanguage == 'ar') return 'تحديث';
        return 'Update';
      case 'period':
        if (widget.selectedLanguage == 'bn') return 'মেয়াদ';
        if (widget.selectedLanguage == 'ar') return 'الفترة';
        return 'Period';
      default:
        return widget.localizedText['bn']?[key] ?? key;
    }
  }

  String getCategoryName(String key) => getText(key);

  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  String _formatMonth(String yearMonth) {
    try {
      List<String> parts = yearMonth.split('-');
      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      DateTime date = DateTime(year, month);
      String locale = widget.selectedLanguage == 'bn' ? 'bn_BD' :
      widget.selectedLanguage == 'ar' ? 'ar_SA' : 'en_US';
      return DateFormat('MMMM yyyy', locale).format(date);
    } catch (e) {
      return yearMonth;
    }
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        title: Text(
          getText('budget_management'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    List<String> parts = _selectedMonth.split('-');
                    int year = int.parse(parts[0]);
                    int month = int.parse(parts[1]);
                    if (month == 1) { year--; month = 12; } else { month--; }
                    setState(() {
                      _selectedMonth = '$year-${month.toString().padLeft(2, '0')}';
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    _formatMonth(_selectedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    List<String> parts = _selectedMonth.split('-');
                    int year = int.parse(parts[0]);
                    int month = int.parse(parts[1]);
                    if (month == 12) { year++; month = 1; } else { month++; }
                    setState(() {
                      _selectedMonth = '$year-${month.toString().padLeft(2, '0')}';
                    });
                  },
                ),
              ],
            ),
          ),

          // Add budget button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddBudgetDialog,
              icon: const Icon(Icons.add),
              label: Text(getText('add_budget')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Budget list (Hive ValueListenableBuilder)
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<BudgetModel>('budgets').listenable(),
              builder: (context, Box<BudgetModel> box, _) {
                final allBudgets = box.values.toList();
                final budgets = allBudgets.where((b) => b.month == _selectedMonth).toList();
                if (allBudgets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(getText('no_budget_set'), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(getText('click_to_add_budget'), style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                  );
                }

                if (budgets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(getText('no_budget_this_month'), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }

                double totalBudget = budgets.fold(0, (sum, b) => sum + b.budgetAmount);
                double totalSpent = budgets.fold(0, (sum, b) => sum + b.spentAmount);
                double overallPercentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildOverviewCard(totalBudget, totalSpent, overallPercentage),
                    const SizedBox(height: 15),
                    Text(getText('category_budget'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...budgets.map((budget) => _buildBudgetCard(budget)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(double totalBudget, double totalSpent, double percentage) {
    Color statusColor = percentage >= 100 ? Colors.red :
    percentage >= 80 ? Colors.orange :
    Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(getText('total_budget_overview'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Text('৳ ${totalSpent.toStringAsFixed(0)} / ৳ ${totalBudget.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text('${percentage.toStringAsFixed(1)}% ${getText('used')}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    var category = expenseCategories.firstWhere(
          (c) => c['key'] == budget.category,
      orElse: () => {'key': 'other', 'icon': Icons.more_horiz, 'color': Colors.grey},
    );

    Color progressColor = budget.isOverBudget ? Colors.red :
    budget.spentPercentage >= 80 ? Colors.orange :
    Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(category['icon'] as IconData, color: category['color'] as Color, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(getCategoryName(budget.category),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${getText('budget')}: ৳ ${budget.budgetAmount.toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('৳ ${budget.spentAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: progressColor)),
                    Text(getBudgetStatusText(budget.statusText),
                        style: TextStyle(fontSize: 11, color: progressColor)),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _showEditBudgetDialog(budget);
                    if (value == 'delete') _confirmDeleteBudget(budget.id);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit, size: 18),
                        const SizedBox(width: 8),
                        Text(getText('edit')),
                      ]),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(getText('delete'), style: const TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: budget.spentPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${budget.spentPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: progressColor)),
                Text('${getText('remaining')}: ৳ ${budget.remainingAmount.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            if (budget.isOverBudget)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 18),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${getText('budget_exceeded')}! ${getText('overspent')} ৳ ${(budget.spentAmount - budget.budgetAmount).toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String getBudgetStatusText(String status) {
    switch (status) {
      case 'অতিরিক্ত খরচ':
        return getText('over_budget');
      case 'সতর্কতা':
        return getText('warning');
      case 'অর্ধেক ব্যবহৃত':
        return getText('half_used');
      case 'নিরাপদ':
        return getText('safe');
      default:
        return status;
    }
  }

  void _showAddBudgetDialog() {
    String selectedCategory = 'gas_bill';
    final amountController = TextEditingController();
    String selectedPeriod = 'monthly';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(getText('add_budget'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      hint: Text(getText('select_category')),
                      items: expenseCategories.map((cat) {
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
                        if (v != null) setDialogState(() => selectedCategory = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Budget amount
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: getText('budget_amount'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.money),
                  ),
                ),
                const SizedBox(height: 15),

                // Period dropdown – now translated
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPeriod,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<String>(
                          value: 'monthly',
                          child: Text(getText('monthly')),
                        ),
                        DropdownMenuItem<String>(
                          value: 'weekly',
                          child: Text(getText('weekly')),
                        ),
                        DropdownMenuItem<String>(
                          value: 'yearly',
                          child: Text(getText('yearly')),
                        ),
                      ],
                      onChanged: (String? v) {
                        if (v != null) setDialogState(() => selectedPeriod = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(getText('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  double? amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    BudgetModel budget = BudgetModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      category: selectedCategory,
                      budgetAmount: amount,
                      spentAmount: 0,
                      period: selectedPeriod,
                      month: _selectedMonth,
                      isActive: true,
                    );
                    _db.addBudget(budget);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('${getCategoryName(selectedCategory)} - ${getText('budget_added_success')}'),
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

  void _showEditBudgetDialog(BudgetModel budget) {
    final amountController = TextEditingController(text: budget.budgetAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getText('edit_budget'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: getText('budget_amount'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.money),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getText('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                double? amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  _db.updateBudget(budget.id, {'budgetAmount': amount});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(getText('budget_updated_success')),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(getText('update')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBudget(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getText('delete_budget'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(getText('delete_budget_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getText('no')),
          ),
          ElevatedButton(
            onPressed: () {
              _db.deleteBudget(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(getText('budget_deleted_success')),
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