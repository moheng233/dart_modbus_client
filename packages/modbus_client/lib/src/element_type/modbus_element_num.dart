import 'dart:typed_data';

import '../modbus_type.dart';
import 'modbus_element.dart';

/// A numeric register where [type] can be [ModbusElementType.inputRegister] or
/// [ModbusElementType.inputRegister]. The returned device value
/// (i.e. raw value) can be of type Int16, Uint16, Int32 or Uint32.
///
/// This raw value might be converted into an engineering value by this formula:
///    engineering value = raw value * [multiplier] + [offset]
///
/// The string representation of the engineering value can have a unit of
/// measure [uom] and rounded decimal places [viewDecimalPlaces].
sealed class ModbusNumRegister<T extends num> extends ModbusElement<T> {
  final double multiplier;
  final double offset;
  final String uom;
  final int viewDecimalPlaces;

  const ModbusNumRegister(
      {required super.name,
      super.description,
      required super.type,
      required super.address,
      required super.wordCount,
      this.uom = "",
      this.multiplier = 1,
      this.offset = 0,
      this.viewDecimalPlaces = 2,
      super.endianness = ModbusEndianness.ABCD});

  T _fromBytes(Uint16List bytes);
  Uint16List _toBytes(T value);
}

sealed class AbsModbusIntRegister extends ModbusNumRegister<int> {
  const AbsModbusIntRegister({
    required super.name,
    required super.type,
    required super.address,
    required super.wordCount,
    super.description,
    super.uom,
    super.multiplier,
    super.offset,
    super.viewDecimalPlaces,
    super.endianness,
  });

  @override
  Uint16List encodeValue(int value) =>
      _toBytes(((value - offset) ~/ multiplier).toInt());

  @override
  int decodeValue(Uint16List raw) =>
      ((_fromBytes(endianness.getEndianWords(raw)) * multiplier) + offset)
          .toInt();
}

sealed class AbsModbusDoubleRegister extends ModbusNumRegister<double> {
  const AbsModbusDoubleRegister({
    required super.name,
    required super.type,
    required super.address,
    required super.wordCount,
    super.description,
    super.uom,
    super.multiplier,
    super.offset,
    super.viewDecimalPlaces,
    super.endianness,
  });

  @override
  Uint16List encodeValue(double value) => endianness
      .getEndianWords(_toBytes(((value - offset) ~/ multiplier).toDouble()));

  @override
  double decodeValue(Uint16List raw) =>
      ((_fromBytes(endianness.getEndianWords(raw)) * multiplier) + offset)
          .toDouble();
}

/// A signed 16 bit register
final class ModbusInt16Register extends AbsModbusIntRegister {
  const ModbusInt16Register(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.uom,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(wordCount: 1);

  @override
  int _fromBytes(Uint16List bytes) => ByteData.view(bytes.buffer, 0, wordCount)
      .getInt16(0, endianness.swapByte ? Endian.little : Endian.big);

  @override
  Uint16List _toBytes(dynamic value) =>
      Uint16List(wordCount)..buffer.asByteData().setInt16(0, value);
}

/// An unsigned 16 bit register
final class ModbusUint16Register extends AbsModbusIntRegister {
  const ModbusUint16Register(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.uom,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(wordCount: 1);

  @override
  int _fromBytes(Uint16List bytes) => bytes.buffer
      .asByteData()
      .getUint16(0, endianness.swapByte ? Endian.little : Endian.big);

  @override
  Uint16List _toBytes(dynamic value) =>
      Uint16List(wordCount)..buffer.asByteData().setUint16(0, value);
}

/// A signed 32 bit register
final class ModbusInt32Register extends AbsModbusIntRegister {
  const ModbusInt32Register(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.uom,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(wordCount: 2);

  @override
  int _fromBytes(Uint16List bytes) => bytes.buffer.asByteData().getInt32(0);

  @override
  Uint16List _toBytes(dynamic value) =>
      Uint16List(wordCount)..buffer.asByteData().setInt32(0, value);
}

/// An unsigned 32 bit register
final class ModbusUint32Register extends AbsModbusIntRegister {
  const ModbusUint32Register(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(wordCount: 2);

  @override
  int _fromBytes(Uint16List bytes) => bytes.buffer.asByteData().getUint32(0);

  @override
  Uint16List _toBytes(dynamic value) =>
      Uint16List(wordCount)..buffer.asByteData().setUint32(0, value);
}

/// A signed 64 bit register
final class ModbusInt64Register extends AbsModbusIntRegister {
  const ModbusInt64Register(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.uom,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(wordCount: 4);

  @override
  int _fromBytes(Uint16List bytes) => bytes.buffer.asByteData().getInt64(0);

  @override
  Uint16List _toBytes(dynamic value) =>
      Uint16List(wordCount)..buffer.asByteData().setInt64(0, value);
}

/// An unsigned 64 bit register
final class ModbusUint64Register extends AbsModbusIntRegister {
  const ModbusUint64Register(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(wordCount: 4);

  @override
  int _fromBytes(Uint16List bytes) => bytes.buffer.asByteData().getUint64(0);

  @override
  Uint16List _toBytes(dynamic value) =>
      Uint16List(wordCount)..buffer.asByteData().setUint64(0, value);
}

/// A 32 bit Float register
final class ModbusFloatRegister extends AbsModbusDoubleRegister {
  const ModbusFloatRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(wordCount: 2);


  @override
  double _fromBytes(Uint16List bytes) =>
      bytes.buffer.asByteData().getFloat32(0);

  @override
  Uint16List _toBytes(dynamic value) =>
      Uint16List(wordCount)..buffer.asByteData().setFloat32(0, value);
}

/// A 64 bit Double register
final class ModbusDoubleRegister extends AbsModbusDoubleRegister {
  const ModbusDoubleRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.multiplier,
      super.offset,
      super.viewDecimalPlaces,
      super.endianness})
      : super(wordCount: 4);

  @override
  double _fromBytes(Uint16List bytes) =>
      bytes.buffer.asByteData().getFloat64(0);

  @override
  Uint16List _toBytes(dynamic value) =>
      Uint16List(wordCount)..buffer.asByteData().setFloat64(0, value);
}
