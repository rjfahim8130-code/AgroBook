import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _completeOnboarding([String defaultName = "খামারি বন্ধু"]) {
    String finalName = _nameController.text.trim().isEmpty ? defaultName : _nameController.text.trim();
    var box = Hive.box('settingsBox');
    box.put('userName', finalName);
    box.put('isFirstTime', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // একদম হালকা সুদিং গ্রিন
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa_rounded, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  "AgroBook",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1),
                ),
                const Text("আপনার খামারের স্মার্ট ও সহজ ডিজিটাল খাতা", style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 48),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "আপনার বা খামারের নাম লিখুন",
                    prefixIcon: Icon(Icons.storefront_rounded, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _completeOnboarding(),
                    child: const Text("হিসাব খাতা শুরু করুন", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _completeOnboarding("সম্মানিত খামারি"),
                  child: const Text("পরে দেব (স্কিপ করুন)", style: TextStyle(color: Colors.black45, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
