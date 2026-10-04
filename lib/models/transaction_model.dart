import 'package:hive/hive.dart';

class TransactionModel extends HiveObject {
  String id;
  String type; // 'income' অথবা 'expense'
  String productName;
  double quantity;
  double weightPerUnit;
  double totalWeight;
  double pricePerUnit;
  double pricePerWeight;
  double totalAmount;
  String note;
  DateTime date;
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

// ম্যানুয়াল হাইভ অ্যাডাপ্টার (কম্পাইল এরর দূর করার জন্য)
class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    return TransactionModel(
      id: reader.readString(),
      type: reader.readString(),
      productName: reader.readString(),
      quantity: reader.readDouble(),
      weightPerUnit: reader.readDouble(),
      totalWeight: reader.readDouble(),
      pricePerUnit: reader.readDouble(),
      pricePerWeight: reader.readDouble(),
      totalAmount: reader.readDouble(),
      note: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      roundId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.type);
    writer.writeString(obj.productName);
    writer.writeDouble(obj.quantity);
    writer.writeDouble(obj.weightPerUnit);
    writer.writeDouble(obj.totalWeight);
    writer.writeDouble(obj.pricePerUnit);
    writer.writeDouble(obj.pricePerWeight);
    writer.writeDouble(obj.totalAmount);
    writer.writeString(obj.note);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.roundId);
  }
}
