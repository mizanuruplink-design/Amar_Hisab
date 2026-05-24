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
      // 🟢 ফিক্সড: আপনার pubspec.yaml ফাইলের নামের সাথে মিলিয়ে NotoSansBengali-Regular.ttf করা হলো
      final fontData = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
      _cachedFont = pw.Font.ttf(fontData);
      print('✅ Bangla font loaded successfully');
    } catch (e) {
      print('❌ Failed to load Bengali font: $e');
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
        .replaceAll('⭐', '[Important]')
        .replaceAll('৳', 'Tk'); // 🟢 ফিক্সড: টাকা সাইন অনেক ফন্টে ভেঙে যায়, তাই 'Tk' বা 'টাকা' দিয়ে রিপ্লেস করা নিরাপদ
  }

  Future<File> generatePdf(List<Map<String, dynamic>> data, String title) async {
    final font = await _getFont();
    final pdf = pw.Document();

    // টোটাল হিসাব বের করার লজিক (পিডিএফের নিচে সুন্দর সামারি দেখানোর জন্য)
    double totalIncome = 0;
    double totalExpense = 0;
    for (var item in data) {
      double amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
      if (item['type'] == 'Income') {
        totalIncome += amt;
      } else {
        totalExpense += amt;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        // 🟢 থিমের বেস ফন্ট হিসেবে বাংলা ফন্ট সেট করা হলো যাতে পুরো ফাইলে বাংলা সাপোর্ট করে
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==================== PREMIUM HEADER ====================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _sanitizeText(title),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1E3A8A'), // ডিপ ব্লু কালার থিম
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'তৈরি করার তারিখ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  // অ্যাপের নাম ব্র্যান্ডিং
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#1E3A8A'),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'আমার হিসাব',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 15),

              // ==================== MODERN TABLE ====================
              pw.TableHelper.fromTextArray(
                headers: ['তারিখ', 'বিবরণ', 'ধরন', 'পরিমাণ'],
                data: data.map((item) {
                  String note = item['note']?.toString() ?? '';
                  note = _sanitizeText(note);
                  String typeText = (item['type'] == 'Income') ? 'আয়' : 'ব্যয়';
                  String amountText = '${item['amount']} Tk';

                  return [
                    item['date']?.toString().split(' ').first ?? '',
                    note,
                    typeText,
                    amountText,
                  ];
                }).toList(),

                // টেবিল ডিজাইন ও কালার স্টাইলিং
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 12),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1E3A8A'), // হেডার ব্যাকগ্রাউন্ড কালার
                ),
                cellStyle: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,     // তারিখ সেন্টারে থাকবে
                  2: pw.Alignment.center,     // ধরন সেন্টারে থাকবে
                  3: pw.Alignment.centerRight, // টাকা ডানপাশে থাকবে
                },
                rowDecoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                ),
                // অল্টারনেティブ রো কালার (একটি সাদা, একটি হালকা গ্রে যাতে পড়তে সুবিধা হয়)
                oddRowDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                ),
                // 🟢 ফিক্সড: 'padding' পরিবর্তন করে এখানে 'cellPadding' করা হয়েছে
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),

              pw.SizedBox(height: 30),

              // ==================== SUMMARY CARD ====================
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F1F5F9'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 1),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('মোট আয়:', style: const pw.TextStyle(fontSize: 11)),
                          pw.Text('${totalIncome.toStringAsFixed(2)} Tk', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#10B981'))),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('মোট ব্যয়:', style: const pw.TextStyle(fontSize: 11)),
                          pw.Text('${totalExpense.toStringAsFixed(2)} Tk', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#EF4444'))),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('অবশিষ্ট:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                            '${(totalIncome - totalExpense).toStringAsFixed(2)} Tk',
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: (totalIncome - totalExpense) >= 0 ? PdfColor.fromHex('#1E3A8A') : PdfColor.fromHex('#EF4444')
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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