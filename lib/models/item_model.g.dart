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
      originalTitle: fields[1] as String,
      originalDetail: fields[2] as String?,
      link: fields[3] as String?,
      originalItems: (fields[4] as List).cast<String>(),
      category: fields[5] as String,
      lastAccessed: fields[6] as DateTime?,
      clickCount: fields[7] as int,
      classification: fields[8] as String?,
      userTitle: fields[9] as String?,
      userDetail: fields[10] as String?,
      userAddedItems: (fields[11] as List?)?.cast<String>(),
      isUserCreated: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalTitle)
      ..writeByte(2)
      ..write(obj.originalDetail)
      ..writeByte(3)
      ..write(obj.link)
      ..writeByte(4)
      ..write(obj.originalItems)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.lastAccessed)
      ..writeByte(7)
      ..write(obj.clickCount)
      ..writeByte(8)
      ..write(obj.classification)
      ..writeByte(9)
      ..write(obj.userTitle)
      ..writeByte(10)
      ..write(obj.userDetail)
      ..writeByte(11)
      ..write(obj.userAddedItems)
      ..writeByte(12)
      ..write(obj.isUserCreated);
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
