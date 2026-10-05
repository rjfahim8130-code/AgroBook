import 'package:hive/hive.dart';

class TransactionModel extends HiveObject {
  String id;
  String type; // 'income' or 'expense'
  String productName;
  double quantity;
  double weightPerUnit;
  double totalWeight;
  double pricePerUnit;
  double pricePerWeight;
  double totalAmount;
  String note;
  DateTime date;
  DateTime? editedAt;
  String batchId; // 'infinity' অথবা নির্দিষ্ট ব্যাচের id

  TransactionModel({
    required this.id,
    required this.type,
    required this.productName,
    this.quantity = 0,
    this.weightPerUnit = 0,
    this.totalWeight = 0,
    this.pricePerUnit = 0,
    this.pricePerWeight = 0,
    this.totalAmount = 0,
    this.note = '',
    required this.date,
    this.editedAt,
    this.batchId = 'infinity',
  });
}

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
      editedAt: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      batchId: reader.readString(),
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
    writer.writeBool(obj.editedAt != null);
    if (obj.editedAt != null) {
      writer.writeInt(obj.editedAt!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.batchId);
  }
}
