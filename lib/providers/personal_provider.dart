import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/personal_transaction_model.dart';

class PersonalProvider extends ChangeNotifier {
  final Box<PersonalTransactionModel> _box =
      Hive.box<PersonalTransactionModel>('personal_transactions');
  final Box _settings = Hive.box('settings');

  String get userName => _settings.get('userName', defaultValue: 'খামারি');

  Future<void> setUserName(String name) async {
    await _settings.put('userName', name);
    notifyListeners();
  }

  List<PersonalTransactionModel> get allTransactions =>
      _box.values.toList().reversed.toList();

  // ==================== Calculations ====================

  double get totalIncome => _box.values
      .where((tx) => tx.type == 'income')
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => _box.values
      .where((tx) => tx.type == 'expense')
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalDonation => _box.values
      .where((tx) => tx.type == 'donation')
      .fold(0.0, (sum, tx) => sum + tx.amount);

  // ঋণ পাবো (আমি অন্যকে দিয়েছি)
  double get loanReceivable => _box.values
      .where((tx) => tx.type == 'loan_given' && !tx.isSettled)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  // ঋণ দিতে হবে (আমি অন্যের কাছ থেকে নিয়েছি)
  double get loanPayable => _box.values
      .where((tx) => tx.type == 'loan_taken' && !tx.isSettled)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  // মূল ব্যালেন্স (আয় - খরচ - দান + পাওনা ঋণ - দেনা ঋণ)
  double get netBalance {
    return totalIncome - totalExpense - totalDonation + loanReceivable - loanPayable;
  }

  // ==================== CRUD ====================

  Future<void> addTransaction(PersonalTransactionModel tx) async {
    await _box.add(tx);
    notifyListeners();
  }

  Future<void> updateTransaction(PersonalTransactionModel tx) async {
    tx.editedAt = DateTime.now();
    await tx.save();
    notifyListeners();
  }

  Future<void> deleteTransaction(PersonalTransactionModel tx) async {
    await tx.delete();
    notifyListeners();
  }

  Future<void> settleLoan(PersonalTransactionModel tx) async {
    tx.isSettled = true;
    tx.editedAt = DateTime.now();
    await tx.save();
    notifyListeners();
  }

  void refresh() => notifyListeners();
}
