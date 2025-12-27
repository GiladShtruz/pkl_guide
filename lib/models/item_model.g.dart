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
      isElementsChanged: fields[15] as bool,
      lastAccessed: fields[16] as DateTime?,
      clickCount: fields[17] as int,
      isUserCreated: fields[18] as bool,
      isUserChanged: fields[19] as bool,
      selectedElements: (fields[20] as List?)?.cast<bool>(),
      elementTextsParam: (fields[13] as List?)?.cast<String>(),
      isUserElementListParam: (fields[14] as List?)?.cast<bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(20)
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
      ..writeByte(13)
      ..write(obj.elementTexts)
      ..writeByte(14)
      ..write(obj.isUserElementList)
      ..writeByte(15)
      ..write(obj.isElementsChanged)
      ..writeByte(16)
      ..write(obj.lastAccessed)
      ..writeByte(17)
      ..write(obj.clickCount)
      ..writeByte(18)
      ..write(obj.isUserCreated)
      ..writeByte(19)
      ..write(obj.isUserChanged)
      ..writeByte(20)
      ..write(obj.selectedElements);
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
