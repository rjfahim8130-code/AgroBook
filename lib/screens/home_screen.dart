import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';
import 'universal_entry_form.dart';
import 'transaction_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "খামারি";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() {
    setState(() {
      userName = Hive.box('settingsBox').get('userName', defaultValue: 'খামারি');
    });
  }

  @override
  Widget build(BuildContext context) {
    final farmProvider = Provider.of<FarmProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AgroBook ড্যাশবোর্ড", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ব্যালেন্স খাতা কার্ড
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("সুস্বাগতম, $userName", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 8),
                  const Text("বর্তমান নেট তহবিল (Net Balance)", style: TextStyle(fontSize: 12, color: Colors.black38)),
                  Text(
                    "৳${farmProvider.netBalance.toStringAsFixed(1)}",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Text(
                        "📥 মোট আয়: ৳${farmProvider.totalIncome.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "📤 মোট ব্যয়: ৳${farmProvider.totalExpense.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("মূল পরিচালনা মেনু", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),

            // গ্রিড বাটনসমূহ
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(context, "নতুন এন্ট্রি", Icons.add_circle_outline_rounded, Colors.teal.shade700, () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const UniversalEntryForm()));
                  }),
                  _buildMenuCard(context, "লেনদেন খাতা", Icons.receipt_long_rounded, Colors.blueGrey.shade700, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionListScreen()));
                  }),
                  _buildMenuCard(context, "রাউন্ড / ব্যাচ", Icons.layers_outlined, Colors.indigo.shade700, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("পরবর্তী মডিউলে রাউন্ড ডাটাবেজ ইন্টিগ্রেট করা হচ্ছে।")),
                    );
                  }),
                  _buildMenuCard(context, "ব্যাকআপ ও সেটিংস", Icons.tune_rounded, Colors.grey.shade700, () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    _loadUserName(); // সেটিংস পরিবর্তন হয়ে আসলে নাম রিফ্রেশ হবে
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
