import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/farm_provider.dart';

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

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) selectedType = widget.initialType!;

    if (widget.editTx != null) {
      final tx = widget.editTx!;
      selectedType = tx.type;
      _nameController.text = tx.productName;
      _qtyController.text = _formatNumber(tx.quantity);
      _wpuController.text = _formatNumber(tx.weightPerUnit);
      _twController.text = _formatNumber(tx.totalWeight);
      _ppuController.text = _formatNumber(tx.pricePerUnit);
      _ppwController.text = _formatNumber(tx.pricePerWeight);
      _taController.text = _formatNumber(tx.totalAmount);
      _noteController.text = tx.note;
    }
  }

  void _onInputChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _calculateAll();
    });
  }

  String _formatNumber(double val) {
    if (val <= 0) return '';
    return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);
  }

  void _calculateAll() {
    double qty = double.tryParse(_qtyController.text) ?? 0;
    double wpu = double.tryParse(_wpuController.text) ?? 0;
    double tw = double.tryParse(_twController.text) ?? 0;
    double ppu = double.tryParse(_ppuController.text) ?? 0;
    double ppw = double.tryParse(_ppwController.text) ?? 0;
    double ta = double.tryParse(_taController.text) ?? 0;

    // ১. ওজন ও পরিমাণের পারস্পরিক হিসাব
    if (qty > 0 && wpu > 0) {
      tw = qty * wpu;
    } else if (tw > 0 && wpu > 0 && qty == 0) {
      qty = tw / wpu;
    } else if (tw > 0 && qty > 0 && wpu == 0) {
      wpu = tw / qty;
    }

    // ২. মোট টাকার হিসাব
    if (qty > 0 && ppu > 0) {
      ta = qty * ppu;
    } else if (tw > 0 && ppw > 0) {
      ta = tw * ppw;
    }

    // ৩. রিভার্স ক্যালকুলেশন (মোট টাকা থেকে একক দাম)
    if (ta > 0) {
      if (qty > 0 && ppu == 0) ppu = ta / qty;
      if (tw > 0 && ppw == 0) ppw = ta / tw;
      if (ppu > 0 && qty == 0) qty = ta / ppu;
      if (ppw > 0 && tw == 0) tw = ta / ppw;
    }

    // ৪. চূড়ান্ত অ্যাডজাস্টমেন্ট
    if (qty > 0 && wpu > 0 && tw == 0) tw = qty * wpu;
    if (tw > 0 && qty > 0 && wpu == 0) wpu = tw / qty;

    if (mounted) {
      setState(() {
        _updateControllerIfChanged(_twController, tw);
        _updateControllerIfChanged(_wpuController, wpu);
        _updateControllerIfChanged(_qtyController, qty);
        _updateControllerIfChanged(_ppuController, ppu);
        _updateControllerIfChanged(_ppwController, ppw);
        _updateControllerIfChanged(_taController, ta);
      });
    }
  }

  void _updateControllerIfChanged(TextEditingController controller, double value) {
    String formatted = _formatNumber(value);
    if (value > 0 && controller.text != formatted) {
      controller.text = formatted;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    _calculateAll();

    final total = double.tryParse(_taController.text) ?? 0;

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("সঠিক তথ্য দিন যাতে মোট টাকা হিসাব করা যায়।"),
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
    _debounceTimer?.cancel();
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "পরিমাণ", border: OutlineInputBorder()),
                      onChanged: (_) => _onInputChanged(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _wpuController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "একক ওজন (কেজি)", border: OutlineInputBorder()),
                      onChanged: (_) => _onInputChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _twController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "মোট ওজন (কেজি)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _onInputChanged(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ppuController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "দাম / পিস", border: OutlineInputBorder()),
                      onChanged: (_) => _onInputChanged(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ppwController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "দাম / কেজি", border: OutlineInputBorder()),
                      onChanged: (_) => _onInputChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _taController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                ),
                decoration: const InputDecoration(
                  labelText: "মোট টাকা",
                  border: OutlineInputBorder(),
                  prefixText: "৳ ",
                ),
                onChanged: (_) => _onInputChanged(),
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
