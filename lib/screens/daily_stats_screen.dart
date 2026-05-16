import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart'; // নিশ্চিত করুন এই ইম্পোর্টটি আছে

class DailyStatsScreen extends StatefulWidget {
  const DailyStatsScreen({super.key});

  @override
  State<DailyStatsScreen> createState() => _DailyStatsScreenState();
}

class _DailyStatsScreenState extends State<DailyStatsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _filterStatus = "সব লেনদেন";

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("দৈনিক আয়/ব্যয়ের পরিসংখ্যান", style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: DatabaseService().getTransactions(),
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          double totalInc = 0, totalExp = 0;
          List<Map<dynamic, dynamic>> allDailyList = []; // PDF এর জন্য সব ডাটা
          List<Map<dynamic, dynamic>> filteredList = []; // স্ক্রিনে দেখানোর জন্য ফিল্টারড ডাটা

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map data = snapshot.data!.snapshot.value as Map;
            data.forEach((key, value) {
              // তারিখ চেক (আপনার ডাটাবেস ফরম্যাট অনুযায়ী)
              if (value['date'].toString().contains(formattedDate)) {
                double amt = double.tryParse(value['amount'].toString()) ?? 0;

                if (value['type'] == 'Income') totalInc += amt;
                if (value['type'] == 'Expense') totalExp += amt;

                // PDF এর জন্য সব ডাটা সেভ করছি
                allDailyList.add(value);

                // ড্রপডাউন ফিল্টার লজিক
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
              // ১. ডেট পিকার এবং পিডিএফ বাটন
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: _topActionBox(Icons.calendar_month, formattedDate, Colors.red),
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
                                "দৈনিক রিপোর্ট: $formattedDate"
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("এক্সপোর্ট করার মতো কোনো ডাটা নেই!"))
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem("মোট আয়", "$totalInc", Colors.green),
                    _summaryItem("মোট ব্যয়", "$totalExp", Colors.orange),
                    _summaryItem("ব্যালেন্স", "${totalInc - totalExp}", Colors.blue),
                  ],
                ),
              ),

              // ৩. ফিল্টার ও লিস্ট হেডার
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("দৈনিক আয়-ব্যয় ইতিহাস", style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _filterStatus,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.filter_list, size: 20),
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
                    return ListTile(
                      leading: Icon(
                        item['type'] == 'Income' ? Icons.arrow_downward : Icons.arrow_upward,
                        color: item['type'] == 'Income' ? Colors.green : Colors.red,
                      ),
                      title: Text(item['note'] ?? "নো ট্যাগ"),
                      subtitle: Text(item['date']),
                      trailing: Text(
                        "${item['amount']} ৳",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item['type'] == 'Income' ? Colors.green : Colors.red
                        ),
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

  Widget _topActionBox(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const Text("কোনো তথ্য পাওয়া যায়নি", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}