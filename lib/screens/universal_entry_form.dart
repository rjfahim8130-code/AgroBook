import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/farm_provider.dart';
import '../utils/calculator_engine.dart';

class UniversalEntryForm extends StatefulWidget {
  final TransactionModel? editTransaction; // এডিট মোডের জন্য অপশনাল
  final String? initialType; // 'income' বা 'expense' প্রাথমিক মোড সেট করতে

  const UniversalEntryForm({
    super.key,
    this.editTransaction,
    this.initialType,
  });

  @override
  State<UniversalEntryForm> createState() => _UniversalEntryFormState();
}

class _UniversalEntryFormState extends State<UniversalEntryForm> {
  final _formKey = GlobalKey<FormState>();

  String selectedType = 'income'; // 'income' অথবা 'expense'
  String selectedRound = 'infinity'; // ডিফল্ট কন্টিনিউয়াস মোড
  String? selectedCategory;
  final List<String> categories = [
    'মুরগি বিক্রি',
    'ফিড কেনা',
    'ওষুধ ও ভ্যাকসিন',
    'বিদ্যুৎ বিল',
    'লেবার খরচ',
    'অন্যান্য'
  ];

  // টেক্সট কন্ট্রোলার সমূহ
  final _qtyController = TextEditingController(text: '0');
  final _wpuController = TextEditingController(text: '0');
  final _twController = TextEditingController(text: '0');
  final _ppuController = TextEditingController(text: '0');
  final _ppwController = TextEditingController(text: '0');
  final _taController = TextEditingController(text: '0');
  final _noteController = TextEditingController();

  // ফোকাস নোড (স্মার্ট অটো-ফিলের মূল চাবিকাঠি)
  final FocusNode _qtyFocus = FocusNode();
  final FocusNode _wpuFocus = FocusNode();
  final FocusNode _twFocus = FocusNode();
  final FocusNode _ppuFocus = FocusNode();
  final FocusNode _ppwFocus = FocusNode();
  final FocusNode _taFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // প্রাথমিক টাইপ সিলেক্ট (যদি বাইরে থেকে পাস করা হয়)
    if (widget.initialType != null) {
      selectedType = widget.initialType!;
    }

    // ফোকাস চেঞ্জ লিসেনার
    _qtyFocus.addListener(_onFocusChange);
    _wpuFocus.addListener(_onFocusChange);
    _twFocus.addListener(_onFocusChange);
    _ppuFocus.addListener(_onFocusChange);
    _ppwFocus.addListener(_onFocusChange);
    _taFocus.addListener(_onFocusChange);

