import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../services/export_service.dart';
import 'package:firebase_database/firebase_database.dart';

class ExportScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedCurrency;
  final String currencySymbol;
  final Map<String, Map<String, String>> localizedText;

  const ExportScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedCurrency,
    required this.currencySymbol,
    required this.localizedText,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final DatabaseService _db = DatabaseService();
  final ExportService _exportService = ExportService();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String _exportFormat = 'pdf';
  bool _isExporting = false;

  String getText(String key) => widget.localizedText[widget.selectedLanguage]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Text(getText('export_report'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(getText('select_period'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              final parts = _selectedMonth.split('-');
                              int y = int.parse(parts[0]), m = int.parse(parts[1]);
                              if (m == 1) { y--; m = 12; } else { m--; }
                              setState(() => _selectedMonth = '$y-${m.toString().padLeft(2, '0')}');
                            },
                          ),
                          Expanded(
                            child: Text(
                              _formatMonth(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              final parts = _selectedMonth.split('-');
                              int y = int.parse(parts[0]), m = int.parse(parts[1]);
                              if (m == 12) { y++; m = 1; } else { m++; }
                              setState(() => _selectedMonth = '$y-${m.toString().padLeft(2, '0')}');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Format Selector
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(getText('export_format'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildFormatCard('PDF', Icons.picture_as_pdf, Colors.red, 'pdf')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildFormatCard('Excel', Icons.table_chart, Colors.green, 'excel')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Preview with Real Data
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPreview(),
              ),
            ),
            const SizedBox(height: 24),

            // Export Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportData,
                icon: _isExporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.download, size: 28),
                label: Text(
                  _isExporting ? getText('exporting') : getText('export_now'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Preview with correct date filtering
  Widget _buildPreview() {
    return StreamBuilder<DatabaseEvent>(
      stream: _db.getTransactions(),
      builder: (context, snapshot) {
        double inc = 0, exp = 0, sav = 0, dbt = 0, crd = 0;
        int count = 0;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          data.forEach((k, v) {
            if (v != null) {
              final tx = Map<String, dynamic>.from(v);
              final type = tx['type'] ?? '';

              if (type != 'Note' && type != 'Reminder' && !(tx['isArchived'] ?? false)) {
                final dateStr = tx['date']?.toString() ?? '';

                // ✅ FIX: Parse date properly and compare month
                if (_isDateInSelectedMonth(dateStr)) {
                  double amt = 0;
                  final raw = tx['amount'];
                  if (raw is double) amt = raw;
                  else if (raw is int) amt = raw.toDouble();
                  else if (raw is String) amt = double.tryParse(raw) ?? 0;

                  switch (type) {
                    case 'Income': inc += amt; break;
                    case 'Expense': exp += amt; break;
                    case 'Savings': sav += amt; break;
                    case 'Debt': dbt += amt; break;
                    case 'Credit': crd += amt; break;
                  }
                  count++;
                }
              }
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(getText('preview'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildPreviewRow(getText('income'), inc, Colors.green),
            _buildPreviewRow(getText('expense'), exp, Colors.red),
            _buildPreviewRow(getText('savings'), sav, Colors.blue),
            _buildPreviewRow(getText('debt'), dbt, Colors.orange),
            _buildPreviewRow(getText('credit'), crd, Colors.purple),
            const Divider(),
            _buildPreviewRow(getText('balance'), inc - exp, Colors.teal),
            const SizedBox(height: 8),
            Text('${getText('total')}: $count ${getText('transactions')}', style: TextStyle(color: Colors.grey[600])),
          ],
        );
      },
    );
  }

  // ✅ FIXED: Date comparison helper
  bool _isDateInSelectedMonth(String dateStr) {
    try {
      // Try format: dd/MM/yyyy hh:mm a
      final date = DateFormat('dd/MM/yyyy').parse(dateStr.split(' ').first);
      final selectedDate = DateFormat('yyyy-MM').parse(_selectedMonth);

      return date.month == selectedDate.month && date.year == selectedDate.year;
    } catch (e) {
      // Try format: dd/MM/yyyy
      try {
        final date = DateFormat('dd/MM/yyyy').parse(dateStr);
        final selectedDate = DateFormat('yyyy-MM').parse(_selectedMonth);
        return date.month == selectedDate.month && date.year == selectedDate.year;
      } catch (e2) {
        return false;
      }
    }
  }

  Widget _buildFormatCard(String title, IconData icon, Color color, String format) {
    bool isSelected = _exportFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _exportFormat = format),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('${widget.currencySymbol} ${amount.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _formatMonth() {
    final parts = _selectedMonth.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMMM yyyy').format(date);
  }

  // ✅ FIXED: Export with correct date filtering
  void _exportData() async {
    setState(() => _isExporting = true);

    try {
      double inc = 0, exp = 0, sav = 0, dbt = 0, crd = 0;
      List<Map<String, dynamic>> txList = [];

      final snapshot = await _db.getTransactions().first;
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((k, v) {
          if (v != null) {
            final tx = Map<String, dynamic>.from(v);
            final type = tx['type'] ?? '';

            if (type != 'Note' && type != 'Reminder' && !(tx['isArchived'] ?? false)) {
              final dateStr = tx['date']?.toString() ?? '';

              // ✅ FIX: Use same date checking logic
              if (_isDateInSelectedMonth(dateStr)) {
                double amt = 0;
                final raw = tx['amount'];
                if (raw is double) amt = raw;
                else if (raw is int) amt = raw.toDouble();
                else if (raw is String) amt = double.tryParse(raw) ?? 0;

                tx['amount'] = amt;
                tx['key'] = k.toString();

                switch (type) {
                  case 'Income': inc += amt; break;
                  case 'Expense': exp += amt; break;
                  case 'Savings': sav += amt; break;
                  case 'Debt': dbt += amt; break;
                  case 'Credit': crd += amt; break;
                }
                txList.add(tx);
              }
            }
          }
        });
      }

      print('✅ Found ${txList.length} transactions for $_selectedMonth');
      print('✅ Income: $inc, Expense: $exp');

      if (txList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getText('no_data_export')), backgroundColor: Colors.orange),
        );
        setState(() => _isExporting = false);
        return;
      }

      final file = await _exportService.generatePdfReport(
        title: getText('app_title'),
        period: _formatMonth(),
        totalIncome: inc,
        totalExpense: exp,
        totalSavings: sav,
        totalDebt: dbt,
        totalCredit: crd,
        transactions: txList,
        currencySymbol: widget.currencySymbol,
        language: widget.selectedLanguage,
      );

      _showExportSuccessDialog(file);
    } catch (e) {
      print('❌ Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${getText('export_error')}: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isExporting = false);
  }

  void _showExportSuccessDialog(File file) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(getText('export_success')),
        content: Text(getText('export_success_msg')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(getText('cancel'))),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(c); _exportService.shareFile(file); },
            icon: const Icon(Icons.share),
            label: Text(getText('share')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(c); _exportService.printPdf(file); },
            icon: const Icon(Icons.print),
            label: Text(getText('print')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }
}