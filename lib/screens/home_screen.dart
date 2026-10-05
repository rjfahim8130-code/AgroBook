import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/personal_provider.dart';
import '../providers/farm_provider.dart';
import 'farm/farm_home_screen.dart';
import 'personal/personal_transaction_form.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final personal = Provider.of<PersonalProvider>(context);
    final farm = Provider.of<FarmProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          personal.userName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          personal.refresh();
          farm.refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== মূল ব্যালেন্স কার্ড =====
              _buildBalanceCard(personal, farm),

              const SizedBox(height: 20),

              // ===== কুইক অ্যাকশন =====
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      context,
                      title: "আয় যোগ",
                      color: Colors.green.shade700,
                      icon: Icons.add_circle_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PersonalTransactionForm(initialType: 'income'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      context,
                      title: "খরচ যোগ",
                      color: Colors.red.shade700,
                      icon: Icons.remove_circle_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PersonalTransactionForm(initialType: 'expense'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // খামারি হিসাব বাটন
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.agriculture, color: Colors.white),
                  label: const Text(
                    "খামারি হিসাব",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FarmHomeScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ===== সাম্প্রতিক লেনদেন =====
              const Text(
                "সাম্প্রতিক লেনদেন",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (personal.allTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text("এখনো কোনো লেনদেন নেই", style: TextStyle(color: Colors.black38)),
                  ),
                )
              else
                ...personal.allTransactions.take(8).map((tx) => _transactionTile(tx)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(PersonalProvider personal, FarmProvider farm) {
    final personalBalance = personal.netBalance;
    final farmProfit = farm.overallFarmProfit;
    final totalBalance = personalBalance + farmProfit;

    return Container(
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
          const Text(
            "মোট ব্যালেন্স",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            "৳${totalBalance.toStringAsFixed(1)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat("পরিবার", "৳${personalBalance.toStringAsFixed(0)}"),
              Container(height: 30, width: 1, color: Colors.white24),
              _miniStat("খামার", "৳${farmProfit.toStringAsFixed(0)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _actionButton(BuildContext context,
      {required String title, required Color color, required IconData icon, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      onPressed: onTap,
    );
  }

  Widget _transactionTile(dynamic tx) {
    final isIncome = tx.type == 'income';
    final isLoanGiven = tx.type == 'loan_given';
    final isDonation = tx.type == 'donation';

    Color color = isIncome
        ? Colors.green
        : isDonation
            ? Colors.purple
            : (tx.type == 'loan_given' || tx.type == 'loan_taken')
                ? Colors.orange
                : Colors.red;

    String prefix = (isIncome || isLoanGiven) ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isIncome
                ? Icons.arrow_downward
                : isDonation
                    ? Icons.favorite
                    : (tx.type == 'loan_given' || tx.type == 'loan_taken')
                        ? Icons.account_balance_wallet
                        : Icons.arrow_upward,
            color: color,
            size: 20,
          ),
        ),
        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          tx.note.isNotEmpty ? tx.note : tx.type,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: Text(
          "$prefix৳${tx.amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
