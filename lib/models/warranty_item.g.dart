// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warranty_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WarrantyItemAdapter extends TypeAdapter<WarrantyItem> {
  @override
  final int typeId = 0;

  @override
  WarrantyItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WarrantyItem(
      id: fields[0] as String,
      name: fields[1] as String,
      storeName: fields[2] as String,
      purchaseDate: fields[3] as DateTime,
      warrantyPeriodInMonths: fields[4] as int,
      serialNumber: fields[5] as String,
      category: fields[6] as String,
      imagePath: fields[7] as String,
      isArchived: fields[8] as bool,
      notificationsEnabled: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, WarrantyItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.storeName)
      ..writeByte(3)
      ..write(obj.purchaseDate)
      ..writeByte(4)
      ..write(obj.warrantyPeriodInMonths)
      ..writeByte(5)
      ..write(obj.serialNumber)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.notificationsEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarrantyItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
