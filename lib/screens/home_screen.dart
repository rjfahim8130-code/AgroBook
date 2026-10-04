import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';
import 'universal_entry_form.dart';
import 'transaction_list_screen.dart';
import 'settings_screen.dart';
import 'report_summary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmProvider = Provider.of<FarmProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          farmProvider.userName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Color(0xFF2E7D32)),
            tooltip: 'লাইভ সামারি বোর্ড',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportSummaryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            tooltip: 'সেটিংস ও ব্যাকআপ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => farmProvider.refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // রাউন্ড/ব্যাচ নির্বাচন কার্ড
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
                    const Text(
                      "বর্তমান মোড / রাউন্ড:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    DropdownButton<String>(
                      value: farmProvider.activeRoundId,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(
                          value: 'infinity',
                          child: Text("♾️ চলমান মোড (Infinity)"),
                        ),
                        ...farmProvider.availableRounds.where((r) => r != 'infinity').map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text("🔄 রাউন্ড: $r"),
                              ),
                            ),
                      ],
                      onChanged: (val) {
                        if (val != null) farmProvider.setActiveRound(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // প্রধান ব্যালেন্স কার্ড
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      farmProvider.activeRoundId == 'infinity'
                          ? "সর্বমোট নিট তহবিল / ব্যালেন্স"
                          : "রাউন্ড (${farmProvider.activeRoundId}) এর লাভ/ক্ষতি",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "৳${farmProvider.netBalance.toStringAsFixed(1)}",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: farmProvider.netBalance >= 0 ? Colors.white : Colors.orangeAccent,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("মোট বিক্রি / আয়", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              "৳${farmProvider.totalIncome.toStringAsFixed(1)}",
                              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Container(height: 30, width: 1, color: Colors.white24),
                        Column(
                          children: [
                            const Text("মোট কেনা / খরচ", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              "৳${farmProvider.totalExpense.toStringAsFixed(1)}",
                              style: TextStyle(color: Colors.redAccent.shade100, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // কুইক অ্যাকশন বাটনসমূহ
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: const Text("বিক্রি / আয়", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UniversalEntryForm(initialType: 'income'),
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
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                      label: const Text("কেনা / খরচ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UniversalEntryForm(initialType: 'expense'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ইতিহাস স্ক্রিনে যাওয়ার শর্টকাট
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "সাম্প্রতিক লেনদেন",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TransactionListScreen()),
                      );
                    },
                    child: const Text("সব দেখুন >", style: TextStyle(color: Color(0xFF2E7D32))),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // সংক্ষিপ্ত সাম্প্রতিক তালিকা
              farmProvider.allTransactions.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text("এখনো কোনো লেনদেন হিসাব করা হয়নি।", style: TextStyle(color: Colors.black38)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: farmProvider.allTransactions.length > 5 ? 5 : farmProvider.allTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = farmProvider.allTransactions[index];
                        bool isIncome = tx.type == 'income';

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                              child: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(tx.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(tx.note.isNotEmpty ? tx.note : "কোনো মন্তব্য নেই", style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              "${isIncome ? '+' : '-'}৳${tx.totalAmount.toStringAsFixed(1)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
