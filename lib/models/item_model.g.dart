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
      id: fields[0] as String,
      category: fields[1] as String,
      originalTitle: fields[2] as String,
      userTitle: fields[3] as String?,
      originalDetail: fields[4] as String?,
      userDetail: fields[5] as String?,
      originalLink: fields[6] as String?,
      userLink: fields[7] as String?,
      classification: fields[8] as String?,
      originalItems: (fields[9] as List).cast<String>(),
      userAddedItems: (fields[10] as List?)?.cast<String>(),
      lastAccessed: fields[11] as DateTime?,
      clickCount: fields[12] as int,
      isUserCreated: fields[13] as bool,
      isUserChanged: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.classification)
      ..writeByte(9)
      ..write(obj.originalItems)
      ..writeByte(10)
      ..write(obj.userAddedItems)
      ..writeByte(11)
      ..write(obj.lastAccessed)
      ..writeByte(12)
      ..write(obj.clickCount)
      ..writeByte(13)
      ..write(obj.isUserCreated)
      ..writeByte(14)
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
