// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomCategoryAdapter extends TypeAdapter<CustomCategory> {
  @override
  final int typeId = 3;

  @override
  CustomCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomCategory(
      id: fields[0] as String,
      nameKey: fields[1] as String,
      iconCode: fields[2] as int,
      colorValue: fields[3] as int,
      isPredefined: fields[4] as bool,
      type: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomCategory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameKey)
      ..writeByte(2)
      ..write(obj.iconCode)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.isPredefined)
      ..writeByte(5)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
