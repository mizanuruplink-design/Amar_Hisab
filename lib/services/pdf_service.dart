import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  pw.Font? _cachedFont;

  Future<pw.Font> _getFont() async {
    if (_cachedFont != null) return _cachedFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSansBengali.ttf');
      _cachedFont = pw.Font.ttf(fontData);
      print('✅ Bangla font loaded (cached)');
    } catch (e) {
      print('❌ Failed to load Bengali font: $e');
      // Fallback to default font if Bengali font fails
      _cachedFont = pw.Font.helvetica();
    }
    return _cachedFont!;
  }

  /// Replace unsupported characters (emojis, special symbols) with text equivalents
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
        .replaceAll('⭐', '[Important]');
  }

  Future<File> generatePdf(List<Map<String, dynamic>> data, String title) async {
    final font = await _getFont();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['তারিখ', 'বিবরণ', 'ধরন', 'টাকা'],
                data: data.map((item) {
                  // Sanitize the note field
                  String note = item['note']?.toString() ?? '';
                  note = _sanitizeText(note);

                  return [
                    item['date']?.toString().split(' ').first ?? '',
                    note,
                    (item['type'] == 'Income') ? 'আয়' : (item['type'] == 'Expense') ? 'ব্যয়' : '',
                    '${item['amount']} ৳',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
                cellStyle: pw.TextStyle(font: font),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'amar_hisab_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    return file;
  }

  void shareFile(File file) {
    Share.shareXFiles([XFile(file.path)], text: 'আমার হিসাব রিপোর্ট');
  }

  void printPdf(File file) async {
    await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
  }
}