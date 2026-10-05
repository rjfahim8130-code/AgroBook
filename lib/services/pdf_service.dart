import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';
import '../models/batch_model.dart';

class PdfService {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');

  /// বিস্তারিত রিপোর্ট জেনারেট + প্রিভিউ
  static Future<void> generateAndShowReport({
    required String title,
    required List<TransactionModel> transactions,
    BatchModel? batch,
  }) async {
    final pdf = pw.Document();

    final incomeList = transactions.where((tx) => tx.type == 'income').toList();
    final expenseList = transactions.where((tx) => tx.type == 'expense').toList();

    double totalIncome = incomeList.fold(0, (s, tx) => s + tx.totalAmount);
    double totalExpense = expenseList.fold(0, (s, tx) => s + tx.totalAmount);
    double net = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        // কলাম বেশি থাকায় পেজ Landscape ফরম্যাটে দিলে টেবিল সুন্দরভাবে ফিট করবে
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // ===== হেডার =====
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "AgroBook - খামার হিসাব রিপোর্ট",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(title, style: const pw.TextStyle(fontSize: 12)),
                if (batch != null) ...[
                  pw.Text("ব্যাচ: ${batch.name}"),
                  pw.Text("শুরু: ${_dateFormat.format(batch.startDate)}"),
                  if (batch.endDate != null)
                    pw.Text("শেষ: ${_dateFormat.format(batch.endDate!)}"),
                ],
                pw.Text("তৈরির তারিখ: ${_dateFormat.format(DateTime.now())}"),
                pw.Divider(),
              ],
            ),
          ),

          // ===== আয়ের হিসাব =====
          pw.Text(
            "আয় / বিক্রির হিসাব",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
          ),
          pw.SizedBox(height: 6),
          _buildTransactionTable(incomeList),
          pw.SizedBox(height: 6),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "মোট আয়: ৳${totalIncome.toStringAsFixed(1)}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
            ),
          ),

          pw.SizedBox(height: 16),

          // ===== ব্যয়ের হিসাব =====
          pw.Text(
            "ব্যয় / কেনার হিসাব",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
          ),
          pw.SizedBox(height: 6),
          _buildTransactionTable(expenseList),
          pw.SizedBox(height: 6),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "মোট ব্যয়: ৳${totalExpense.toStringAsFixed(1)}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Divider(),

          // ===== সামারি =====
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("মোট আয়:"),
                    pw.Text("৳${totalIncome.toStringAsFixed(1)}"),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("মোট ব্যয়:"),
                    pw.Text("৳${totalExpense.toStringAsFixed(1)}"),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "নিট লাভ / ক্ষতি:",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      "৳${net.toStringAsFixed(1)}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: net >= 0 ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // প্রিভিউ + জুম + শেয়ার সাপোর্ট
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: title,
    );
  }

  static pw.Widget _buildTransactionTable(List<TransactionModel> list) {
    if (list.isEmpty) {
      return pw.Text("কোনো লেনদেন নেই", style: const pw.TextStyle(color: PdfColors.grey));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.8), // নাম
        1: pw.FlexColumnWidth(1.0), // পরিমাণ
        2: pw.FlexColumnWidth(1.1), // একক ওজন
        3: pw.FlexColumnWidth(1.1), // মোট ওজন
        4: pw.FlexColumnWidth(1.1), // দর/পিস
        5: pw.FlexColumnWidth(1.1), // দর/কেজি
        6: pw.FlexColumnWidth(1.3), // মোট টাকা
        7: pw.FlexColumnWidth(1.8), // তারিখ ও এডিট তারিখ
        8: pw.FlexColumnWidth(1.5), // নোট
      },
      children: [
        // হেডার
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell("পণ্যের নাম", bold: true),
            _cell("পরিমাণ", bold: true),
            _cell("একক ওজন", bold: true),
            _cell("মোট ওজন", bold: true),
            _cell("দর/পিস", bold: true),
            _cell("দর/কেজি", bold: true),
            _cell("মোট টাকা", bold: true),
            _cell("তারিখ", bold: true),
            _cell("নোট", bold: true),
          ],
        ),
        // ডাটা
        ...list.map((tx) {
          String dateText = "${_dateFormat.format(tx.date)}\n${_timeFormat.format(tx.date)}";
          if (tx.editedAt != null) {
            dateText += "\n(এডিট: ${_dateFormat.format(tx.editedAt!)})";
          }

          return pw.TableRow(
            children: [
              _cell(tx.productName),
              _cell(tx.quantity > 0 ? tx.quantity.toStringAsFixed(0) : "-"),
              _cell(tx.weightPerUnit > 0 ? "${tx.weightPerUnit.toStringAsFixed(2)} কেজি" : "-"),
              _cell(tx.totalWeight > 0 ? "${tx.totalWeight.toStringAsFixed(1)} কেজি" : "-"),
              _cell(tx.pricePerUnit > 0 ? "৳${tx.pricePerUnit.toStringAsFixed(1)}" : "-"),
              _cell(tx.pricePerWeight > 0 ? "৳${tx.pricePerWeight.toStringAsFixed(1)}" : "-"),
              _cell("৳${tx.totalAmount.toStringAsFixed(1)}"),
              _cell(dateText),
              _cell(tx.note.isNotEmpty ? tx.note : "-"),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// দৈনিক / সাপ্তাহিক / মাসিক / বাৎসরিক ফিল্টার
  static List<TransactionModel> filterByPeriod(
    List<TransactionModel> all,
    String period, // 'daily', 'weekly', 'monthly', 'yearly'
  ) {
    final now = DateTime.now();
    return all.where((tx) {
      switch (period) {
        case 'daily':
          return tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
        case 'weekly':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return tx.date.isAfter(weekStart.subtract(const Duration(days: 1)));
        case 'monthly':
          return tx.date.year == now.year && tx.date.month == now.month;
        case 'yearly':
          return tx.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }
}
