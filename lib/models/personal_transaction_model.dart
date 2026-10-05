import 'package:hive/hive.dart';

class PersonalTransactionModel extends HiveObject {
  String id;
  String type; // 'income', 'expense', 'loan_given', 'loan_taken', 'donation'
  String title;
  double amount;
  String note;
  DateTime date;
  DateTime? dueDate; // ঋণের ক্ষেত্রে
  DateTime? editedAt;
  bool isSettled; // ঋণ শোধ হয়েছে কি না

  PersonalTransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    this.note = '',
    required this.date,
    this.dueDate,
    this.editedAt,
    this.isSettled = false,
  });
}

class PersonalTransactionModelAdapter extends TypeAdapter<PersonalTransactionModel> {
  @override
  final int typeId = 2;

  @override
  PersonalTransactionModel read(BinaryReader reader) {
    return PersonalTransactionModel(
      id: reader.readString(),
      type: reader.readString(),
      title: reader.readString(),
      amount: reader.readDouble(),
      note: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      dueDate: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      editedAt: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      isSettled: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, PersonalTransactionModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.type);
    writer.writeString(obj.title);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.note);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.dueDate != null);
    if (obj.dueDate != null) {
      writer.writeInt(obj.dueDate!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.editedAt != null);
    if (obj.editedAt != null) {
      writer.writeInt(obj.editedAt!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.isSettled);
  }
}
