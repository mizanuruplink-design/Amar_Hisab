import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/pdf_service.dart';
import '../models/transaction_model.dart';

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
  final PdfService _pdfService = PdfService();
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

            // Preview
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

  Widget _buildPreview() {
    final transactions = Hive.box<TransactionModel>('transactions').values.toList();
    double inc = 0, exp = 0, sav = 0, dbt = 0, crd = 0;
    int count = 0;

    for (var tx in transactions) {
      final type = tx.type.toLowerCase().trim();
      if (type != 'note' && type != 'reminder' && !tx.isArchived) {
        if (_isDateInSelectedMonth(tx.date ?? '')) {
          double amt = tx.amount;
          switch (type) {
            case 'income': inc += amt; break;
            case 'expense': exp += amt; break;
            case 'savings': sav += amt; break;
            case 'debt': dbt += amt; break;
            case 'credit': crd += amt; break;
          }
          count++;
        }
      }
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
  }

  bool _isDateInSelectedMonth(String dateStr) {
    if (dateStr.isEmpty) return false;
    try {
      final firstPart = dateStr.split(' ').first;
      final dateParts = firstPart.split('/');
      if (dateParts.length < 3) return false;
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);
      final selectedParts = _selectedMonth.split('-');
      int selectedYear = int.parse(selectedParts[0]);
      int selectedMonth = int.parse(selectedParts[1]);
      return month == selectedMonth && year == selectedYear;
    } catch (e) {
      return false;
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

  void _exportData() async {
    setState(() => _isExporting = true);

    try {
      final transactions = Hive.box<TransactionModel>('transactions').values.toList();
      List<Map<String, dynamic>> exportList = [];

      for (var tx in transactions) {
        final type = tx.type.toLowerCase().trim();
        if (type != 'note' && type != 'reminder' && !tx.isArchived) {
          if (_isDateInSelectedMonth(tx.date ?? '')) {
            exportList.add({
              'date': tx.date ?? '',
              'note': tx.note ?? '',
              'type': tx.type,
              'amount': tx.amount,
              'category': tx.category ?? '',
            });
          }
        }
      }

      if (exportList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(getText('no_data_export')), backgroundColor: Colors.orange),
          );
        }
        setState(() => _isExporting = false);
        return;
      }

      final file = await _pdfService.generatePdf(
        exportList,
        "${getText('app_title')} - ${_formatMonth()}",
      );

      if (mounted) _showExportSuccessDialog(file);
    } catch (e) {
      print('❌ Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${getText('export_error')}: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isExporting = false);
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
            onPressed: () { Navigator.pop(c); _pdfService.shareFile(file); },
            icon: const Icon(Icons.share),
            label: Text(getText('share')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(c); _pdfService.printPdf(file); },
            icon: const Icon(Icons.print),
            label: Text(getText('print')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }
}