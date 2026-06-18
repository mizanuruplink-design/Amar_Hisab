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
    final translated = widget.localizedText[widget.selectedLanguage]?[key];
    if (translated != null && translated.isNotEmpty) return translated;

    // Fallback
    switch (key) {
      case 'export_report':
        if (widget.selectedLanguage == 'bn') return 'এক্সপোর্ট রিপোর্ট';
        if (widget.selectedLanguage == 'ar') return 'تقرير التصدير';
        return 'Export Report';
      case 'select_period':
        if (widget.selectedLanguage == 'bn') return 'সময়কাল নির্বাচন করুন';
        if (widget.selectedLanguage == 'ar') return 'اختر الفترة';
        return 'Select Period';
      case 'export_format':
        if (widget.selectedLanguage == 'bn') return 'এক্সপোর্ট ফরম্যাট';
        if (widget.selectedLanguage == 'ar') return 'تنسيق التصدير';
        return 'Export Format';
      case 'preview':
        if (widget.selectedLanguage == 'bn') return 'প্রিভিউ';
        if (widget.selectedLanguage == 'ar') return 'معاينة';
        return 'Preview';
      case 'export_now':
        if (widget.selectedLanguage == 'bn') return 'এখন এক্সপোর্ট করুন';
        if (widget.selectedLanguage == 'ar') return 'تصدير الآن';
        return 'Export Now';
      case 'exporting':
        if (widget.selectedLanguage == 'bn') return 'এক্সপোর্ট হচ্ছে...';
        if (widget.selectedLanguage == 'ar') return 'جاري التصدير...';
        return 'Exporting...';
      case 'no_data_export':
        if (widget.selectedLanguage == 'bn') return 'এক্সপোর্ট করার মতো কোনো ডেটা নেই';
        if (widget.selectedLanguage == 'ar') return 'لا توجد بيانات للتصدير';
        return 'No data to export';
      case 'export_error':
        if (widget.selectedLanguage == 'bn') return 'এক্সপোর্ট ত্রুটি';
        if (widget.selectedLanguage == 'ar') return 'خطأ في التصدير';
        return 'Export error';
      case 'export_success':
        if (widget.selectedLanguage == 'bn') return 'এক্সপোর্ট সফল';
        if (widget.selectedLanguage == 'ar') return 'تم التصدير بنجاح';
        return 'Export Successful';
      case 'export_success_msg':
        if (widget.selectedLanguage == 'bn') return 'পিডিএফ ফাইল তৈরি হয়েছে। আপনি শেয়ার বা প্রিন্ট করতে পারেন।';
        if (widget.selectedLanguage == 'ar') return 'تم إنشاء ملف PDF. يمكنك مشاركته أو طباعته.';
        return 'PDF file created. You can share or print it.';
      case 'income':
        if (widget.selectedLanguage == 'bn') return 'আয়';
        if (widget.selectedLanguage == 'ar') return 'دخل';
        return 'Income';
      case 'expense':
        if (widget.selectedLanguage == 'bn') return 'ব্যয়';
        if (widget.selectedLanguage == 'ar') return 'مصروف';
        return 'Expense';
      case 'savings':
        if (widget.selectedLanguage == 'bn') return 'সঞ্চয়';
        if (widget.selectedLanguage == 'ar') return 'مدخرات';
        return 'Savings';
      case 'debt':
        if (widget.selectedLanguage == 'bn') return 'দেনা';
        if (widget.selectedLanguage == 'ar') return 'دين';
        return 'Debt';
      case 'credit':
        if (widget.selectedLanguage == 'bn') return 'পাওনা';
        if (widget.selectedLanguage == 'ar') return 'ائتمان';
        return 'Credit';
      case 'balance':
        if (widget.selectedLanguage == 'bn') return 'ব্যালেন্স';
        if (widget.selectedLanguage == 'ar') return 'رصيد';
        return 'Balance';
      case 'total':
        if (widget.selectedLanguage == 'bn') return 'মোট';
        if (widget.selectedLanguage == 'ar') return 'الإجمالي';
        return 'Total';
      case 'transactions':
        if (widget.selectedLanguage == 'bn') return 'লেনদেন';
        if (widget.selectedLanguage == 'ar') return 'معاملات';
        return 'Transactions';
      case 'share':
        if (widget.selectedLanguage == 'bn') return 'শেয়ার';
        if (widget.selectedLanguage == 'ar') return 'مشاركة';
        return 'Share';
      case 'print':
        if (widget.selectedLanguage == 'bn') return 'প্রিন্ট';
        if (widget.selectedLanguage == 'ar') return 'طباعة';
        return 'Print';
      case 'cancel':
        if (widget.selectedLanguage == 'bn') return 'বাতিল';
        if (widget.selectedLanguage == 'ar') return 'إلغاء';
        return 'Cancel';
      default:
        return widget.localizedText['bn']?[key] ?? key;
    }
  }

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

            // Preview (ডিজিট কনভার্ট সহ)
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

  // ==================== BUILD HELPERS ====================
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

  Widget _buildPreviewRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${widget.currencySymbol} ${_formatAmount(amount)}', // ✅ ডিজিট কনভার্ট
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
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

  // ==================== HELPERS ====================
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

  String _formatMonth() {
    final parts = _selectedMonth.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    // লোকেল অনুযায়ী মাসের নাম
    String locale = widget.selectedLanguage == 'bn' ? 'bn_BD' :
                    widget.selectedLanguage == 'ar' ? 'ar_SA' : 'en_US';
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  // ==================== EXPORT LOGIC ====================
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