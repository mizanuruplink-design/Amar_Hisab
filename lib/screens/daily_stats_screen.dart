import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../models/transaction_model.dart';

class DailyStatsScreen extends StatefulWidget {
  const DailyStatsScreen({super.key});

  @override
  State<DailyStatsScreen> createState() => _DailyStatsScreenState();
}

class _DailyStatsScreenState extends State<DailyStatsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'all';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final String displayDate = DateFormat('EEEE, d MMMM yyyy', 'bn').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("দৈনিক পরিসংখ্যান", style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
          ),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: DatabaseService().transactionsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTransactions = snapshot.data!;
          final todayTxs = allTransactions.where((tx) {
            final datePart = tx.date?.split(' ').first ?? '';
            if (datePart != formattedDate) return false;
            return tx.type == 'Income' || tx.type == 'Expense';
          }).toList();

          double totalIncome = 0, totalExpense = 0;
          for (var tx in todayTxs) {
            if (tx.type == 'Income') totalIncome += tx.amount;
            else if (tx.type == 'Expense') totalExpense += tx.amount;
          }

          List<TransactionModel> filteredList = todayTxs;
          if (_filterType == 'income') {
            filteredList = todayTxs.where((t) => t.type == 'Income').toList();
          } else if (_filterType == 'expense') {
            filteredList = todayTxs.where((t) => t.type == 'Expense').toList();
          }

          return Column(
            children: [
              // Date picker + PDF export
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.calendar_month,
                        label: displayDate,
                        color: Colors.red,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.picture_as_pdf,
                        label: _isExporting ? "সেভ হচ্ছে..." : "PDF",
                        color: Colors.green,
                        onTap: _isExporting ? null : () {
                          if (filteredList.isNotEmpty) {
                            _exportToPdf(filteredList, formattedDate);
                          } else {
                            _showSnackBar("কোনো লেনদেন নেই");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Summary cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _summaryCard("মোট আয়", totalIncome, Colors.green),
                    const SizedBox(width: 12),
                    _summaryCard("মোট ব্যয়", totalExpense, Colors.red),
                    const SizedBox(width: 12),
                    _summaryCard("সঞ্চয়", totalIncome - totalExpense, Colors.blue),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Filter row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("লেনদেন ইতিহাস", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    DropdownButton<String>(
                      value: _filterType,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text("সব")),
                        DropdownMenuItem(value: 'income', child: Text("শুধু আয়")),
                        DropdownMenuItem(value: 'expense', child: Text("শুধু ব্যয়")),
                      ],
                      onChanged: (v) => setState(() => _filterType = v!),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.filter_list),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Transaction list
              Expanded(
                child: filteredList.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredList.length,
                  itemBuilder: (context, i) {
                    final tx = filteredList[i];
                    final isIncome = tx.type == 'Income';
                    String displayDateOnly = '';
                    if (tx.date != null && tx.date!.isNotEmpty) {
                      final parts = tx.date!.split(' ');
                      displayDateOnly = parts.isNotEmpty ? parts[0] : '';
                    }
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red),
                        ),
                        title: Text(tx.note ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(displayDateOnly),
                        trailing: Text(
                          "৳ ${tx.amount.toInt()}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                            fontSize: 16,
                          ),
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

  Widget _buildActionCard({required IconData icon, required String label, required Color color, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text("কোনো লেনদেন নেই", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _exportToPdf(List<TransactionModel> transactions, String date) async {
    setState(() => _isExporting = true);

    try {
      final exportData = transactions.map((tx) {
        return {
          'note': tx.note ?? '',
          'amount': tx.amount,
          'type': tx.type,
          'date': tx.date ?? '',
          'category': tx.category ?? '',
        };
      }).toList();

      final pdfFile = await PdfService().generatePdf(exportData, "দৈনিক রিপোর্ট: $date");
      if (mounted) {
        _showExportSuccessDialog(pdfFile);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("PDF তৈরি করতে ব্যর্থ: $e");
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportSuccessDialog(File file) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("এক্সপোর্ট সফল"),
        content: const Text("পিডিএফ ফাইল তৈরি হয়েছে। আপনি শেয়ার বা প্রিন্ট করতে পারেন।"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("বন্ধ করুন"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(c);
              PdfService().shareFile(file);
            },
            icon: const Icon(Icons.share),
            label: const Text("শেয়ার"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(c);
              PdfService().printPdf(file);
            },
            icon: const Icon(Icons.print),
            label: const Text("প্রিন্ট"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}