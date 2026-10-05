import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/personal_provider.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String status = "আপনার ডাটা লোকাল ফাইলে ব্যাকআপ নিতে পারেন।";

  Future<void> _export() async {
    setState(() => status = "ব্যাকআপ তৈরি হচ্ছে...");
    final path = await BackupService.exportBackup();
    setState(() {
      status = path != null
          ? "✅ ব্যাকআপ সফল!\n\n$path"
          : "❌ ব্যাকআপ ব্যর্থ হয়েছে";
    });
  }

  @override
  Widget build(BuildContext context) {
    final personal = Provider.of<PersonalProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("সেটিংস ও ব্যাকআপ")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF2E7D32)),
              title: const Text("খামারীর নাম"),
              subtitle: Text(personal.userName),
              trailing: const Icon(Icons.edit),
              onTap: () => _editName(context, personal),
            ),
          ),
          const SizedBox(height: 24),
          Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.backup, color: Colors.white),
            label: const Text("ব্যাকআপ নিন (Export)", style: TextStyle(color: Colors.white)),
            onPressed: _export,
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context, PersonalProvider personal) {
    final controller = TextEditingController(text: personal.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("নাম পরিবর্তন"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "নতুন নাম", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                personal.setUserName(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text("সেভ"),
          ),
        ],
      ),
    );
  }
}
