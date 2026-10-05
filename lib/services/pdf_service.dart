import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/batch_model.dart';

class PdfService {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');

  static Future<void> generateAndShowReport({
    required String title,
    required List<TransactionModel> transactions,
    BatchModel? batch,
  }) async {
    // বাংলা ফন্ট লোড
    final regularData = await rootBundle.load("assets/fonts/NotoSansBengali-Regular.ttf");
    final boldData = await rootBundle.load("assets/fonts/NotoSansBengali-Bold.ttf");
    final ttf = pw.Font.ttf(regularData);
    final ttfBold = pw.Font.ttf(boldData);

    final pdf = pw.Document();

    final incomeList = transactions.where((tx) => tx.type == 'income').toList();
    final expenseList = transactions.where((tx) => tx.type == 'expense').toList();

    double totalIncome = incomeList.fold(0, (s, tx) => s + tx.totalAmount);
    double totalExpense = expenseList.fold(0, (s, tx) => s + tx.totalAmount);
    double net = totalIncome - totalExpense;

    pw.TextStyle normalStyle({double size = 10, PdfColor? color}) {
      return pw.TextStyle(font: ttf, fontSize: size, color: color);
    }

    pw.TextStyle boldStyle({double size = 10, PdfColor? color}) {
      return pw.TextStyle(font: ttfBold, fontSize: size, color: color);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // হেডার
          pw.Text("AgroBook - খামার হিসাব রিপোর্ট", style: boldStyle(size: 18)),
          pw.SizedBox(height: 4),
          pw.Text(title, style: normalStyle(size: 12)),
          if (batch != null) ...[
            pw.Text("ব্যাচ: ${batch.name}", style: normalStyle()),
            pw.Text("শুরু: ${_dateFormat.format(batch.startDate)}", style: normalStyle()),
            if (batch.endDate != null)
              pw.Text("শেষ: ${_dateFormat.format(batch.endDate!)}", style: normalStyle()),
          ],
          pw.Text("তৈরির তারিখ: ${_dateFormat.format(DateTime.now())}", style: normalStyle()),
          pw.Divider(),

          // আয়
          pw.Text("আয় / বিক্রির হিসাব", style: boldStyle(size: 13, color: PdfColors.green800)),
          pw.SizedBox(height: 6),
          _buildTable(incomeList, ttf, ttfBold),
          pw.SizedBox(height: 6),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "মোট আয়: ৳${totalIncome.toStringAsFixed(1)}",
              style: boldStyle(color: PdfColors.green800),
            ),
          ),

          pw.SizedBox(height: 18),

          // ব্যয়
          pw.Text("ব্যয় / কেনার হিসাব", style: boldStyle(size: 13, color: PdfColors.red800)),
          pw.SizedBox(height: 6),
          _buildTable(expenseList, ttf, ttfBold),
          pw.SizedBox(height: 6),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "মোট ব্যয়: ৳${totalExpense.toStringAsFixed(1)}",
              style: boldStyle(color: PdfColors.red800),
            ),
          ),

          pw.SizedBox(height: 20),
          pw.Divider(),

          // সামারি
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              children: [
                _summaryRow("মোট আয়:", "৳${totalIncome.toStringAsFixed(1)}", ttf, ttfBold),
                _summaryRow("মোট ব্যয়:", "৳${totalExpense.toStringAsFixed(1)}", ttf, ttfBold),
                pw.Divider(),
                _summaryRow(
                  "নিট লাভ / ক্ষতি:",
                  "৳${net.toStringAsFixed(1)}",
                  ttf,
                  ttfBold,
                  valueColor: net >= 0 ? PdfColors.green800 : PdfColors.red800,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: title,
    );
  }

  static pw.Widget _buildTable(
    List<TransactionModel> list,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    if (list.isEmpty) {
      return pw.Text("কোনো লেনদেন নেই", style: pw.TextStyle(font: ttf, color: PdfColors.grey));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(2.0),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(1.3),
        4: const pw.FlexColumnWidth(1.4),
        5: const pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell("তারিখ", ttfBold, bold: true),
            _cell("পণ্যের নাম", ttfBold, bold: true),
            _cell("পরিমাণ", ttfBold, bold: true),
            _cell("মোট ওজন", ttfBold, bold: true),
            _cell("মোট টাকা", ttfBold, bold: true),
            _cell("নোট", ttfBold, bold: true),
          ],
        ),
        ...list.map((tx) {
          return pw.TableRow(
            children: [
              _cell("${_dateFormat.format(tx.date)}\n${_timeFormat.format(tx.date)}", ttf),
              _cell(tx.productName, ttf),
              _cell(tx.quantity > 0 ? (tx.quantity % 1 == 0 ? tx.quantity.toInt().toString() : tx.quantity.toStringAsFixed(1)) : "-", ttf),
              _cell(tx.totalWeight > 0 ? "${tx.totalWeight % 1 == 0 ? tx.totalWeight.toInt() : tx.totalWeight} কেজি" : "-", ttf),
              _cell("৳${tx.totalAmount.toStringAsFixed(1)}", ttf),
              _cell(tx.note.isNotEmpty ? tx.note : "-", ttf),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, pw.Font font, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9),
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value,
    pw.Font ttf,
    pw.Font ttfBold, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: ttfBold, fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(font: ttfBold, fontSize: 11, color: valueColor)),
        ],
      ),
    );
  }

  static List<TransactionModel> filterByPeriod(
    List<TransactionModel> all,
    String period,
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
