import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import '../models/batch_model.dart';

class FarmProvider extends ChangeNotifier {
  final Box<TransactionModel> _txBox = Hive.box<TransactionModel>('farm_transactions');
  final Box<BatchModel> _batchBox = Hive.box<BatchModel>('batches');

  String _activeMode = 'infinity'; // 'infinity' or batchId
  String get activeMode => _activeMode;

  // ==================== Batch Related ====================

  List<BatchModel> get allBatches => _batchBox.values.toList().reversed.toList();

  List<BatchModel> get activeBatches =>
      _batchBox.values.where((b) => b.isActive).toList();

  BatchModel? getBatchById(String id) {
    try {
      return _batchBox.values.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> createBatch(BatchModel batch) async {
    await _batchBox.add(batch);
    notifyListeners();
  }

  Future<void> updateBatch(BatchModel batch) async {
    await batch.save();
    notifyListeners();
  }

  Future<void> endBatch(String batchId) async {
    final batch = getBatchById(batchId);
    if (batch != null) {
      batch.isActive = false;
      batch.endDate = DateTime.now();
      await batch.save();
      notifyListeners();
    }
  }

  void setActiveMode(String mode) {
    _activeMode = mode;
    notifyListeners();
  }

  // ==================== Transactions ====================

  List<TransactionModel> get allTransactions =>
      _txBox.values.toList().reversed.toList();

  List<TransactionModel> get filteredTransactions {
    if (_activeMode == 'infinity') {
      return allTransactions.where((tx) => tx.batchId == 'infinity').toList();
    }
    return allTransactions.where((tx) => tx.batchId == _activeMode).toList();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    await _txBox.add(tx);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    tx.editedAt = DateTime.now();
    await tx.save();
    notifyListeners();
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    await tx.delete();
    notifyListeners();
  }

  // ==================== Calculations ====================

  double get totalIncome {
    return filteredTransactions
        .where((tx) => tx.type == 'income')
        .fold(0.0, (sum, tx) => sum + tx.totalAmount);
  }

  double get totalExpense {
    return filteredTransactions
        .where((tx) => tx.type == 'expense')
        .fold(0.0, (sum, tx) => sum + tx.totalAmount);
  }

  double get netBalance => totalIncome - totalExpense;

  // Specific batch summary
  Map<String, double> getBatchSummary(String batchId) {
    final txs = allTransactions.where((tx) => tx.batchId == batchId);
    double income = txs.where((tx) => tx.type == 'income').fold(0.0, (s, tx) => s + tx.totalAmount);
    double expense = txs.where((tx) => tx.type == 'expense').fold(0.0, (s, tx) => s + tx.totalAmount);
    double profit = income - expense;
    double percentage = expense > 0 ? (profit / expense) * 100 : 0;

    return {
      'income': income,
      'expense': expense,
      'profit': profit,
      'percentage': percentage,
    };
  }

  // Overall farm profit/loss (all batches + infinity)
  double get overallFarmProfit {
    return allTransactions
        .where((tx) => tx.type == 'income')
        .fold(0.0, (s, tx) => s + tx.totalAmount) -
        allTransactions
            .where((tx) => tx.type == 'expense')
            .fold(0.0, (s, tx) => s + tx.totalAmount);
  }

  void refresh() => notifyListeners();
}
