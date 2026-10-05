import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/farm_provider.dart';
import 'create_batch_screen.dart';

class BatchListScreen extends StatelessWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farm = Provider.of<FarmProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("সব ব্যাচ"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBatchScreen()));
            },
          ),
        ],
      ),
      body: farm.allBatches.isEmpty
          ? const Center(child: Text("এখনো কোনো ব্যাচ তৈরি হয়নি"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: farm.allBatches.length,
              itemBuilder: (context, index) {
                final batch = farm.allBatches[index];
                final summary = farm.getBatchSummary(batch.id);
                final profit = summary['profit'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      batch.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("শুরু: \( {batch.startDate.day}/ \){batch.startDate.month}/${batch.startDate.year}"),
                        if (!batch.isActive && batch.endDate != null)
                          Text("শেষ: \( {batch.endDate!.day}/ \){batch.endDate!.month}/${batch.endDate!.year}"),
                        Text(
                          batch.isActive ? "🟢 চলমান" : "🔴 শেষ",
                          style: TextStyle(
                            color: batch.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "৳${profit.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        Text(
                          "${summary['percentage']?.toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                    onTap: () {
                      farm.setActiveMode(batch.id);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
    );
  }
}
