import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/local_database_service.dart';
import '../models/transaction_model.dart';

class YearlyStatsScreen extends StatefulWidget {
  final String selectedLanguage;
  final Map<String, Map<String, String>> localizedText;

  const YearlyStatsScreen({
    super.key,
    required this.selectedLanguage,
    required this.localizedText,
  });

  @override
  State<YearlyStatsScreen> createState() => _YearlyStatsScreenState();
}

class _YearlyStatsScreenState extends State<YearlyStatsScreen> {
  int _selectedYear = DateTime.now().year;

  String getText(String key) {
    return widget.localizedText[widget.selectedLanguage]?[key] ??
        widget.localizedText['bn']?[key] ??
        key;
  }

  String _getMonthName(int month) {
    final date = DateTime(_selectedYear, month);
    String locale;
    if (widget.selectedLanguage == 'bn') {
      locale = 'bn_BD';
    } else if (widget.selectedLanguage == 'ar') {
      locale = 'ar_SA';
    } else {
      locale = 'en_US';
    }
    return DateFormat('MMM', locale).format(date);
  }

  List<Color> get _monthColors => [
    Colors.red.shade300,
    Colors.orange.shade300,
    Colors.amber.shade300,
    Colors.lime.shade300,
    Colors.lightGreen.shade300,
    Colors.green.shade300,
    Colors.teal.shade300,
    Colors.cyan.shade300,
    Colors.blue.shade300,
    Colors.indigo.shade300,
    Colors.purple.shade300,
    Colors.pink.shade300,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(getText('yearly_stats'), style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.purple.shade700]),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final transactions = box.values.toList();
          double yearlyInc = 0, yearlyExp = 0;
          Map<int, double> monthInc = {};
          Map<int, double> monthExp = {};

          for (var tx in transactions) {
            final dateStr = tx.date ?? '';
            if (dateStr.contains(_selectedYear.toString())) {
              try {
                final parts = dateStr.split('/');
                if (parts.length >= 2) {
                  final month = int.parse(parts[1]);
                  final amt = tx.amount;
                  if (tx.type == 'Income') {
                    yearlyInc += amt;
                    monthInc[month] = (monthInc[month] ?? 0) + amt;
                  } else if (tx.type == 'Expense') {
                    yearlyExp += amt;
                    monthExp[month] = (monthExp[month] ?? 0) + amt;
                  }
                }
              } catch (_) {}
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _yearPickerSection(),
                const SizedBox(height: 20),
                _summaryRow(yearlyInc, yearlyExp),
                const SizedBox(height: 20),
                _pieChartSection(yearlyInc, yearlyExp),
                const SizedBox(height: 20),
                _tableHeader(),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    return _monthRow(
                      _getMonthName(month),
                      monthInc[month] ?? 0,
                      monthExp[month] ?? 0,
                      _monthColors[index],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _totalFooter(yearlyInc, yearlyExp),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _yearPickerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedYear,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.calendar_today),
        ),
        items: List.generate(10, (i) => DateTime.now().year - 5 + i)
            .map((y) => DropdownMenuItem(
          value: y,
          child: Text("${getText('year_report')} $y", style: const TextStyle(fontWeight: FontWeight.w500)),
        ))
            .toList(),
        onChanged: (v) => setState(() => _selectedYear = v!),
      ),
    );
  }

  Widget _summaryRow(double inc, double exp) {
    return Row(
      children: [
        _summaryCard(getText('total_income'), inc, Colors.green),
        const SizedBox(width: 12),
        _summaryCard(getText('total_expense'), exp, Colors.red),
        const SizedBox(width: 12),
        _summaryCard(getText('savings'), inc - exp, Colors.blue),
      ],
    );
  }

  Widget _summaryCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 4),
            Text("৳ ${amount.toInt()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _pieChartSection(double inc, double exp) {
    final total = inc + exp;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(getText('income_expense_ratio'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _pieChart(getText('income'), inc, total, Colors.green)),
              Expanded(child: _pieChart(getText('expense'), exp, total, Colors.red)),
              Expanded(child: _pieChart(getText('balance'), inc - exp, inc, Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pieChart(String label, double value, double total, Color color) {
    final percent = total > 0 ? (value / total) * 100 : 0;
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: 70,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: value.abs(),
                  color: color,
                  radius: 30,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (total - value).abs(),
                  color: Colors.grey.shade100,
                  radius: 30,
                  showTitle: false,
                ),
              ],
              centerSpaceRadius: 18,
              sectionsSpace: 0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        Text("${percent.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
      ],
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.purple.shade700]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(getText('month'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text(getText('income_label'), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text(getText('expense_label'), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _monthRow(String monthName, double inc, double exp, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: Text(monthName.isNotEmpty ? monthName[0] : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(monthName, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13))),
          Expanded(child: Text("৳ ${inc.toInt()}", textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text("৳ ${exp.toInt()}", textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _totalFooter(double inc, double exp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.purple.shade700]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(getText('total_label'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          Expanded(child: Text("৳ ${inc.toInt()}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text("৳ ${exp.toInt()}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}