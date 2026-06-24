import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  /// 🟢 Daily abong Monthly stats screen duthir jonnoi ekdom safe dynamic method
  Future<File> generatePdf(List<Map<String, dynamic>> data, String title) async {
    double totalIncome = 0, totalExpense = 0;
    String tableRows = '';

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      if (item == null) continue;

      // Amount safe parsing (Monthly/Daily jekono data structure-e jeno crash na kore)
      double amt = 0;
      if (item['amount'] != null) {
        amt = double.tryParse(item['amount'].toString()) ?? 0;
      }

      // Type standard normalization
      String rawType = item['type']?.toString().trim().toLowerCase() ?? '';
      bool isIncome = rawType == 'income' || rawType == 'আয়' || rawType == 'ায়';

      if (isIncome) {
        totalIncome += amt;
      } else {
        totalExpense += amt;
      }

      String dateText = '';
      if (item['date'] != null) {
        dateText = item['date'].toString().split(' ').first;
      }

      String note = item['note']?.toString() ?? '';
      String typeText = isIncome ? 'আয়' : 'ব্যয়';
      String amountText = '$amt Tk';
      String bgColor = (i % 2 == 0) ? '#ffffff' : '#f8fafc';

      tableRows += '''
        <tr style="background-color: $bgColor;">
          <td style="padding: 12px 10px; border: 1px solid #e2e8f0; text-align: center;">$dateText</td>
          <td style="padding: 12px 10px; border: 1px solid #e2e8f0; text-align: left;">$note</td>
          <td style="padding: 12px 10px; border: 1px solid #e2e8f0; text-align: center;">$typeText</td>
          <td style="padding: 12px 10px; border: 1px solid #e2e8f0; text-align: right;">$amountText</td>
        </tr>
      ''';
    }

    final now = DateTime.now();
    double remaining = totalIncome - totalExpense;

    // 🌐 Full HTML Structure (Font fallbacks optimize kora hoyeche crash prevent korar jonno)
    final String htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: 'Noto Sans Bengali', 'SolaimanLipi', sans-serif; color: #333; padding: 10px; margin: 0; }
        .header-container { width: 100%; margin-bottom: 25px; clear: both; display: block; }
        .left-header { float: left; width: 65%; }
        .right-header { float: right; width: 30%; text-align: right; }
        .title { font-size: 26px; font-weight: bold; color: #1e3a8a; margin: 0; }
        .date { font-size: 13px; color: #4b5563; margin-top: 6px; }
        .brand { display: inline-block; background-color: #1e3a8a; color: white; padding: 8px 16px; border-radius: 6px; font-weight: bold; font-size: 14px; text-align: center; }
        .divider { border-top: 2px solid #cbd5e1; margin-top: 20px; margin-bottom: 25px; clear: both; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 14px; }
        th { background-color: #1e3a8a; color: white; padding: 12px 10px; font-weight: bold; border: 1px solid #1e3a8a; }
        .summary-wrapper { width: 100%; display: block; margin-top: 35px; clear: both; }
        .summary-box { float: right; width: 230px; background-color: #f1f5f9; border: 1px solid #cbd5e1; border-radius: 8px; padding: 15px; }
        .summary-row { width: 100%; clear: both; display: block; padding: 4px 0; font-size: 14px; }
        .summary-label { float: left; }
        .summary-value { float: right; font-weight: bold; }
        .summary-divider { border-top: 1px solid #94a3b8; margin: 8px 0; clear: both; }
      </style>
    </head>
    <body>

      <div class="header-container">
        <div class="left-header">
          <h1 class="title">$title</h1>
          <div class="date">তৈরি: ${now.day}/${now.month}/${now.year}</div>
        </div>
        <div class="right-header">
          <div class="brand">আমার হিসাব</div>
        </div>
      </div>

      <div class="divider"></div>

      <table>
        <thead>
          <tr>
            <th style="text-align: center; width: 20%;">তারিখ</th>
            <th style="text-align: left; width: 45%;">বিবরণ</th>
            <th style="text-align: center; width: 15%;">ধরন</th>
            <th style="text-align: right; width: 20%;">পরিমাণ</th>
          </tr>
        </thead>
        <tbody>
          $tableRows
        </tbody>
      </table>

      <div class="summary-wrapper">
        <div class="summary-box">
          <div class="summary-row">
            <span class="summary-label">মোট আয়:</span>
            <span class="summary-value" style="color: #10b981;">${totalIncome.toStringAsFixed(2)} Tk</span>
          </div>
          <div class="summary-row">
            <span class="summary-label">মোট ব্যয়:</span>
            <span class="summary-value" style="color: #ef4444;">${totalExpense.toStringAsFixed(2)} Tk</span>
          </div>
          <div class="summary-divider"></div>
          <div class="summary-row" style="color: #1e3a8a; font-weight: bold;">
            <span class="summary-label">অবशिष्ट:</span>
            <span class="summary-value">${remaining.toStringAsFixed(2)} Tk</span>
          </div>
        </div>
      </div>

    </body>
    </html>
    ''';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/report_${DateTime.now().microsecondsSinceEpoch}.pdf');

    await file.writeAsString(htmlContent);
    return file;
  }

  /// 🟢 Native printing UI execution method
  void printPdf(File file) async {
    try {
      final htmlContent = await file.readAsString();

      // Chotto micro buffer jeno heavy monthly calculations por render thread safe thake
      await Future.delayed(const Duration(milliseconds: 150));

      await Printing.layoutPdf(
        onLayout: (format) async => await Printing.convertHtml(
          format: format,
          html: htmlContent,
        ),
        name: 'আমার_হিসাব_রিপোর্ট',
      );
    } catch (e) {
      // Suppressed
    }
  }

  void shareFile(File file) async {}
}