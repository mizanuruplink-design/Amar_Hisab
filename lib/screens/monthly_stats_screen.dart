import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart'; // নিশ্চিত করুন এই ফাইলটি আছে

class MonthlyStatsScreen extends StatefulWidget {
  const MonthlyStatsScreen({super.key});

  @override
  State<MonthlyStatsScreen> createState() => _MonthlyStatsScreenState();
}

class _MonthlyStatsScreenState extends State<MonthlyStatsScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _filterStatus = "সব লেনদেন";

  @override
  Widget build(BuildContext context) {
    String monthFilter = DateFormat('MM/yyyy').format(_selectedMonth);
    String displayMonth = DateFormat('MMMM, yyyy').format(_selectedMonth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("মাসিক আয়/ব্যয়ের পরিসংখ্যান", style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: DatabaseService().getTransactions(),
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          double totalInc = 0, totalExp = 0;
          List<Map<dynamic, dynamic>> filteredList = [];

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map data = snapshot.data!.snapshot.value as Map;
            data.forEach((key, value) {
              if (value['date'].toString().contains(monthFilter)) {
                double amt = double.tryParse(value['amount'].toString()) ?? 0;
                if (value['type'] == 'Income') totalInc += amt;
                if (value['type'] == 'Expense') totalExp += amt;

                // ফিল্টার লজিক
                if (_filterStatus == "সব লেনদেন") {
                  filteredList.add(value);
                } else if (_filterStatus == "শুধু ক্যাশ ইন" && value['type'] == 'Income') {
                  filteredList.add(value);
                } else if (_filterStatus == "শুধু ক্যাশ আউট" && value['type'] == 'Expense') {
                  filteredList.add(value);
                }
              }
            });
          }

          return Column(
            children: [
              // ১. মাস নির্বাচন এবং পিডিএফ বাটন
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectMonth(context),
                        child: _topActionBox(Icons.calendar_month, displayMonth, Colors.red),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (filteredList.isNotEmpty) {
                            // PDF জেনারেট ফাংশন কল
                            PdfService().generatePdf(
                                filteredList,
                                "মাসিক রিপোর্ট: $displayMonth"
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("এই মাসের কোনো ডাটা নেই!"))
                            );
                          }
                        },
                        child: _topActionBox(Icons.description, "পিডিএফ এক্সপোর্ট", Colors.green),
                      ),
                    ),
                  ],
                ),
              ),

              // ২. সামারি সেকশন
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem("মোট আয়", "$totalInc", Colors.green),
                    _summaryItem("মোট ব্যয়", "$totalExp", Colors.orange),
                    _summaryItem("ব্যালেন্স", "${totalInc - totalExp}", Colors.blue),
                  ],
                ),
              ),

              const Divider(),

              // ৩. ফিল্টার হেডার
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("মাসিক আয়-ব্যয় ইতিহাস", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    DropdownButton<String>(
                      value: _filterStatus,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      items: ["সব লেনদেন", "শুধু ক্যাশ ইন", "শুধু ক্যাশ আউট"]
                          .map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) => setState(() => _filterStatus = val!),
                    ),
                  ],
                ),
              ),

              // ৪. ডাটা লিস্ট
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    bool isInc = item['type'] == 'Income';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      elevation: 0.5,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isInc ? Colors.green.shade50 : Colors.red.shade50,
                          child: Icon(isInc ? Icons.arrow_downward : Icons.arrow_upward, color: isInc ? Colors.green : Colors.red, size: 18),
                        ),
                        title: Text(item['note'] ?? "বিবরণ নেই", style: const TextStyle(fontSize: 14)),
                        subtitle: Text(item['date'] ?? "", style: const TextStyle(fontSize: 11)),
                        trailing: Text("${item['amount']} ৳", style: TextStyle(fontWeight: FontWeight.bold, color: isInc ? Colors.green : Colors.red)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // বাকি উইজেটগুলো (selectMonth, topActionBox, summaryItem, buildEmptyState) অপরিবর্তিত থাকবে
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      helpText: "মাস নির্বাচন করুন",
    );
    if (picked != null) setState(() => _selectedMonth = picked);
  }

  Widget _topActionBox(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        const SizedBox(height: 5),
        Text("$val ৳", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey.shade300),
          const Text("কোনো লেনদেন পাওয়া যায়নি", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}