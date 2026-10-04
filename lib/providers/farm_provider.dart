import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';

class FarmProvider extends ChangeNotifier {
  final Box<TransactionModel> _box = Hive.box<TransactionModel>('transactionsBox');

  String _userName = "কৃষক ভাই";
  String get userName => _userName;

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  String _activeRoundId = 'infinity';
  String get activeRoundId => _activeRoundId;

  List<String> get availableRounds {
    final rounds = _box.values
        .map((tx) => tx.roundId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (!rounds.contains('infinity')) {
      rounds.insert(0, 'infinity');
    }
    return rounds;
  }

  void setActiveRound(String roundId) {
    _activeRoundId = roundId;
    notifyListeners();
  }

  List<TransactionModel> get allTransactions => _box.values.toList().reversed.toList();

  double get totalIncome => _box.values
      .where((tx) => tx.type == 'income')
      .fold(0.0, (sum, tx) => sum + tx.totalAmount);

  double get totalExpense => _box.values
      .where((tx) => tx.type == 'expense')
      .fold(0.0, (sum, tx) => sum + tx.totalAmount);

  double get netBalance => totalIncome - totalExpense;

  void refreshData() {
    notifyListeners();
  }

  Map<String, double> getRoundSummary(String roundId) {
    final roundTxs = _box.values.where((tx) => tx.roundId == roundId);
    double income = roundTxs
        .where((tx) => tx.type == 'income')
        .fold(0.0, (sum, tx) => sum + tx.totalAmount);
    double expense = roundTxs
        .where((tx) => tx.type == 'expense')
        .fold(0.0, (sum, tx) => sum + tx.totalAmount);

    return {
      'income': income,
      'expense': expense,
      'profit': income - expense,
      'percentage': expense > 0 ? ((income - expense) / expense) * 100 : 0.0,
    };
  }

  Future<void> addTransaction(TransactionModel tx) async {
    await _box.add(tx);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final values = _box.values.toList();
    int index = values.indexWhere((element) => element.id == tx.id);
    if (index != -1) {
      await _box.putAt(index, tx);
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    await tx.delete();
    notifyListeners();
  }
}
