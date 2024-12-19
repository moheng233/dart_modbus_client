import 'dart:typed_data';

import '../../modbus_client.dart';

/// The base element class
abstract class ModbusElement<T> {
  final String name;
  final String description;
  final ModbusElementType type;
  final int address;
  final ModbusEndianness endianness;

  final int byteCount;

  const ModbusElement({
    required this.name,
    this.description = "",
    required this.type,
    required this.address,
    required this.byteCount,
    this.endianness = ModbusEndianness.ABCD,
  });

  /// Gets a read request from this element
  ModbusReadRequest getReadRequest(
      {int? unitId, Duration? responseTimeout, ModbusEndianness? endianness}) {
    var pdu = Uint8List(5);
    ByteData.view(pdu.buffer)
      ..setUint8(0, type.readFunction.code)
      ..setUint16(1, address)
      ..setUint16(3, byteCount > 1 ? byteCount ~/ 2 : 1);
    return ModbusReadRequest(this, pdu, type.readFunction,
        unitId: unitId,
        responseTimeout: responseTimeout,
        endianness: endianness ?? this.endianness);
  }

  /// Gets a write request from this register element.
  /// [value] is set to the element once request is successfully completed.
  /// If [rawValue] is true then the integer [value] is written as it is
  /// without any value or type conversion.
  ModbusWriteRequest getWriteRequest(
    T value, {
    int? unitId,
    Duration? responseTimeout,
    ModbusEndianness? endianness,
  }) {
    if (type.writeSingleFunction == null) {
      throw ModbusException(
          context: "ModbusElement.getWriteRequest",
          msg: "$type element does not support write request!");
    }

    final raw = encodeValue(value);

    // Build the request object
    final pdu = Uint8List(2 + (byteCount * 2));
    ByteData.view(pdu.buffer)
      ..setUint8(0, type.writeSingleFunction!.code)
      ..setUint16(1, address)
      ..setUint16(2, raw[0]);

    return ModbusWriteRequest(this, pdu, type.writeSingleFunction!,
        unitId: unitId,
        responseTimeout: responseTimeout,
        endianness: endianness ?? this.endianness);
  }

  /// Gets a write request from multiple register elements.
  ModbusWriteRequest getMultipleWriteRequest(Uint16List bytes,
      {int? unitId, Duration? responseTimeout, ModbusEndianness? endianness}) {
    if (type.writeMultipleFunction == null) {
      throw ModbusException(
          context: "ModbusBitElement",
          msg: "$type element does not support multiple write request!");
    }
    // Build the request object
    var pdu = Uint8List(6 + bytes.length);
    pdu.setAll(
      6,
      endianness == null
          ? bytes
          : endianness.getEndianBytesUint8(Uint8List.view(bytes.buffer)),
    );
    ByteData.view(pdu.buffer)
      ..setUint8(0, type.writeMultipleFunction!.code)
      ..setUint16(1, address)
      ..setUint16(3, bytes.length ~/ 2) // value register count
      ..setUint8(5, bytes.length); // value byte count
    return ModbusWriteRequest(this, pdu, type.writeMultipleFunction!,
        unitId: unitId,
        responseTimeout: responseTimeout,
        endianness: endianness ?? this.endianness);
  }

  Uint16List encodeValue(T value);
  T decodeValue(Uint16List raw);
}
