import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/farm_provider.dart';
import '../../services/pdf_service.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farm = Provider.of<FarmProvider>(context);
    final allTx = farm.filteredTransactions;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text("রিপোর্ট ও PDF"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "রিপোর্ট তৈরি করুন",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _reportButton(
            context,
            title: "আজকের রিপোর্ট (দৈনিক)",
            icon: Icons.today,
            onTap: () {
              final list = PdfService.filterByPeriod(allTx, 'daily');
              PdfService.generateAndShowReport(
                title: "দৈনিক রিপোর্ট - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}",
                transactions: list,
              );
            },
          ),
          _reportButton(
            context,
            title: "এই সপ্তাহের রিপোর্ট",
            icon: Icons.date_range,
            onTap: () {
              final list = PdfService.filterByPeriod(allTx, 'weekly');
              PdfService.generateAndShowReport(
                title: "সাপ্তাহিক রিপোর্ট",
                transactions: list,
              );
            },
          ),
          _reportButton(
            context,
            title: "এই মাসের রিপোর্ট",
            icon: Icons.calendar_month,
            onTap: () {
              final list = PdfService.filterByPeriod(allTx, 'monthly');
              PdfService.generateAndShowReport(
                title: "মাসিক রিপোর্ট - ${now.month.toString().padLeft(2, '0')}/${now.year}",
                transactions: list,
              );
            },
          ),
          _reportButton(
            context,
            title: "এই বছরের রিপোর্ট",
            icon: Icons.calendar_today,
            onTap: () {
              final list = PdfService.filterByPeriod(allTx, 'yearly');
              PdfService.generateAndShowReport(
                title: "বাৎসরিক রিপোর্ট - ${now.year}",
                transactions: list,
              );
            },
          ),
          _reportButton(
            context,
            title: "সম্পূর্ণ রিপোর্ট (সব লেনদেন)",
            icon: Icons.picture_as_pdf,
            color: Colors.deepOrange,
            onTap: () {
              PdfService.generateAndShowReport(
                title: "সম্পূর্ণ হিসাব রিপোর্ট",
                transactions: allTx,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _reportButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF2E7D32),
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
