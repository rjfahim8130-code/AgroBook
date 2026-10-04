import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';

class BackupService {
  static Future<String?> exportLocalBackup() async {
    try {
      final txBox = Hive.box<TransactionModel>('transactionsBox');
      final settingsBox = Hive.box('settingsBox');

      final List<Map<String, dynamic>> txList = txBox.values.map((tx) => {
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
        'roundId': tx.roundId,
      }).toList();

      Map<String, dynamic> masterMap = {
        'userName': settingsBox.get('userName', defaultValue: 'খামারি'),
        'transactions': txList,
        'exportedAt': DateTime.now().toIso8601String()
      };

      String rawJson = jsonEncode(masterMap);
      String encryptedString = base64Encode(utf8.encode(rawJson));

      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/agrobook_backup.abk');
      await backupFile.writeAsString(encryptedString);

      return backupFile.path;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> restoreLocalBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      String encryptedString = await file.readAsString();
      String rawJson = utf8.decode(base64Decode(encryptedString.trim()));
      Map<String, dynamic> masterMap = jsonDecode(rawJson);

      final txBox = Hive.box<TransactionModel>('transactionsBox');
      final settingsBox = Hive.box('settingsBox');

      if (masterMap['transactions'] == null) return false;

      await txBox.clear();
      if (masterMap['userName'] != null) {
        await settingsBox.put('userName', masterMap['userName']);
      }

      for (var txMap in masterMap['transactions']) {
        final tx = TransactionModel(
          id: txMap['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: txMap['type'] ?? 'income',
          productName: txMap['productName'] ?? 'অন্যান্য',
          quantity: (txMap['quantity'] as num?)?.toDouble() ?? 0.0,
          weightPerUnit: (txMap['weightPerUnit'] as num?)?.toDouble() ?? 0.0,
          totalWeight: (txMap['totalWeight'] as num?)?.toDouble() ?? 0.0,
          pricePerUnit: (txMap['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
          pricePerWeight: (txMap['pricePerWeight'] as num?)?.toDouble() ?? 0.0,
          totalAmount: (txMap['totalAmount'] as num?)?.toDouble() ?? 0.0,
          note: txMap['note'] ?? '',
          date: DateTime.tryParse(txMap['date'] ?? '') ?? DateTime.now(),
          roundId: txMap['roundId'] ?? 'infinity',
        );
        await txBox.add(tx);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
