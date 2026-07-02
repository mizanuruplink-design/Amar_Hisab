import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/local_database_service.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/category_service.dart';
import '../widgets/category_dropdown.dart';

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
  final CategoryService _categoryService = CategoryService();

  String _budgetType = 'Expense';
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

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

  // ==================== LOCALIZATION ====================
  String getText(String key) {
    final translated = widget.localizedText[widget.selectedLanguage]?[key];
    if (translated != null && translated.isNotEmpty) return translated;

    final fallbacks = {
      'budget_management': 'Budget Management',
      'add_budget': 'Add Budget',
      'total_budget_overview': 'Total Budget Overview',
      'category_budget': 'Category-wise Budget',
      'budget_amount': 'Budget Amount',
      'select_category': 'Select Category',
      'monthly': 'Monthly',
      'weekly': 'Weekly',
      'yearly': 'Yearly',
      'add': 'Add',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'delete': 'Delete',
      'budget': 'Budget',
      'remaining': 'Remaining',
      'used': 'Used',
      'budget_exceeded': 'Budget Exceeded',
      'overspent': 'Overspent',
      'warning': 'Warning',
      'half_used': 'Half Used',
      'safe': 'Safe',
      'no_budget_set': 'No budget set',
      'click_to_add_budget': 'Click to add budget',
      'no_budget_this_month': 'No budget for this month',
      'budget_added_success': 'Budget added successfully',
      'budget_updated_success': 'Budget updated successfully',
      'budget_deleted_success': 'Budget deleted successfully',
      'edit_budget': 'Edit Budget',
      'delete_budget': 'Delete Budget',
      'delete_budget_confirm': 'Do you want to delete this budget?',
      'yes': 'Yes',
      'no': 'No',
      'update': 'Update',
      'period': 'Period',
      'add_new_category': 'Add New Category',
      'add_new_category_dialog_title': 'Add New Category',
      'category_name': 'Category Name',
      'income': 'Income',
      'expense': 'Expense',
      'opening_balance': 'Opening Balance',
      'closing_balance': 'Closing Balance',
      'net_savings': 'Net Savings',
      'net_deficit': 'Net Deficit',
      'total_income': 'Total Income',
      'total_expense': 'Total Expense',
    };

    if (fallbacks.containsKey(key)) {
      final val = fallbacks[key]!;
      if (widget.selectedLanguage == 'bn') {
        switch (key) {
          case 'budget_management': return 'বাজেট ম্যানেজমেন্ট';
          case 'add_budget': return 'বাজেট যোগ করুন';
          case 'total_budget_overview': return 'মোট বাজেটের সারাংশ';
          case 'category_budget': return 'ক্যাটাগরি অনুযায়ী বাজেট';
          case 'budget_amount': return 'বাজেটের পরিমাণ';
          case 'select_category': return 'ক্যাটাগরি নির্বাচন করুন';
          case 'monthly': return 'মাসিক';
          case 'weekly': return 'সাপ্তাহিক';
          case 'yearly': return 'বার্ষিক';
          case 'add': return 'যোগ করুন';
          case 'cancel': return 'বাতিল';
          case 'edit': return 'সম্পাদনা';
          case 'delete': return 'মুছুন';
          case 'budget': return 'বাজেট';
          case 'remaining': return 'বাকি';
          case 'used': return 'ব্যবহৃত';
          case 'budget_exceeded': return 'বাজেট অতিক্রম';
          case 'overspent': return 'অতিরিক্ত খরচ';
          case 'warning': return 'সতর্কতা';
          case 'half_used': return 'অর্ধেক ব্যবহৃত';
          case 'safe': return 'নিরাপদ';
          case 'no_budget_set': return 'কোনো বাজেট সেট করা নেই';
          case 'click_to_add_budget': return 'বাজেট যোগ করতে ক্লিক করুন';
          case 'no_budget_this_month': return 'এই মাসের কোনো বাজেট নেই';
          case 'budget_added_success': return 'বাজেট সফলভাবে যোগ করা হয়েছে';
          case 'budget_updated_success': return 'বাজেট আপডেট করা হয়েছে';
          case 'budget_deleted_success': return 'বাজেট মুছে ফেলা হয়েছে';
          case 'edit_budget': return 'বাজেট সম্পাদনা';
          case 'delete_budget': return 'বাজেট মুছুন';
          case 'delete_budget_confirm': return 'আপনি কি বাজেটটি মুছতে চান?';
          case 'yes': return 'হ্যাঁ';
          case 'no': return 'না';
          case 'update': return 'আপডেট';
          case 'period': return 'মেয়াদ';
          case 'add_new_category': return 'নতুন ক্যাটাগরি যোগ করুন';
          case 'add_new_category_dialog_title': return 'নতুন ক্যাটাগরি যোগ করুন';
          case 'category_name': return 'ক্যাটাগরির নাম';
          case 'income': return 'আয়';
          case 'expense': return 'ব্যয়';
          case 'opening_balance': return 'শুরুর ব্যালেন্স';
          case 'closing_balance': return 'শেষের ব্যালেন্স';
          case 'net_savings': return 'সঞ্চয়';
          case 'net_deficit': return 'ঘাটতি';
          case 'total_income': return 'মোট আয়';
          case 'total_expense': return 'মোট ব্যয়';
        }
      } else if (widget.selectedLanguage == 'ar') {
        switch (key) {
          case 'budget_management': return 'إدارة الميزانية';
          case 'add_budget': return 'إضافة ميزانية';
          case 'total_budget_overview': return 'نظرة عامة على إجمالي الميزانية';
          case 'category_budget': return 'الميزانية حسب الفئة';
          case 'budget_amount': return 'مبلغ الميزانية';
          case 'select_category': return 'اختر الفئة';
          case 'monthly': return 'شهرياً';
          case 'weekly': return 'أسبوعياً';
          case 'yearly': return 'سنوياً';
          case 'add': return 'إضافة';
          case 'cancel': return 'إلغاء';
          case 'edit': return 'تعديل';
          case 'delete': return 'حذف';
          case 'budget': return 'الميزانية';
          case 'remaining': return 'المتبقي';
          case 'used': return 'المستخدم';
          case 'budget_exceeded': return 'تجاوز الميزانية';
          case 'overspent': return 'إنفاق زائد';
          case 'warning': return 'تحذير';
          case 'half_used': return 'نصف المستخدم';
          case 'safe': return 'آمن';
          case 'no_budget_set': return 'لم يتم تعيين ميزانية';
          case 'click_to_add_budget': return 'انقر لإضافة ميزانية';
          case 'no_budget_this_month': return 'لا توجد ميزانية لهذا الشهر';
          case 'budget_added_success': return 'تمت إضافة الميزانية بنجاح';
          case 'budget_updated_success': return 'تم تحديث الميزانية';
          case 'budget_deleted_success': return 'تم حذف الميزانية';
          case 'edit_budget': return 'تحرير الميزانية';
          case 'delete_budget': return 'حذف الميزانية';
          case 'delete_budget_confirm': return 'هل تريد حذف هذه الميزانية؟';
          case 'yes': return 'نعم';
          case 'no': return 'لا';
          case 'update': return 'تحديث';
          case 'period': return 'الفترة';
          case 'add_new_category': return 'إضافة فئة جديدة';
          case 'add_new_category_dialog_title': return 'إضافة فئة جديدة';
          case 'category_name': return 'اسم الفئة';
          case 'income': return 'دخل';
          case 'expense': return 'مصروف';
          case 'opening_balance': return 'الرصيد الافتتاحي';
          case 'closing_balance': return 'الرصيد الختامي';
          case 'net_savings': return 'صافي الادخار';
          case 'net_deficit': return 'العجز الصافي';
          case 'total_income': return 'إجمالي الدخل';
          case 'total_expense': return 'إجمالي المصروفات';
        }
      }
      return val;
    }

    return widget.localizedText['bn']?[key] ?? key;
  }

  String getCategoryName(String key) {
    if (key == null || key.isEmpty) return getText('other');
    final allCats = _categoryService.allCategories;
    final cat = allCats.firstWhere(
      (c) => c['key'] == key,
      orElse: () => <String, dynamic>{},
    );
    if (cat.isNotEmpty && cat['isCustom'] == true) {
      return cat['key'];
    }
    return getText(key);
  }

  // ==================== MONTH HELPERS ====================
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

  // ==================== SUMMARY CALCULATION ====================
  Map<String, double> _getMonthSummary(Box<TransactionModel> txBox, String month) {
    double openingBalance = 0.0;
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    // Parse month to DateTime range
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);
    final startDate = DateTime(year, monthNum, 1);
    final endDate = DateTime(year, monthNum + 1, 1); // first day of next month

    for (var tx in txBox.values) {
      if (tx.type == 'Note' || tx.type == 'Reminder') continue;
      // Parse tx.date (format: dd/MM/yyyy hh:mm a)
      try {
        final dateStr = tx.date.split(' ')[0]; // get dd/MM/yyyy part
        final date = DateFormat('dd/MM/yyyy').parse(dateStr);
        if (date.compareTo(startDate) >= 0 && date.compareTo(endDate) < 0) {
          if (tx.type == 'Income') totalIncome += tx.amount;
          else if (tx.type == 'Expense') totalExpense += tx.amount;
        }
        // For opening balance: transactions before startDate
        if (date.compareTo(startDate) < 0) {
          if (tx.type == 'Income') openingBalance += tx.amount;
          else if (tx.type == 'Expense') openingBalance -= tx.amount;
          // also add Savings? Actually Savings are not income/expense; we can treat them as income for balance? Better to treat Savings as positive.
          else if (tx.type == 'Savings') openingBalance += tx.amount;
          else if (tx.type == 'Debt') openingBalance -= tx.amount; // debt is negative
          else if (tx.type == 'Credit') openingBalance += tx.amount; // credit is positive
        }
      } catch (_) {}
    }

    double closingBalance = openingBalance + totalIncome - totalExpense;
    return {
      'openingBalance': openingBalance,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'closingBalance': closingBalance,
      'netSavings': totalIncome - totalExpense,
    };
  }

  // ==================== INIT ====================
  @override
  void initState() {
    super.initState();
    _categoryService.init();
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildTypeToggle(),
          _buildAddBudgetButton(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
              builder: (context, Box<TransactionModel> txBox, _) {
                final summary = _getMonthSummary(txBox, _selectedMonth);
                return Column(
                  children: [
                    _buildSummaryCard(summary),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: Hive.box<BudgetModel>('budgets').listenable(),
                        builder: (context, Box<BudgetModel> budgetBox, _) {
                          return _buildBudgetList(budgetBox);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildMonthSelector() {
    return Container(
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
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: 'Expense',
            label: Text(getText('expense')),
            icon: const Icon(Icons.trending_down),
          ),
          ButtonSegment(
            value: 'Income',
            label: Text(getText('income')),
            icon: const Icon(Icons.trending_up),
          ),
        ],
        selected: {_budgetType},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            _budgetType = newSelection.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.blue.shade700;
            }
            return Colors.grey.shade200;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.black87;
          }),
        ),
      ),
    );
  }

  Widget _buildAddBudgetButton() {
    return Padding(
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
    );
  }

  // ==================== SUMMARY CARD ====================
  Widget _buildSummaryCard(Map<String, double> summary) {
    final currencySymbol = '৳'; // You can get from settings
    final opening = summary['openingBalance']!;
    final income = summary['totalIncome']!;
    final expense = summary['totalExpense']!;
    final closing = summary['closingBalance']!;
    final net = summary['netSavings']!;

    Color netColor = net >= 0 ? Colors.green : Colors.red;
    String netLabel = net >= 0 ? getText('net_savings') : getText('net_deficit');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(getText('opening_balance'), opening, currencySymbol),
                _buildSummaryItem(getText('total_income'), income, currencySymbol),
                _buildSummaryItem(getText('total_expense'), expense, currencySymbol),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getText('closing_balance'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '$currencySymbol ${_formatAmount(closing)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: closing >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      netLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '$currencySymbol ${_formatAmount(net)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: netColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, String symbol) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          '$symbol ${_formatAmount(value)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  // ==================== BUDGET LIST ====================
  Widget _buildBudgetList(Box<BudgetModel> budgetBox) {
    final allBudgets = budgetBox.values.toList();
    final budgets = allBudgets
        .where((b) => b.month == _selectedMonth && (b.type ?? 'Expense') == _budgetType)
        .toList();

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
  }

  // ==================== WIDGETS ====================
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${_formatAmount(totalSpent)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const Text(' / ', style: TextStyle(color: Colors.white70, fontSize: 22)),
              Text('${_formatAmount(totalBudget)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
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
    final allCats = _categoryService.allCategories;
    var category = allCats.firstWhere(
      (c) => c['key'] == budget.category,
      orElse: () => {
        'key': 'other',
        'icon': Icons.more_horiz,
        'color': Colors.grey,
        'isCustom': false,
        'id': '',
      },
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
                      Text('${getText('budget')}: ${_formatAmount(budget.budgetAmount)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatAmount(budget.spentAmount),
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
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ]),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
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
                Text('${getText('remaining')}: ${_formatAmount(budget.remainingAmount)}',
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
                        '${getText('budget_exceeded')}! ${getText('overspent')} ${_formatAmount(budget.spentAmount - budget.budgetAmount)}',
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
        return getText('overspent');
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

  // ==================== BUDGET DIALOGS ====================
  void _showAddBudgetDialog() {
    String selectedCategory = _budgetType == 'Income' ? 'salary' : 'gas_bill';
    final amountController = TextEditingController();
    String selectedPeriod = 'monthly';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${_budgetType == 'Income' ? getText('income') : getText('expense')} ${getText('add_budget')}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryDropdown(
                  selectedValue: selectedCategory,
                  onChanged: (newValue) => setDialogState(() => selectedCategory = newValue),
                  hintText: getText('select_category'),
                  showAddNew: true,
                  filterType: _budgetType,
                  getTranslatedName: (key) => getCategoryName(key),
                  addNewCategoryText: getText('add_new_category'),
                  dialogTitle: getText('add_new_category_dialog_title'),
                  categoryNameLabel: getText('category_name'),
                  addButtonText: getText('add'),
                  cancelButtonText: getText('cancel'),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯٠-٩]+\.?[0-9০-৯٠-٩]*')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      String converted = _convertToScriptDigits(newValue.text);
                      return newValue.copyWith(
                        text: converted,
                        selection: TextSelection.collapsed(offset: converted.length),
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    labelText: getText('budget_amount'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.money),
                  ),
                ),
                const SizedBox(height: 15),

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
                        DropdownMenuItem(value: 'monthly', child: Text(getText('monthly'))),
                        DropdownMenuItem(value: 'weekly', child: Text(getText('weekly'))),
                        DropdownMenuItem(value: 'yearly', child: Text(getText('yearly'))),
                      ],
                      onChanged: (v) => setDialogState(() => selectedPeriod = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(getText('cancel'))),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  final rawAmount = _convertToEnglishDigits(amountController.text);
                  double? amount = double.tryParse(rawAmount);
                  if (amount != null && amount > 0) {
                    BudgetModel budget = BudgetModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      category: selectedCategory,
                      budgetAmount: amount,
                      spentAmount: 0,
                      period: selectedPeriod,
                      month: _selectedMonth,
                      isActive: true,
                      type: _budgetType,
                    );
                    _db.addBudget(budget);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${getCategoryName(selectedCategory)} - ${getText('budget_added_success')}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {});
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

  void _showEditBudgetDialog(BudgetModel budget) {
    final amountController = TextEditingController(
      text: _convertToScriptDigits(budget.budgetAmount.toStringAsFixed(0)),
    );
    String selectedCategory = budget.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${getText('edit_budget')} - ${budget.type == 'Income' ? getText('income') : getText('expense')}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryDropdown(
                  selectedValue: selectedCategory,
                  onChanged: (newValue) => setDialogState(() => selectedCategory = newValue),
                  hintText: getText('select_category'),
                  showAddNew: true,
                  filterType: budget.type ?? 'Expense',
                  getTranslatedName: (key) => getCategoryName(key),
                  addNewCategoryText: getText('add_new_category'),
                  dialogTitle: getText('add_new_category_dialog_title'),
                  categoryNameLabel: getText('category_name'),
                  addButtonText: getText('add'),
                  cancelButtonText: getText('cancel'),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯٠-٩]+\.?[0-9০-৯٠-٩]*')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      String converted = _convertToScriptDigits(newValue.text);
                      return newValue.copyWith(
                        text: converted,
                        selection: TextSelection.collapsed(offset: converted.length),
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    labelText: getText('budget_amount'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.money),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(getText('cancel'))),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  final rawAmount = _convertToEnglishDigits(amountController.text);
                  double? amount = double.tryParse(rawAmount);
                  if (amount != null && amount > 0) {
                    _db.updateBudget(budget.id, {
                      'budgetAmount': amount,
                      'category': selectedCategory,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(getText('budget_updated_success')), backgroundColor: Colors.green),
                    );
                    setState(() {});
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
              child: Text(getText('update')),
            ),
          ],
        ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(getText('budget_deleted_success')), backgroundColor: Colors.red),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(getText('yes'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}