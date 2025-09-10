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
      name: fields[1] as String,
      detail: fields[2] as String?,
      link: fields[3] as String?,
      items: (fields[4] as List).cast<String>(),
      category: fields[5] as String,
      isUserAdded: fields[6] as bool,
      lastAccessed: fields[7] as DateTime?,
      clickCount: fields[8] as int,
      isFavorite: fields[9] as bool,
      classification: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.detail)
      ..writeByte(3)
      ..write(obj.link)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.isUserAdded)
      ..writeByte(7)
      ..write(obj.lastAccessed)
      ..writeByte(8)
      ..write(obj.clickCount)
      ..writeByte(9)
      ..write(obj.isFavorite)
      ..writeByte(10)
      ..write(obj.classification);
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