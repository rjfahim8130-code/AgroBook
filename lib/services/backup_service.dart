import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import '../models/batch_model.dart';
import '../models/personal_transaction_model.dart';

class BackupService {
  static Future<String?> exportBackup() async {
    try {
      final farmTxBox = Hive.box<TransactionModel>('farm_transactions');
      final batchBox = Hive.box<BatchModel>('batches');
      final personalBox = Hive.box<PersonalTransactionModel>('personal_transactions');
      final settingsBox = Hive.box('settings');

      final data = {
        'userName': settingsBox.get('userName', defaultValue: 'খামারি'),
        'exportedAt': DateTime.now().toIso8601String(),
        'farm_transactions': farmTxBox.values.map((tx) => {
          'id': tx.id,
          'type': tx.type,
          'productName': tx.productName,
          'quantity': tx.quantity,
          'weightPerUnit': tx.weightPerUnit,
          'totalWeight': tx.totalWeight,
          'pricePerUnit': tx.pricePerUnit,
          'pricePerWeight': tx.pricePerWeight,
          'totalAmount': tx.totalAmount,
          'note': tx.note,
          'date': tx.date.toIso8601String(),
          'editedAt': tx.editedAt?.toIso8601String(),
          'batchId': tx.batchId,
        }).toList(),
        'batches': batchBox.values.map((b) => {
          'id': b.id,
          'name': b.name,
          'startDate': b.startDate.toIso8601String(),
          'endDate': b.endDate?.toIso8601String(),
          'initialCapital': b.initialCapital,
          'previousProfit': b.previousProfit,
          'isActive': b.isActive,
          'note': b.note,
        }).toList(),
        'personal_transactions': personalBox.values.map((tx) => {
          'id': tx.id,
          'type': tx.type,
          'title': tx.title,
          'amount': tx.amount,
          'note': tx.note,
          'date': tx.date.toIso8601String(),
          'dueDate': tx.dueDate?.toIso8601String(),
          'editedAt': tx.editedAt?.toIso8601String(),
          'isSettled': tx.isSettled,
        }).toList(),
      };

      final jsonString = jsonEncode(data);
      final encoded = base64Encode(utf8.encode(jsonString));

      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File("\( {dir.path}/agrobook_backup_ \){DateTime.now().millisecondsSinceEpoch}.abk");
      await file.writeAsString(encoded);

      return file.path;
    } catch (e) {
      return null;
    }
  }

  // রিস্টোর ফাংশন পরে আরও রোবাস্ট করে দিব
  static Future<bool> restoreBackup(String filePath) async {
    // আপাতত সিম্পল রাখছি — পরে পূর্ণাঙ্গ করব
    return false;
  }
}
