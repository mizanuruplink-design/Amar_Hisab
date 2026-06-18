import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/pdf_service.dart';
import '../models/transaction_model.dart';

class DailyStatsScreen extends StatefulWidget {
  final String selectedLanguage;
  final Map<String, Map<String, String>> localizedText;

  const DailyStatsScreen({
    super.key,
    required this.selectedLanguage,
    required this.localizedText,
  });

  @override
  State<DailyStatsScreen> createState() => _DailyStatsScreenState();
}

class _DailyStatsScreenState extends State<DailyStatsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'all';
  bool _isExporting = false;

  // ==================== DIGIT CONVERSION HELPERS ====================
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
    return widget.localizedText[widget.selectedLanguage]?[key] ??
        widget.localizedText['bn']?[key] ??
        key;
  }

  String _getFormattedDate(DateTime date) {
    String locale;
    if (widget.selectedLanguage == 'bn') {
      locale = 'bn_BD';
    } else if (widget.selectedLanguage == 'ar') {
      locale = 'ar_SA';
    } else {
      locale = 'en_US';
    }
    return DateFormat('EEEE, d MMMM yyyy', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final String displayDate = _getFormattedDate(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(getText('daily_stats'), style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final allTransactions = box.values.toList();
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
                            locale: Locale(widget.selectedLanguage), // ✅ ভাষা সাপোর্ট
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.picture_as_pdf,
                        label: _isExporting ? getText('saving') : getText('pdf'),
                        color: Colors.green,
                        onTap: _isExporting
                            ? null
                            : () {
                          if (filteredList.isNotEmpty) {
                            _exportToPdf(filteredList, formattedDate);
                          } else {
                            _showSnackBar(getText('no_transactions'));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Summary cards (ডিজিট কনভার্ট সহ)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _summaryCard(getText('total_income'), totalIncome, Colors.green),
                    const SizedBox(width: 12),
                    _summaryCard(getText('total_expense'), totalExpense, Colors.red),
                    const SizedBox(width: 12),
                    _summaryCard(getText('savings'), totalIncome - totalExpense, Colors.blue),
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
                    Text(getText('transaction_history'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    DropdownButton<String>(
                      value: _filterType,
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(getText('all'))),
                        DropdownMenuItem(value: 'income', child: Text(getText('income'))),
                        DropdownMenuItem(value: 'expense', child: Text(getText('expense'))),
                      ],
                      onChanged: (v) => setState(() => _filterType = v!),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.filter_list),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Transaction list (ডিজিট কনভার্ট সহ)
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
                          child: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(tx.note ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(displayDateOnly),
                        trailing: Text(
                          "${_formatAmount(tx.amount)}", // ✅ ডিজিট কনভার্ট
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

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
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
            Text(
              _formatAmount(amount), // ✅ ডিজিট কনভার্ট
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
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
          Text(getText('no_transactions'), style: TextStyle(color: Colors.grey[600])),
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

      final pdfFile = await PdfService().generatePdf(exportData, "${getText('daily_report')}: $date");
      if (mounted) {
        _showExportSuccessDialog(pdfFile);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("${getText('pdf_failed')}: $e");
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportSuccessDialog(File file) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(getText('export_success')),
        content: Text(getText('pdf_created_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(getText('close')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(c);
              PdfService().shareFile(file);
            },
            icon: const Icon(Icons.share),
            label: Text(getText('share')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(c);
              PdfService().printPdf(file);
            },
            icon: const Icon(Icons.print),
            label: Text(getText('print')),
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