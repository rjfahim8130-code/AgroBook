import 'package:hive/hive.dart';

class BatchModel extends HiveObject {
  String id;
  String name;
  DateTime startDate;
  DateTime? endDate;
  double initialCapital;
  double previousProfit;
  bool isActive;
  String note;

  BatchModel({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.initialCapital = 0,
    this.previousProfit = 0,
    this.isActive = true,
    this.note = '',
  });
}

class BatchModelAdapter extends TypeAdapter<BatchModel> {
  @override
  final int typeId = 1;

  @override
  BatchModel read(BinaryReader reader) {
    return BatchModel(
      id: reader.readString(),
      name: reader.readString(),
      startDate: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      endDate: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      initialCapital: reader.readDouble(),
      previousProfit: reader.readDouble(),
      isActive: reader.readBool(),
      note: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, BatchModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.startDate.millisecondsSinceEpoch);
    writer.writeBool(obj.endDate != null);
    if (obj.endDate != null) {
      writer.writeInt(obj.endDate!.millisecondsSinceEpoch);
    }
    writer.writeDouble(obj.initialCapital);
    writer.writeDouble(obj.previousProfit);
    writer.writeBool(obj.isActive);
    writer.writeString(obj.note);
  }
}
