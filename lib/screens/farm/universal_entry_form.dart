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

  final _qtyFocus = FocusNode();
  final _wpuFocus = FocusNode();
  final _twFocus = FocusNode();
  final _ppuFocus = FocusNode();
  final _ppwFocus = FocusNode();
  final _taFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) selectedType = widget.initialType!;

    if (widget.editTx != null) {
      final tx = widget.editTx!;
      selectedType = tx.type;
      _nameController.text = tx.productName;
      _qtyController.text = tx.quantity > 0 ? _formatNumber(tx.quantity) : '';
      _wpuController.text = tx.weightPerUnit > 0 ? _formatNumber(tx.weightPerUnit) : '';
      _twController.text = tx.totalWeight > 0 ? _formatNumber(tx.totalWeight) : '';
      _ppuController.text = tx.pricePerUnit > 0 ? _formatNumber(tx.pricePerUnit) : '';
      _ppwController.text = tx.pricePerWeight > 0 ? _formatNumber(tx.pricePerWeight) : '';
      _taController.text = tx.totalAmount > 0 ? _formatNumber(tx.totalAmount) : '';
      _noteController.text = tx.note;
    }

    // একটি ফিল্ড থেকে অন্য ফিল্ডে ফোকাস সরলে রিক্যালকুলেশন হবে
    _qtyFocus.addListener(_handleFocusChange);
    _wpuFocus.addListener(_handleFocusChange);
    _twFocus.addListener(_handleFocusChange);
    _ppuFocus.addListener(_handleFocusChange);
    _ppwFocus.addListener(_handleFocusChange);
    _taFocus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    // কোনো ফিল্ড থেকে ফোকাস চলে গেলে রিক্যালকুলেশন
    if (!_qtyFocus.hasFocus &&
        !_wpuFocus.hasFocus &&
        !_twFocus.hasFocus &&
        !_ppuFocus.hasFocus &&
        !_ppwFocus.hasFocus &&
        !_taFocus.hasFocus) {
      _calculateAll();
    }
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

    // ১. ওজন সংক্রান্ত হিসাব (পরিমাণ, একক ওজন, মোট ওজন)
    if (qty > 0 && wpu > 0) {
      tw = qty * wpu;
    } else if (tw > 0 && wpu > 0 && qty == 0) {
      qty = tw / wpu;
    } else if (tw > 0 && qty > 0 && wpu == 0) {
      wpu = tw / qty;
    }

    // ২. মোট টাকা বের করার হিসাব
    if (ta == 0) {
      if (qty > 0 && ppu > 0) {
        ta = qty * ppu;
      } else if (tw > 0 && ppw > 0) {
        ta = tw * ppw;
      }
    }

    // ৩. মোট টাকা দেওয়া থাকলে অন্যান্য মান বের করা
    if (ta > 0) {
      if (qty > 0 && ppu == 0) ppu = ta / qty;
      if (tw > 0 && ppw == 0) ppw = ta / tw;
      if (ppu > 0 && qty == 0) qty = ta / ppu;
      if (ppw > 0 && tw == 0) tw = ta / ppw;
    }

    // ওজনের দ্বিমুখী সম্পর্ক পুনঃনির্ধারণ
    if (qty > 0 && wpu > 0 && tw == 0) tw = qty * wpu;
    if (tw > 0 && qty > 0 && wpu == 0) wpu = tw / qty;

    // যে ফিল্ডগুলো ক্লিয়ার/খালি সেগুলোতে সঠিক ডাটা বসানো
    setState(() {
      _qtyController.text = _formatNumber(qty);
      _wpuController.text = _formatNumber(wpu);
      _twController.text = _formatNumber(tw);
      _ppuController.text = _formatNumber(ppu);
      _ppwController.text = _formatNumber(ppw);
      _taController.text = _formatNumber(ta);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // সেভ বাটন প্রেস করা মাত্র চূড়ান্ত হিসাব নিশ্চিত করা
    _calculateAll();

    final total = double.tryParse(_taController.text) ?? 0;

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("পর্যাপ্ত তথ্য পাওয়া যায়নি! মোট টাকা বা দাম/পরিমাণের তথ্য সঠিকভাবে দিন।"),
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
    _qtyFocus.dispose();
    _wpuFocus.dispose();
    _twFocus.dispose();
    _ppuFocus.dispose();
    _ppwFocus.dispose();
    _taFocus.dispose();

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
                      focusNode: _qtyFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "পরিমাণ", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _wpuController,
                      focusNode: _wpuFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "একক ওজন (কেজি)", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _twController,
                focusNode: _twFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "মোট ওজন (কেজি)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ppuController,
                      focusNode: _ppuFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "দাম / পিস", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ppwController,
                      focusNode: _ppwFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "দাম / কেজি", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _taController,
                focusNode: _taFocus,
                keyboardType: TextInputType.number,
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
