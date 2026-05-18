import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';

class YearlyStatsScreen extends StatefulWidget {
  const YearlyStatsScreen({super.key});

  @override
  State<YearlyStatsScreen> createState() => _YearlyStatsScreenState();
}

class _YearlyStatsScreenState extends State<YearlyStatsScreen> {
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    "জানু", "ফেব্রু", "মার্চ", "এপ্রিল", "মে", "জুন",
    "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর"
  ];

  final List<Color> _monthColors = [
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
        title: const Text("বার্ষিক পরিসংখ্যান", style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.purple.shade700]),
          ),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: DatabaseService().transactionsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;
          double yearlyInc = 0, yearlyExp = 0;
          Map<int, double> monthInc = {};
          Map<int, double> monthExp = {};

          for (var tx in transactions) {
            final dateStr = tx.date ?? '';
            if (dateStr.contains(_selectedYear.toString())) {
              try {
                // Date format expected: dd/MM/yyyy hh:mm a
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
                      _months[index],
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
        decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.calendar_today)),
        items: List.generate(10, (i) => DateTime.now().year - 5 + i)
            .map((y) => DropdownMenuItem(value: y, child: Text("$y সালের রিপোর্ট", style: const TextStyle(fontWeight: FontWeight.w500))))
            .toList(),
        onChanged: (v) => setState(() => _selectedYear = v!),
      ),
    );
  }

  Widget _summaryRow(double inc, double exp) {
    return Row(
      children: [
        _summaryCard("মোট আয়", inc, Colors.green),
        const SizedBox(width: 12),
        _summaryCard("মোট ব্যয়", exp, Colors.red),
        const SizedBox(width: 12),
        _summaryCard("সঞ্চয়", inc - exp, Colors.blue),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          const Text("আয়-ব্যয়ের অনুপাত", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pieChart("আয়", inc, total, Colors.green),
                _pieChart("ব্যয়", exp, total, Colors.red),
                _pieChart("ব্যালেন্স", inc - exp, inc, Colors.blue),
              ],
            ),
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
          height: 90,
          width: 90,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: value.abs(),
                  color: color,
                  radius: 40,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (total - value).abs(),
                  color: Colors.grey.shade100,
                  radius: 40,
                  showTitle: false,
                ),
              ],
              centerSpaceRadius: 25,
              sectionsSpace: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text("${percent.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
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
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text("মাস", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text("আয়", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text("ব্যয়", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _monthRow(String name, double inc, double exp, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: color, child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
          Expanded(child: Text("৳ ${inc.toInt()}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
          Expanded(child: Text("৳ ${exp.toInt()}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _totalFooter(double inc, double exp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.purple.shade700]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(flex: 2, child: Text("মোট:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          Expanded(child: Text("৳ ${inc.toInt()}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text("৳ ${exp.toInt()}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}