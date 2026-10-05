import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/batch_model.dart';

class PdfService {
  static Future<File?> generateBatchReport({
    required BatchModel batch,
    required List<TransactionModel> transactions,
    required Map<String, double> summary,
  }) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd MMM yyyy');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                "AgroBook - ব্যাচ রিপোর্ট",
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text("ব্যাচের নাম: ${batch.name}", style: const pw.TextStyle(fontSize: 14)),
            pw.Text("শুরুর তারিখ: ${dateFormat.format(batch.startDate)}"),
            if (batch.endDate != null) pw.Text("শেষ তারিখ: ${dateFormat.format(batch.endDate!)}"),
            pw.SizedBox(height: 15),
            pw.Text("মোট আয়: ৳${summary['income']?.toStringAsFixed(1)}"),
            pw.Text("মোট ব্যয়: ৳${summary['expense']?.toStringAsFixed(1)}"),
            pw.Text(
              "নিট লাভ/ক্ষতি: ৳\( {summary['profit']?.toStringAsFixed(1)} ( \){summary['percentage']?.toStringAsFixed(1)}%)",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text("লেনদেনের তালিকা:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...transactions.map((tx) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  "${dateFormat.format(tx.date)} | ${tx.productName} | "
                  "\( {tx.type == 'income' ? '+' : '-'}৳ \){tx.totalAmount.toStringAsFixed(1)}",
                ),
              );
            }),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File("\( {dir.path}/batch_ \){batch.id}_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      return null;
    }
  }
}
