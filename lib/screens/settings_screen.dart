import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/personal_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final personal = Provider.of<PersonalProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("সেটিংস", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // নাম পরিবর্তন
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF2E7D32)),
              title: const Text("খামারীর নাম"),
              subtitle: Text(personal.userName),
              trailing: const Icon(Icons.edit),
              onTap: () => _editName(context, personal),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "ব্যাকআপ ও রিস্টোর শীঘ্রই আসছে",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
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
          decoration: const InputDecoration(
            labelText: "নতুন নাম",
            border: OutlineInputBorder(),
          ),
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
