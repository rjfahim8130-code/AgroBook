import 'package:flutter/material.dart';

class BatchDetailPlaceholder extends StatelessWidget {
  const BatchDetailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ব্যাচ ডিটেইল")),
      body: const Center(
        child: Text("ব্যাচ ডিটেইল স্ক্রিন শীঘ্রই আসছে..."),
      ),
    );
  }
}
