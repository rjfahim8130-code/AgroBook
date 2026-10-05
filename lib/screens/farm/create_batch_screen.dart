import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/batch_model.dart';
import '../../providers/farm_provider.dart';

class CreateBatchScreen extends StatefulWidget {
  const CreateBatchScreen({super.key});

  @override
  State<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capitalController = TextEditingController();
  final _prevProfitController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime startDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _capitalController.dispose();
    _prevProfitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = Provider.of<FarmProvider>(context, listen: false);

    // নাম খালি থাকলে অটো নাম তৈরি করব
    String batchName = _nameController.text.trim();
    if (batchName.isEmpty) {
      final existingCount = farm.allBatches.length;
      batchName = "ব্যাচ-${(existingCount + 1).toString().padLeft(2, '0')}";
    }

    final batch = BatchModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: batchName,
      startDate: startDate,
      initialCapital: double.tryParse(_capitalController.text) ?? 0,
      previousProfit: double.tryParse(_prevProfitController.text) ?? 0,
      note: _noteController.text.trim(),
      isActive: true,
    );

    await farm.createBatch(batch);
    farm.setActiveMode(batch.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ব্যাচ তৈরি হয়েছে: $batchName")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("নতুন ব্যাচ তৈরি")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "ব্যাচের নাম (খালি রাখলে অটো নাম্বার হবে)",
                  hintText: "যেমন: মুরগি ব্যাচ-০৩",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // তারিখ সিলেক্টর (সংশোধিত)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("শুরুর তারিখ"),
                subtitle: Text(
                  "${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _capitalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "বর্তমান পুঁজি (ঐচ্ছিক)",
                  border: OutlineInputBorder(),
                  prefixText: "৳ ",
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _prevProfitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "আগের ব্যাচের লাভ (ঐচ্ছিক)",
                  border: OutlineInputBorder(),
                  prefixText: "৳ ",
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "নোট (ঐচ্ছিক)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  child: const Text(
                    "ব্যাচ শুরু করুন",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
