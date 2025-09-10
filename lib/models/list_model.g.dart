// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ListModelAdapter extends TypeAdapter<ListModel> {
  @override
  final int typeId = 1;

  @override
  ListModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ListModel(
      id: fields[0] as String,
      name: fields[1] as String,
      detail: fields[2] as String?,
      categoryItemIds: (fields[3] as List).cast<String>(),
      createdAt: fields[4] as DateTime,
      lastModified: fields[5] as DateTime?,
      isDefault: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ListModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.detail)
      ..writeByte(3)
      ..write(obj.categoryItemIds)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastModified)
      ..writeByte(6)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
