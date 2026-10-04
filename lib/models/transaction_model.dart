import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String type; // 'income' অথবা 'expense'

  @HiveField(2)
  String productName;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  double weightPerUnit;

  @HiveField(5)
  double totalWeight;

  @HiveField(6)
  double pricePerUnit;

  @HiveField(7)
  double pricePerWeight;

  @HiveField(8)
  double totalAmount;

  @HiveField(9)
  String note;

  @HiveField(10)
  DateTime date;

  @HiveField(11)
  String roundId; // 'infinity' অথবা নির্দিষ্ট রাউন্ড আইডি

  TransactionModel({
    required this.id,
    required this.type,
    required this.productName,
    required this.quantity,
    required this.weightPerUnit,
    required this.totalWeight,
    required this.pricePerUnit,
    required this.pricePerWeight,
    required this.totalAmount,
    required this.note,
    required this.date,
    required this.roundId,
  });
}
