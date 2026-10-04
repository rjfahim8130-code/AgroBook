import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/farm_provider.dart';
import '../models/transaction_model.dart';
import 'universal_entry_form.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmProvider = Provider.of<FarmProvider>(context);
    final list = farmProvider.allTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "লেনদেন খাতা (ইতিহাস)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      body: list.isEmpty
          ? const Center(
              child: Text(
                "এখনো কোনো লেনদেন রেকর্ড করা হয়নি।",
                style: TextStyle(color: Colors.black38),
              ),
            )
          : ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final tx = list[index];
                bool isIncome = tx.type == 'income';
                String dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(tx.date);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isIncome ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    title: Text(
                      tx.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tx.note.isNotEmpty)
                          Text(
                            tx.note,
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 11, color: Colors.black26),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${isIncome ? '+' : '-'}৳${tx.totalAmount.toStringAsFixed(1)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UniversalEntryForm(editTransaction: tx),
                                ),
                              );
                            } else if (val == 'delete') {
                              _showDeleteDialog(context, farmProvider, tx);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('✏️ এডিট'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('❌ ডিলিট', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(BuildContext context, FarmProvider provider, TransactionModel tx) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("হিসাব মুছে ফেলবেন?"),
        content: const Text(
          "আপনি কি নিশ্চিত? এই এন্ট্রিটি ডিলিট করলে আপনার মোট তহবিল স্বয়ংক্রিয়ভাবে রিক্যালকুলেট হবে।",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("বাতিল"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await provider.deleteTransaction(tx);
            },
            child: const Text("ডিলিট করুন", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
