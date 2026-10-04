import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';
import '../models/transaction_model.dart';

class ReportSummaryScreen extends StatelessWidget {
  const ReportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FarmProvider>(context);
    final transactions = provider.allTransactions;

    // রাউন্ড অনুযায়ী ট্রানজেকশন গুছিয়ে নেওয়ার লজিক (Group by roundId)
    Map<String, List<TransactionModel>> roundGroupedTx = {};

    for (var tx in transactions) {
      String rId = tx.roundId.isEmpty ? 'infinity' : tx.roundId;
      if (!roundGroupedTx.containsKey(rId)) {
        roundGroupedTx[rId] = [];
      }
      roundGroupedTx[rId]!.add(tx);
    }

    // ট্যাবের তালিকা সাজানো
    List<String> roundKeys = roundGroupedTx.keys.toList();
    
    // ইনফিনিটি মোড থাকলে সবার সামনে আনব, তারপর অন্যান্য রাউন্ড
    roundKeys.sort((a, b) {
      if (a == 'infinity') return -1;
      if (b == 'infinity') return 1;
      return a.compareTo(b);
    });

    if (roundKeys.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("লাইভ হিসাব ও সামারি বোর্ড", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: Text("এখনো কোনো লেনদেন রেকর্ড করা হয়নি।", style: TextStyle(color: Colors.black38)),
        ),
      );
    }

    return DefaultTabController(
      length: roundKeys.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "রাউন্ডভিত্তিক লাইভ সামারি",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF2E7D32),
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFF2E7D32),
            tabs: roundKeys.map((key) {
              String title = key == 'infinity' ? '♾️ চলমান হিসাব' : '🔄 রাউন্ড: $key';
              return Tab(text: title);
            }).toList(),
          ),
        ),
        body: TabBarView(
          children: roundKeys.map((roundId) {
            final roundTxList = roundGroupedTx[roundId]!;
            return _RoundSummaryView(roundId: roundId, transactions: roundTxList);
          }).toList(),
        ),
      ),
    );
  }
}

class _RoundSummaryView extends StatelessWidget {
  final String roundId;
  final List<TransactionModel> transactions;

  const _RoundSummaryView({
    required this.roundId,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpense = 0;

    // পণ্যভিত্তিক অগ্রিগেটেড ডাটা
    Map<String, Map<String, double>> productSummary = {};

    for (var tx in transactions) {
      String name = tx.productName.trim();
      if (name.isEmpty) name = "অন্যান্য";

      if (tx.type == 'income') {
        totalIncome += tx.totalAmount;
      } else {
        totalExpense += tx.totalAmount;
      }

      if (!productSummary.containsKey(name)) {
        productSummary[name] = {
          'income': 0.0,
          'expense': 0.0,
          'weight': 0.0,
          'quantity': 0.0,
        };
      }

      if (tx.type == 'income') {
        productSummary[name]!['income'] = (productSummary[name]!['income'] ?? 0) + tx.totalAmount;
      } else {
        productSummary[name]!['expense'] = (productSummary[name]!['expense'] ?? 0) + tx.totalAmount;
      }

      productSummary[name]!['weight'] = (productSummary[name]!['weight'] ?? 0) + tx.totalWeight;
      productSummary[name]!['quantity'] = (productSummary[name]!['quantity'] ?? 0) + tx.quantity;
    }

    double netProfit = totalIncome - totalExpense;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // এই নির্দিষ্ট রাউন্ডের অভারভিউ কার্ড
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade100,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  roundId == 'infinity' ? "চলমান হিসাবের মোট নিট লাভ/ক্ষতি" : "রাউন্ড ($roundId) - নিট লাভ/ক্ষতি",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "৳${netProfit.toStringAsFixed(1)}",
                  style: TextStyle(
                    color: netProfit >= 0 ? Colors.white : Colors.orangeAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryStat("মোট বিক্রীত/আয়", "৳${totalIncome.toStringAsFixed(1)}", Colors.greenAccent),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _buildSummaryStat("মোট কেনা/খরচ", "৳${totalExpense.toStringAsFixed(1)}", Colors.redAccent.shade100),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            roundId == 'infinity' ? "📊 চলমান হিসাবের পণ্যভিত্তিক তালিকা" : "📊 রাউন্ড ($roundId)-এর পণ্যভিত্তিক তালিকা",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productSummary.keys.length,
            itemBuilder: (context, index) {
              String productName = productSummary.keys.elementAt(index);
              var data = productSummary[productName]!;
              double inc = data['income']!;
              double exp = data['expense']!;
              double weight = data['weight']!;
              double qty = data['quantity']!;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          "নিট: ৳${(inc - exp).toStringAsFixed(1)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: (inc - exp) >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (qty > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text("মোট সংখ্যা: ${qty.toStringAsFixed(0)} টি", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ),
                        if (weight > 0)
                          Text("মোট ওজন: ${weight.toStringAsFixed(1)} কেজি", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("আয়: +৳${inc.toStringAsFixed(1)}", style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600)),
                        Text("ব্যয়: -৳${exp.toStringAsFixed(1)}", style: const TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String title, String amount, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(amount, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
