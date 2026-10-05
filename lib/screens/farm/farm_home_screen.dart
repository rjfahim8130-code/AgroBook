import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/farm_provider.dart';
import 'universal_entry_form.dart';
import 'create_batch_screen.dart';
import 'batch_list_screen.dart';
import 'farm_transaction_list_screen.dart';
import 'report_screen.dart';

class FarmHomeScreen extends StatelessWidget {
  const FarmHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farm = Provider.of<FarmProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("খামারি হিসাব", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "রিপোর্ট / PDF",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: "সব লেনদেন",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FarmTransactionListScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // মোড সিলেক্টর
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("বর্তমান মোড:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: farm.activeMode,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(
                        value: 'infinity',
                        child: Text("♾️ ইনফিনিটি (চলমান)"),
                      ),
                      ...farm.activeBatches.map((b) => DropdownMenuItem(
                            value: b.id,
                            child: Text("🔄 ${b.name}"),
                          )),
                    ],
                    onChanged: (val) {
                      if (val != null) farm.setActiveMode(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ব্যালেন্স কার্ড
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    farm.activeMode == 'infinity'
                        ? "চলমান হিসাবের নিট ব্যালেন্স"
                        : "বর্তমান ব্যাচের নিট লাভ/ক্ষতি",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "৳${farm.netBalance.toStringAsFixed(1)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat("আয়", "৳${farm.totalIncome.toStringAsFixed(0)}", Colors.greenAccent),
                      _stat("ব্যয়", "৳${farm.totalExpense.toStringAsFixed(0)}", Colors.redAccent.shade100),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // অ্যাকশন বাটন
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("আয় যোগ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UniversalEntryForm(
                            initialType: 'income',
                            batchId: farm.activeMode,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.remove, color: Colors.white),
                    label: const Text("ব্যয় যোগ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UniversalEntryForm(
                            initialType: 'expense',
                            batchId: farm.activeMode,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ব্যাচ ম্যানেজমেন্ট
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_business),
                    label: const Text("নতুন ব্যাচ"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateBatchScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text("সব ব্যাচ"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BatchListScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // সাম্প্রতিক লেনদেন
            const Text("সাম্প্রতিক লেনদেন", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (farm.filteredTransactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text("কোনো লেনদেন নেই", style: TextStyle(color: Colors.black38))),
              )
            else
              ...farm.filteredTransactions.take(10).map((tx) {
                final isIncome = tx.type == 'income';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(tx.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(tx.note.isNotEmpty ? tx.note : "কোনো নোট নেই"),
                    trailing: Text(
                      "${isIncome ? '+' : '-'}৳${tx.totalAmount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _stat(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
