// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_cart_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedCartAdapter extends TypeAdapter<SavedCart> {
  @override
  final int typeId = 1;

  @override
  SavedCart read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedCart(
      id: fields[0] as String,
      savedDate: fields[1] as DateTime,
      items: (fields[2] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      totalAmount: fields[3] as double,
      qrData: fields[4] as String,
      prestashopCartId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedCart obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.savedDate)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.qrData)
      ..writeByte(5)
      ..write(obj.prestashopCartId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedCartAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
