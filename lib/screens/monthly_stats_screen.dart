import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../models/transaction_model.dart';

class MonthlyStatsScreen extends StatefulWidget {
  final String selectedLanguage;
  final Map<String, Map<String, String>> localizedText;

  const MonthlyStatsScreen({
    super.key,
    required this.selectedLanguage,
    required this.localizedText,
  });

  @override
  State<MonthlyStatsScreen> createState() => _MonthlyStatsScreenState();
}

class _MonthlyStatsScreenState extends State<MonthlyStatsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  String _filterType = 'all';
  bool _isExporting = false;

  String getText(String key) {
    return widget.localizedText[widget.selectedLanguage]?[key] ??
        widget.localizedText['bn']?[key] ??
        key;
  }

  String _formatDate(DateTime date) {
    String locale;
    if (widget.selectedLanguage == 'bn') {
      locale = 'bn_BD';
    } else if (widget.selectedLanguage == 'ar') {
      locale = 'ar_SA';
    } else {
      locale = 'en_US';
    }
    return DateFormat('dd/MM/yyyy', locale).format(date);
  }

  String _getDateRangeTitle() {
    return '${_formatDate(_startDate)} - ${_formatDate(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(getText('monthly_stats'), style: const TextStyle(fontSize: 18)),
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
          final filteredByDate = allTransactions.where((tx) {
            final datePart = tx.date?.split(' ').first ?? '';
            try {
              final txDate = DateFormat('dd/MM/yyyy').parse(datePart);
              return txDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                  txDate.isBefore(_endDate.add(const Duration(days: 1)));
            } catch (_) {
              return false;
            }
          }).toList();

          final List<TransactionModel> incomeExpenseTxs = filteredByDate
              .where((tx) => tx.type == 'Income' || tx.type == 'Expense')
              .toList();

          double totalIncome = 0, totalExpense = 0;
          for (var tx in incomeExpenseTxs) {
            if (tx.type == 'Income') totalIncome += tx.amount;
            else if (tx.type == 'Expense') totalExpense += tx.amount;
          }

          List<TransactionModel> filteredList = incomeExpenseTxs;
          if (_filterType == 'income') {
            filteredList = incomeExpenseTxs.where((t) => t.type == 'Income').toList();
          } else if (_filterType == 'expense') {
            filteredList = incomeExpenseTxs.where((t) => t.type == 'Expense').toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerCard(
                        label: getText('from_date'),
                        date: _startDate,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null && picked.isBefore(_endDate.add(const Duration(days: 1)))) {
                            setState(() => _startDate = picked);
                          } else if (picked != null) {
                            _showSnackBar(getText('start_date_before_end_date'));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePickerCard(
                        label: getText('to_date'),
                        date: _endDate,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null && picked.isAfter(_startDate.subtract(const Duration(days: 1)))) {
                            setState(() => _endDate = picked);
                          } else if (picked != null) {
                            _showSnackBar(getText('end_date_after_start_date'));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.picture_as_pdf,
                        label: _isExporting ? getText('saving') : getText('pdf'),
                        color: Colors.green,
                        onTap: _isExporting
                            ? null
                            : () {
                          if (filteredList.isNotEmpty) {
                            _exportToPdf(filteredList, _getDateRangeTitle());
                          } else {
                            _showSnackBar(getText('no_transactions'));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

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

  Widget _buildDatePickerCard({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(date),
              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
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
              "৳ ${amount.toInt()}",
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

  Future<void> _exportToPdf(List<TransactionModel> transactions, String period) async {
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

      final pdfFile = await PdfService().generatePdf(exportData, "${getText('monthly_report')}: $period");
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