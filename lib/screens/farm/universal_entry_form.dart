import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/farm_provider.dart';
import '../../utils/calculator_engine.dart';

class UniversalEntryForm extends StatefulWidget {
  final String? initialType;
  final String batchId;
  final TransactionModel? editTx;

  const UniversalEntryForm({
    super.key,
    this.initialType,
    this.batchId = 'infinity',
    this.editTx,
  });

  @override
  State<UniversalEntryForm> createState() => _UniversalEntryFormState();
}

class _UniversalEntryFormState extends State<UniversalEntryForm> {
  final _formKey = GlobalKey<FormState>();
  String selectedType = 'income';

  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _wpuController = TextEditingController();
  final _twController = TextEditingController();
  final _ppuController = TextEditingController();
  final _ppwController = TextEditingController();
  final _taController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) selectedType = widget.initialType!;

    if (widget.editTx != null) {
      final tx = widget.editTx!;
      selectedType = tx.type;
      _nameController.text = tx.productName;
      _qtyController.text = tx.quantity > 0 ? tx.quantity.toString() : '';
      _wpuController.text = tx.weightPerUnit > 0 ? tx.weightPerUnit.toString() : '';
      _twController.text = tx.totalWeight > 0 ? tx.totalWeight.toString() : '';
      _ppuController.text = tx.pricePerUnit > 0 ? tx.pricePerUnit.toString() : '';
      _ppwController.text = tx.pricePerWeight > 0 ? tx.pricePerWeight.toString() : '';
      _taController.text = tx.totalAmount > 0 ? tx.totalAmount.toString() : '';
      _noteController.text = tx.note;
    }
  }

  void _runCalculation() {
    if (_isCalculating) return;
    _isCalculating = true;

    final result = CalculatorEngine.calculateMissingValues(
      quantity: double.tryParse(_qtyController.text) ?? 0,
      weightPerUnit: double.tryParse(_wpuController.text) ?? 0,
      totalWeight: double.tryParse(_twController.text) ?? 0,
      pricePerUnit: double.tryParse(_ppuController.text) ?? 0,
      pricePerWeight: double.tryParse(_ppwController.text) ?? 0,
      totalAmount: double.tryParse(_taController.text) ?? 0,
    );

    void updateIfNeeded(TextEditingController controller, double newValue) {
      final current = double.tryParse(controller.text) ?? 0;
      if (current <= 0 && newValue > 0) {
        controller.text = newValue.toStringAsFixed(
          newValue.truncateToDouble() == newValue ? 0 : 2,
        );
      }
    }

    setState(() {
      updateIfNeeded(_qtyController, result['quantity']!);
      updateIfNeeded(_wpuController, result['weightPerUnit']!);
      updateIfNeeded(_twController, result['totalWeight']!);
      updateIfNeeded(_ppuController, result['pricePerUnit']!);
      updateIfNeeded(_ppwController, result['pricePerWeight']!);
      updateIfNeeded(_taController, result['totalAmount']!);
    });

    _isCalculating = false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // সেভ করার মুহূর্তে চূড়ান্ত হিসাব সম্পন্ন করা
    _runCalculation();

    final total = double.tryParse(_taController.text) ?? 0;
    
    // পর্যাপ্ত তথ্য না দিলে যদি মোট টাকা বের না হয়, তখন নোটিশ দেওয়া হবে
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("মোট টাকা পাওয়া যায়নি। অনুগ্রহ করে সঠিক পরিমাণ ও দামের তথ্য দিন।"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final farm = Provider.of<FarmProvider>(context, listen: false);

    final tx = TransactionModel(
      id: widget.editTx?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: selectedType,
      productName: _nameController.text.trim(),
      quantity: double.tryParse(_qtyController.text) ?? 0,
      weightPerUnit: double.tryParse(_wpuController.text) ?? 0,
      totalWeight: double.tryParse(_twController.text) ?? 0,
      pricePerUnit: double.tryParse(_ppuController.text) ?? 0,
      pricePerWeight: double.tryParse(_ppwController.text) ?? 0,
      totalAmount: total,
      note: _noteController.text.trim(),
      date: widget.editTx?.date ?? DateTime.now(),
      editedAt: widget.editTx != null ? DateTime.now() : null,
      batchId: widget.batchId,
    );

    if (widget.editTx != null) {
      await farm.updateTransaction(tx);
    } else {
      await farm.addTransaction(tx);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _wpuController.dispose();
    _twController.dispose();
    _ppuController.dispose();
    _ppwController.dispose();
    _taController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = selectedType == 'income';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTx != null ? "হিসাব এডিট" : "নতুন হিসাব এন্ট্রি"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // আয় / ব্যয় সিলেক্ট
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("📥 আয় / বিক্রি")),
                      selected: isIncome,
                      selectedColor: Colors.green.shade100,
                      onSelected: (_) => setState(() => selectedType = 'income'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("📤 ব্যয় / কেনা")),
                      selected: !isIncome,
                      selectedColor: Colors.red.shade100,
                      onSelected: (_) => setState(() => selectedType = 'expense'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "পণ্যের নাম *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'পণ্যের নাম দেওয়া আবশ্যক' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "পরিমাণ", border: OutlineInputBorder()),
                      onChanged: (_) => _runCalculation(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _wpuController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "একক ওজন (কেজি)", border: OutlineInputBorder()),
                      onChanged: (_) => _runCalculation(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _twController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "মোট ওজন (কেজি) - অটো হিসাব হবে",
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _runCalculation(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ppuController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "দাম / পিস", border: OutlineInputBorder()),
                      onChanged: (_) => _runCalculation(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ppwController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "দাম / কেজি", border: OutlineInputBorder()),
                      onChanged: (_) => _runCalculation(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _taController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                ),
                decoration: const InputDecoration(
                  labelText: "মোট টাকা (অটো হিসাব হবে)",
                  border: OutlineInputBorder(),
                  prefixText: "৳ ",
                ),
                onChanged: (_) => _runCalculation(),
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
                    backgroundColor: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  child: const Text(
                    "সেভ করুন",
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
