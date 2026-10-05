import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/personal_transaction_model.dart';
import '../../providers/personal_provider.dart';

class PersonalTransactionForm extends StatefulWidget {
  final String? initialType;
  final PersonalTransactionModel? editTx;

  const PersonalTransactionForm({super.key, this.initialType, this.editTx});

  @override
  State<PersonalTransactionForm> createState() => _PersonalTransactionFormState();
}

class _PersonalTransactionFormState extends State<PersonalTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  String selectedType = 'expense';
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) selectedType = widget.initialType!;
    if (widget.editTx != null) {
      final tx = widget.editTx!;
      selectedType = tx.type;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note;
      dueDate = tx.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PersonalProvider>(context, listen: false);

    final tx = PersonalTransactionModel(
      id: widget.editTx?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: selectedType,
      title: _titleController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 0,
      note: _noteController.text.trim(),
      date: widget.editTx?.date ?? DateTime.now(),
      dueDate: dueDate,
      editedAt: widget.editTx != null ? DateTime.now() : null,
    );

    if (widget.editTx != null) {
      // update logic (we need to replace the object properly)
      await provider.deleteTransaction(widget.editTx!);
      await provider.addTransaction(tx);
    } else {
      await provider.addTransaction(tx);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTx != null ? "এডিট করুন" : "নতুন লেনদেন"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Type Selector
              Wrap(
                spacing: 8,
                children: [
                  _typeChip('income', 'আয়'),
                  _typeChip('expense', 'খরচ'),
                  _typeChip('loan_given', 'ঋণ দিয়েছি'),
                  _typeChip('loan_taken', 'ঋণ নিয়েছি'),
                  _typeChip('donation', 'দান/সদকা'),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "শিরোনাম *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'শিরোনাম দিন' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "টাকার পরিমাণ *",
                  border: OutlineInputBorder(),
                  prefixText: "৳ ",
                ),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'সঠিক পরিমাণ দিন' : null,
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

  Widget _typeChip(String value, String label) {
    final isSelected = selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.green.shade100,
      onSelected: (_) => setState(() => selectedType = value),
    );
  }
}
