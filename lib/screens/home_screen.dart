import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "খামারি বন্ধু";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() {
    var box = Hive.box('settingsBox');
    setState(() {
      userName = box.get('userName', defaultValue: 'খামারি বন্ধু');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AgroBook - খামার হিসাব", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // সেটিংস বা নাম পরিবর্তনের অপশন
              _showEditNameDialog(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ওয়েলকাম কার্ড
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, size: 35, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("স্বাগতম,", style: TextStyle(fontSize: 14, color: Colors.black54)),
                        Text(
                          userName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "হিসাব নিকাশ ও পরিচালনা",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            // মেনু বাটনসমূহ
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    "ইউনিভার্সাল এন্ট্রি",
                    Icons.add_box,
                    Colors.orange,
                    () {
                      // ইউনিভার্সাল এন্ট্রি ফর্মে যাওয়ার রাউট
                    },
                  ),
                  _buildMenuCard(
                    context,
                    "লেনদেন তালিকা",
                    Icons.list_alt,
                    Colors.blue,
                    () {
                      // হিস্ট্রি স্ক্রিন
                    },
                  ),
                  _buildMenuCard(
                    context,
                    "রাউন্ড / ব্যাচ",
                    Icons.all_inbox,
                    Colors.purple,
                    () {
                      // রাউন্ড ম্যানেজমেন্ট
                    },
                  ),
                  _buildMenuCard(
                    context,
                    "ব্যাকআপ ও সেটিংস",
                    Icons.backup,
                    Colors.teal,
                    () {
                      // ব্যাকআপ অপশন
                    },
                  ),
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
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 5, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("নাম পরিবর্তন করুন"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "নতুন নাম"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("বাতিল"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              var box = Hive.box('settingsBox');
              await box.put('userName', nameController.text.trim());
              setState(() {
                userName = nameController.text.trim();
              });
              if(!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("সেভ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
