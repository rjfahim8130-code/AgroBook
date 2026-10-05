import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
import '../../models/transaction_model.dart';
import 'universal_entry_form.dart';

class FarmTransactionListScreen extends StatelessWidget {
  const FarmTransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farm = Provider.of<FarmProvider>(context);
    final list = farm.filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text("লেনদেন খাতা (বিস্তারিত)"),
      ),
      body: list.isEmpty
          ? const Center(child: Text("কোনো লেনদেন নেই"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final tx = list[index];
                final isIncome = tx.type == 'income';
                final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(tx.date);
                final amountPrefix = isIncome ? '+' : '-';
                final amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "$amountPrefix ৳${tx.totalAmount.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: amountColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 22),
                            onSelected: (val) async {
                              if (val == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UniversalEntryForm(
                                      editTx: tx,
                                      batchId: tx.batchId,
                                    ),
                                  ),
                                );
                              } else if (val == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("ডিলিট করবেন?"),
                                    content: const Text("এই এন্ট্রি মুছে ফেলতে চান?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text("না"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text("হ্যাঁ", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await farm.deleteTransaction(tx);
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text("এডিট করুন"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text("ডিলিট", style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (tx.quantity > 0) _chip("পরিমাণ", tx.quantity % 1 == 0 ? tx.quantity.toInt().toString() : tx.quantity.toStringAsFixed(1)),
                          if (tx.weightPerUnit > 0) _chip("একক ওজন", "${tx.weightPerUnit % 1 == 0 ? tx.weightPerUnit.toInt() : tx.weightPerUnit} কেজি"),
                          if (tx.totalWeight > 0) _chip("মোট ওজন", "${tx.totalWeight % 1 == 0 ? tx.totalWeight.toInt() : tx.totalWeight} কেজি"),
                          if (tx.pricePerUnit > 0) _chip("দাম/পিস", "৳${tx.pricePerUnit % 1 == 0 ? tx.pricePerUnit.toInt() : tx.pricePerUnit}"),
                          if (tx.pricePerWeight > 0) _chip("দাম/কেজি", "৳${tx.pricePerWeight % 1 == 0 ? tx.pricePerWeight.toInt() : tx.pricePerWeight}"),
                          _chip("রাউন্ড", tx.batchId == 'infinity' ? 'চলমান' : tx.batchId),
                        ],
                      ),
                      if (tx.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text("নোট: ${tx.note}", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                      if (tx.editedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "এডিট: ${DateFormat('dd MMM, hh:mm a').format(tx.editedAt!)}",
                          style: const TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text("$label: $value", style: const TextStyle(fontSize: 12)),
    );
  }
}
