import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _statusText = "আপনার মূল্যবান খামার ডাটা সুরক্ষিত রাখতে লোকাল ফাইলে ব্যাকআপ নিন।";
  late String _userName;

  @override
  void initState() {
    super.initState();
    _userName = Hive.box('settingsBox').get('userName', defaultValue: 'খামারি');
  }

  void _runExport() async {
    setState(() => _statusText = "ব্যাকআপ ফাইল তৈরি হচ্ছে, অনুগ্রহ করে অপেক্ষা করুন...");
    String? path = await BackupService.exportLocalBackup();
    
    if (!mounted) return;

    setState(() {
      if (path != null) {
        _statusText = "✅ ব্যাকআপ সফল হয়েছে!\n\nফাইল পাথ:\n$path\n\nফোন পরিবর্তন করলে এই ফাইলটি নতুন ফোনে নিয়ে ইম্পোর্ট করলেই সব হিসাব ফিরে আসবে।";
      } else {
        _statusText = "❌ দুঃখিত! স্টোরেজ পারমিশন বা অন্য কোনো সমস্যার কারণে ব্যাকআপ ফাইল তৈরি করা যায়নি।";
      }
    });
  }

  void _editUserName() {
    final nameController = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("খামার / ব্যবহারকারীর নাম"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "নতুন নাম লিখুন",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("বাতিল"),
          ),
          ElevatedButton(
            onPressed: () async {
              String newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await Hive.box('settingsBox').put('userName', newName);
                if (!mounted) return;
                setState(() => _userName = newName);
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text("সেভ করুন"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("সেটিংস ও ব্যাকআপ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // নাম পরিবর্তনের কার্ড
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 30, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("খামারি / প্রোফাইল নাম", style: TextStyle(fontSize: 12, color: Colors.black45)),
                        Text(_userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF2E7D32)),
                    onPressed: _editUserName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Icon(Icons.shield_rounded, size: 70, color: Color(0xFF2E7D32)),
            const SizedBox(height: 24),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 48),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.drive_folder_upload_rounded, color: Colors.white),
              label: const Text(
                "লোকাল ফাইলে ব্যাকআপ নিন (Export)",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _runExport,
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.file_download_outlined, color: Color(0xFF2E7D32)),
              label: const Text(
                "ফাইল থেকে রিস্টোর করুন (Import)",
                style: TextStyle(color: Color(0xFF2E7D32), fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("ফাইল রিস্টোর করতে ফাইল ম্যানেজার থেকে 'agrobook_backup.abk' ফাইলটি সিলেক্ট করুন।"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
