// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_provider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CouponAdapter extends TypeAdapter<Coupon> {
  @override
  final int typeId = 0;

  @override
  Coupon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Coupon(
      id: fields[0] as int,
      code: fields[1] as String,
      reductionPercent: fields[2] as double?,
      reductionAmount: fields[3] as double?,
      name: fields[4] as String,
      expiryDate: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Coupon obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.reductionPercent)
      ..writeByte(3)
      ..write(obj.reductionAmount)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.expiryDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CouponAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
