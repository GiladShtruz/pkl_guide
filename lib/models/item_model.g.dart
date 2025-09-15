// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemModelAdapter extends TypeAdapter<ItemModel> {
  @override
  final int typeId = 0;

  @override
  ItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemModel(
      id: fields[0] as int,
      category: fields[1] as String,
      originalTitle: fields[2] as String,
      userTitle: fields[3] as String?,
      originalDetail: fields[4] as String?,
      userDetail: fields[5] as String?,
      originalLink: fields[6] as String?,
      userLink: fields[7] as String?,
      originalClassification: fields[8] as String?,
      userClassification: fields[9] as String?,
      originalEquipment: fields[10] as String?,
      userEquipment: fields[11] as String?,
      originalElements: (fields[12] as List).cast<String>(),
      userElements: (fields[13] as List?)?.cast<String>(),
      lastAccessed: fields[14] as DateTime?,
      clickCount: fields[15] as int,
      isUserCreated: fields[16] as bool,
      isUserChanged: fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.originalTitle)
      ..writeByte(3)
      ..write(obj.userTitle)
      ..writeByte(4)
      ..write(obj.originalDetail)
      ..writeByte(5)
      ..write(obj.userDetail)
      ..writeByte(6)
      ..write(obj.originalLink)
      ..writeByte(7)
      ..write(obj.userLink)
      ..writeByte(8)
      ..write(obj.originalClassification)
      ..writeByte(9)
      ..write(obj.userClassification)
      ..writeByte(10)
      ..write(obj.originalEquipment)
      ..writeByte(11)
      ..write(obj.userEquipment)
      ..writeByte(12)
      ..write(obj.originalElements)
      ..writeByte(13)
      ..write(obj.userElements)
      ..writeByte(14)
      ..write(obj.lastAccessed)
      ..writeByte(15)
      ..write(obj.clickCount)
      ..writeByte(16)
      ..write(obj.isUserCreated)
      ..writeByte(17)
      ..write(obj.isUserChanged);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