    if (widget.editTransaction != null) {
      final tx = widget.editTransaction!;
      selectedType = tx.type;
      selectedCategory = categories.contains(tx.productName) ? tx.productName : null;
      selectedRound = tx.roundId;
      _qtyController.text = tx.quantity.toString();
      _wpuController.text = tx.weightPerUnit.toString();
      _twController.text = tx.totalWeight.toString();
      _ppuController.text = tx.pricePerUnit.toString();
      _ppwController.text = tx.pricePerWeight.toString();
      _taController.text = tx.totalAmount.toString();
      _noteController.text = tx.note;
    }
  }

  void _onFocusChange() {
    if (!_qtyFocus.hasFocus &&
        !_wpuFocus.hasFocus &&
        !_twFocus.hasFocus &&
        !_ppuFocus.hasFocus &&
        !_ppwFocus.hasFocus &&
        !_taFocus.hasFocus) {
      _runSmartCalculation();
    }
  }

  void _runSmartCalculation() {
    double q = double.tryParse(_qtyController.text) ?? 0;
    double wpu = double.tryParse(_wpuController.text) ?? 0;
    double tw = double.tryParse(_twController.text) ?? 0;
    double ppu = double.tryParse(_ppuController.text) ?? 0;
    double ppw = double.tryParse(_ppwController.text) ?? 0;
    double ta = double.tryParse(_taController.text) ?? 0;

    final result = CalculatorEngine.calculateMissingValues(
      quantity: q,
      weightPerUnit: wpu,
      totalWeight: tw,
      pricePerUnit: ppu,
      pricePerWeight: ppw,
      totalAmount: ta,
    );

    if (!mounted) return;

    setState(() {
      _qtyController.text = result['quantity'] == 0 ? '0' : result['quantity'].toString();
      _wpuController.text = result['weightPerUnit'] == 0 ? '0' : result['weightPerUnit'].toString();
      _twController.text = result['totalWeight'] == 0 ? '0' : result['totalWeight'].toString();
      _ppuController.text = result['pricePerUnit'] == 0 ? '0' : result['pricePerUnit'].toString();
      _ppwController.text = result['pricePerWeight'] == 0 ? '0' : result['pricePerWeight'].toString();
      _taController.text = result['totalAmount'] == 0 ? '0' : result['totalAmount'].toString();
    });
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _runSmartCalculation(); // সেভ করার ঠিক আগে চূড়ান্ত হিসাব

    final farmProvider = Provider.of<FarmProvider>(context, listen: false);

    final tx = TransactionModel(
      id: widget.editTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: selectedType,
      productName: selectedCategory ?? 'অন্যান্য',
      quantity: double.tryParse(_qtyController.text) ?? 0,
      weightPerUnit: double.tryParse(_wpuController.text) ?? 0,
      totalWeight: double.tryParse(_twController.text) ?? 0,
      pricePerUnit: double.tryParse(_ppuController.text) ?? 0,
      pricePerWeight: double.tryParse(_ppwController.text) ?? 0,
      totalAmount: double.tryParse(_taController.text) ?? 0,
      note: _noteController.text.trim(),
      date: widget.editTransaction?.date ?? DateTime.now(),
      roundId: selectedRound,
    );

    if (widget.editTransaction != null) {
      await farmProvider.updateTransaction(tx);
    } else {
      await farmProvider.addTransaction(tx);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // ফোকাস নোড লিসেনার রিমুভ ও ডিসপোজ
    _qtyFocus.removeListener(_onFocusChange);
    _wpuFocus.removeListener(_onFocusChange);
    _twFocus.removeListener(_onFocusChange);
    _ppuFocus.removeListener(_onFocusChange);
    _ppwFocus.removeListener(_onFocusChange);
    _taFocus.removeListener(_onFocusChange);

    _qtyFocus.dispose();
    _wpuFocus.dispose();
    _twFocus.dispose();
    _ppuFocus.dispose();
    _ppwFocus.dispose();
    _taFocus.dispose();

    // টেক্সট কন্ট্রোলার ডিসপোজ
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
    bool isIncome = selectedType == 'income';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTransaction != null ? "✏️ হিসাব পরিবর্তন" : "📝 নতুন হিসাব এন্ট্রি"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // লেনদেনের ধরণ সিলেক্টর (আয় বনাম ব্যয়)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text("📥 আয় / বিক্রি", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      selected: isIncome,
                      selectedColor: Colors.green.shade100,
                      onSelected: (val) => setState(() => selectedType = 'income'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text("📤 ব্যয় / কেনা", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      selected: !isIncome,
                      selectedColor: Colors.red.shade100,
                      onSelected: (val) => setState(() => selectedType = 'expense'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // হিসাবের মোড / রাউন্ড
              DropdownButtonFormField<String>(
                value: selectedRound,
                decoration: const InputDecoration(
                  labelText: "হিসাবের মোড / রাউন্ড",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'infinity', child: Text('∞ কন্টিনিউয়াস মোড (চলমান হিসাব)')),
                  DropdownMenuItem(value: 'round_01', child: Text('শেড #১ (Round 01)')),
                  DropdownMenuItem(value: 'round_02', child: Text('শেড #২ (Round 02)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedRound = val);
                },
              ),
              const SizedBox(height: 16),

              // ক্যাটাগরি ড্রপডাউন
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: "ক্যাটাগরি সিলেক্ট করুন *",
                  border: OutlineInputBorder(),
                ),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
                validator: (val) => val == null ? 'ক্যাটাগরি দেওয়া বাধ্যতামূলক' : null,
              ),
              const SizedBox(height: 16),

              // স্মার্ট ইনপুট গ্রিড (সংখ্যা ও একক ওজন)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      focusNode: _qtyFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "পরিমাণ (পিস/বস্তা)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _wpuController,
                      focusNode: _wpuFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "একক ওজন (কেজি)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // মোট ওজন
              TextFormField(
                controller: _twController,
                focusNode: _twFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "মোট ওজন (কেজি) [ইঞ্জিন অটো ফিল করবে]",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // রেট গ্রিড (পার পিস ও পার কেজি)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ppuController,
                      focusNode: _ppuFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "দাম (প্রতি পিস)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ppwController,
                      focusNode: _ppwFocus,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "দাম (প্রতি কেজি)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // চূড়ান্ত মোট টাকা
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
                  labelText: "সর্বমোট টাকা (Total Amount) *",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (double.tryParse(val ?? '0') ?? 0) <= 0 ? 'টাকার সঠিক অংক দিন' : null,
              ),
              const SizedBox(height: 16),

              // অপশনাল নোট
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "নোট / মন্তব্য (ঐচ্ছিক)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // সেভ বাটন
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIncome ? theme.colorScheme.primary : Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveForm,
                  child: const Text(
                    "✨ তথ্য সুরক্ষিত করুন",
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
