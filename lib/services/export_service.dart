import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class ExportService {
  static pw.Font? _cachedBanglaFont;

  /// Load Bengali font (caches after first load)
  static Future<pw.Font?> _loadBanglaFont() async {
    if (_cachedBanglaFont != null) {
      print('✅ Bangla font already cached.');
      return _cachedBanglaFont;
    }
    try {
      print('🔄 Loading Bangla font from assets...');
      // 🟢 ফিক্সড: আপনার pubspec.yaml ফাইলের নামের সাথে মিলিয়ে NotoSansBengali-Regular.ttf করা হলো
      final fontData = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
      _cachedBanglaFont = pw.Font.ttf(fontData);
      print('✅ Bangla font loaded successfully!');
      return _cachedBanglaFont;
    } catch (e) {
      print('❌ Bangla font loading failed: $e');
      return null;
    }
  }

  /// পিডিএফে সাপোর্ট করে না এমন ইমোজি ও টাকা সাইন ফিল্টার করার মেথড
  String _sanitizeText(String text) {
    return text
        .replaceAll('🔄', '[Recurring]')
        .replaceAll('📊', '[Stats]')
        .replaceAll('📓', '[Notebook]')
        .replaceAll('⏰', '[Reminder]')
        .replaceAll('💰', '[Budget]')
        .replaceAll('🎨', '[Drawing]')
        .replaceAll('📝', '[Note]')
        .replaceAll('🔔', '[Reminder]')
        .replaceAll('✅', '[Done]')
        .replaceAll('❌', '[Failed]')
        .replaceAll('⭐', '[Important]')
        .replaceAll('৳', 'Tk'); // 🟢 ফিক্সড: ৳ চিহ্ন ভেঙে যাওয়া আটকাতে 'Tk' করা হলো
  }

  // ==================== PDF এক্সপোর্ট ====================
  Future<File> generatePdfReport({
    required String title,
    required String period,
    required double totalIncome,
    required double totalExpense,
    required double totalSavings,
    required double totalDebt,
    required double totalCredit,
    required List<Map<String, dynamic>> transactions,
    required String currencySymbol,
    required String language,
  }) async {
    final pdf = pw.Document();

    // ✅ ফন্ট লোড করুন
    final banglaFont = await _loadBanglaFont();
    if (banglaFont == null) {
      print('⚠️ Falling back to default font (Bengali will not render)');
    }

    // 🟢 কারেন্সি সিম্বল যদি ৳ হয়, তবে সেটিকে নিরাপদ করতে 'Tk' করা হলো
    final safeCurrency = currencySymbol == '৳' ? 'Tk' : currencySymbol;

    final textStyle = pw.TextStyle(font: banglaFont, fontSize: 10);
    final headerStyle = pw.TextStyle(
      font: banglaFont, fontSize: 18, fontWeight: pw.FontWeight.bold,
    );
    final titleStyle = pw.TextStyle(
      font: banglaFont, fontSize: 12, fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        // 🟢 পুরো পেজের থিমে বাংলা ফন্ট সেট করা হলো যাতে সব উইজেট অটোমেটিক বাংলা পেয়ে যায়
        theme: pw.ThemeData.withFont(base: banglaFont, bold: banglaFont),
        build: (context) => [
          pw.Center(child: pw.Text(_sanitizeText(title), style: headerStyle)),
          pw.SizedBox(height: 5),
          pw.Center(child: pw.Text(_sanitizeText(period), style: textStyle)),
          pw.SizedBox(height: 20),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  language == 'bn' ? 'সারসংক্ষেপ' : 'Summary',
                  style: titleStyle,
                ),
                pw.SizedBox(height: 10),
                _summaryRow('মোট আয়', totalIncome, safeCurrency, PdfColors.green, banglaFont),
                _summaryRow('মোট ব্যয়', totalExpense, safeCurrency, PdfColors.red, banglaFont),
                _summaryRow('সঞ্চয়', totalSavings, safeCurrency, PdfColors.blue, banglaFont),
                _summaryRow('দেনা', totalDebt, safeCurrency, PdfColors.orange, banglaFont),
                _summaryRow('পাওনা', totalCredit, safeCurrency, PdfColors.purple, banglaFont),
                pw.Divider(),
                _summaryRow('ব্যালেন্স', totalIncome - totalExpense, safeCurrency, PdfColors.teal, banglaFont),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text('লেনদেনের তালিকা', style: titleStyle),
          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.5),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _cell('তারিখ', true, banglaFont),
                  _cell('বিবরণ', true, banglaFont),
                  _cell('ক্যাটাগরি', true, banglaFont),
                  _cell('টাকা', true, banglaFont),
                ],
              ),
              ...transactions.map((tx) {
                bool isIncome = tx['type'] == 'Income' || tx['type'] == 'Savings' || tx['type'] == 'Credit';
                String datePart = '';
                try {
                  datePart = (tx['date']?.toString() ?? '').split(' ').first;
                } catch (_) {
                  datePart = tx['date']?.toString() ?? '';
                }

                String noteText = _sanitizeText(tx['note']?.toString() ?? '');
                String categoryText = _categoryName(tx['category']?.toString() ?? '', language);
                String amountText = '${isIncome ? "+" : "-"}$safeCurrency ${(tx['amount'] as num?)?.toStringAsFixed(0) ?? '0'}';

                return pw.TableRow(
                  children: [
                    _cell(datePart, false, banglaFont),
                    _cell(noteText, false, banglaFont),
                    _cell(categoryText, false, banglaFont),
                    _cell(
                      amountText,
                      false,
                      banglaFont,
                      isIncome ? PdfColors.green : PdfColors.red,
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text(
              'Generated by আমার হিসাব - ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'amar_hisab_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    print('📄 PDF saved: ${file.path}');
    return file;
  }

  // ---------- Helper widgets ----------
  pw.Widget _summaryRow(String label, double amount, String symbol, PdfColor color, pw.Font? font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11, font: font)),
          pw.Text('$symbol ${amount.toStringAsFixed(0)}',
              style: pw.TextStyle(fontSize: 11, color: color, font: font)),
        ],
      ),
    );
  }

  pw.Widget _cell(String text, bool isHeader, pw.Font? font, [PdfColor? color]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: font,
          color: color,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  String _categoryName(String key, String language) {
    const catNames = {
      'salary': {'bn': 'বেতন', 'en': 'Salary'},
      'business': {'bn': 'ব্যবসা', 'en': 'Business'},
      'house_rent': {'bn': 'বাড়ি ভাড়া', 'en': 'House Rent'},
      'grocery': {'bn': 'বাজার', 'en': 'Grocery'},
      'food': {'bn': 'খাবার', 'en': 'Food'},
      'transport': {'bn': 'যাতায়াত', 'en': 'Transport'},
      'education': {'bn': 'শিক্ষা', 'en': 'Education'},
      'medical': {'bn': 'চিকিৎসা', 'en': 'Medical'},
      'other': {'bn': 'অন্যান্য', 'en': 'Other'},
    };
    return catNames[key]?[language] ?? catNames[key]?['bn'] ?? key;
  }

  // ==================== শেয়ার / প্রিন্ট ====================
  Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'আমার হিসেব - রিপোর্ট');
  }

  Future<void> printPdf(File file) async {
    await Printing.layoutPdf(
      onLayout: (format) async => file.readAsBytesSync(),
    );
  }
}