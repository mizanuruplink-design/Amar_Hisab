// yearly_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';

class YearlyStatsScreen extends StatefulWidget {
  const YearlyStatsScreen({super.key});

  @override
  State<YearlyStatsScreen> createState() => _YearlyStatsScreenState();
}

class _YearlyStatsScreenState extends State<YearlyStatsScreen> {
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    "জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন",
    "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("বার্ষিক পরিসংখ্যান", style: TextStyle(fontSize: 18, color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: DatabaseService().getTransactions(),
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          double yearlyInc = 0, yearlyExp = 0;
          Map<int, double> monthIncMap = {};
          Map<int, double> monthExpMap = {};

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map data = snapshot.data!.snapshot.value as Map;
            data.forEach((key, value) {
              String dateStr = value['date'].toString();
              if (dateStr.contains(_selectedYear.toString())) {
                try {
                  // "dd/MM/yyyy" থেকে মাস বের করা
                  List<String> parts = dateStr.split('/');
                  int month = int.parse(parts[1]);
                  double amt = double.tryParse(value['amount'].toString()) ?? 0;

                  if (value['type'] == 'Income') {
                    yearlyInc += amt;
                    monthIncMap[month] = (monthIncMap[month] ?? 0) + amt;
                  } else {
                    yearlyExp += amt;
                    monthExpMap[month] = (monthExpMap[month] ?? 0) + amt;
                  }
                } catch (e) { /* Error handling */ }
              }
            });
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _yearPickerSection(),
                _chartSection(yearlyInc, yearlyExp),
                _tableHeader(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    int m = index + 1;
                    return _monthRow(_months[index], monthIncMap[m] ?? 0, monthExpMap[m] ?? 0, _getColor(index));
                  },
                ),
                _totalFooter(yearlyInc, yearlyExp),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _yearPickerSection() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: DropdownButtonFormField<int>(
        value: _selectedYear,
        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
        items: List.generate(10, (i) => DateTime.now().year - 5 + i)
            .map((y) => DropdownMenuItem(value: y, child: Text("$y সালের রিপোর্ট")))
            .toList(),
        onChanged: (v) => setState(() => _selectedYear = v!),
      ),
    );
  }

  Widget _chartSection(double inc, double exp) {
    double total = inc + exp;
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circularIndicator("আয়", inc, total, Colors.green),
          _circularIndicator("ব্যয়", exp, total, Colors.red),
          _circularIndicator("ব্যালেন্স", inc - exp, inc, Colors.blue),
        ],
      ),
    );
  }

  Widget _circularIndicator(String label, double val, double total, Color color) {
    double percent = (total > 0) ? (val / total) * 100 : 0;
    return Column(children: [
      SizedBox(
        height: 60, width: 60,
        child: PieChart(PieChartData(sections: [
          PieChartSectionData(value: val.abs(), color: color, radius: 6, showTitle: false),
          PieChartSectionData(value: (total - val).abs(), color: Colors.grey.shade100, radius: 6, showTitle: false),
        ], centerSpaceRadius: 20)),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 12)),
      Text("${percent.toStringAsFixed(0)}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
    ]);
  }

  Widget _tableHeader() {
    return Container(
      color: Colors.blue.shade800,
      padding: const EdgeInsets.all(10),
      child: const Row(children: [
        Expanded(flex: 2, child: Text("মাস", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        Expanded(child: Text("আয়", textAlign: TextAlign.right, style: TextStyle(color: Colors.white))),
        Expanded(child: Text("ব্যয়", textAlign: TextAlign.right, style: TextStyle(color: Colors.white))),
      ]),
    );


  }

  Widget _monthRow(String name, double inc, double exp, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(children: [
        Icon(Icons.circle, size: 10, color: c),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: Text(name)),
        Expanded(child: Text("${inc.toInt()}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.green))),
        Expanded(child: Text("${exp.toInt()}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.red))),
      ]),
    );
  }

  Widget _totalFooter(double inc, double exp) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(15),
      child: Row(children: [
        const Expanded(flex: 2, child: Text("মোট:", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text("${inc.toInt()} ৳", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text("${exp.toInt()} ৳", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Color _getColor(int i) => Colors.primaries[i % Colors.primaries.length];
}