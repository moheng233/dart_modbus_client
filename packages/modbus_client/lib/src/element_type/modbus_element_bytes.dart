import 'dart:typed_data';

import '../../modbus_client.dart';
import 'modbus_element.dart';

/// This register type reads and writes byte array.
///
/// The [wordCount] cannot exceed 250 bytes which is the multiple read
/// bytes limit for Modbus/RTU. Note that the protocol limit depends on multiple
/// factors:
///  - Read & Write have different limits
///  - Modbus RTU and TCP have different limits
///  - Device dependent limits
/// To get the right limit please refer to Modbus specs and your device manual.
final class ModbusBytesRegister extends ModbusElement<Uint8List> {
  const ModbusBytesRegister({
    required super.name,
    required super.address,
    required super.wordCount,
    super.description,
    super.type = ModbusElementType.holdingRegister,
  });

  @override
  Uint8List decodeValue(Uint16List raw) {
    return Uint8List.view(raw.buffer);
  }

  @override
  Uint16List encodeValue(Uint8List value) {
    return Uint16List.view(value.buffer);
  }

  @override
  ModbusWriteRequest getWriteRequest(Uint8List value,
      {bool rawValue = false,
      int? unitId,
      Duration? responseTimeout,
      ModbusEndianness? endianness}) {
    // Expecting a same length as the original byte count
    if (value.length != wordCount) {
      throw ModbusException(
          context: "ModbusBytesRegister",
          msg: "The length of 'value' must match 'byteCount'!");
    }
    // Expecting a multiple write function code
    if (type.writeMultipleFunction == null) {
      throw ModbusException(
          context: "ModbusBytesRegister.getWriteRequest",
          msg: "ModbusBytesRegister requires 'writeMultipleFunction' code!");
    }
    return getMultipleWriteRequest(encodeValue(value),
        unitId: unitId,
        responseTimeout: responseTimeout,
        endianness: endianness);
  }
}
