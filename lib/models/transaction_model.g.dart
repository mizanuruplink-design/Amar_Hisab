// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      type: fields[2] as String,
      category: fields[3] as String,
      date: fields[4] as String,
      note: fields[5] as String?,
      refundDate: fields[6] as String?,
      isPaid: fields[7] as bool,
      isArchived: fields[8] as bool,
      time: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.refundDate)
      ..writeByte(7)
      ..write(obj.isPaid)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.time);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
