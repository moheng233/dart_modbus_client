import 'dart:typed_data';

import '../../modbus_client.dart';
import 'modbus_element.dart';

/// A Modbus bit value element. This is the base class of [ModbusDiscreteInput]
/// and [ModbusCoil] elements.
sealed class ModbusBitElement extends ModbusElement<bool> {
  const ModbusBitElement({
    required super.name,
    super.description,
    required super.address,
    required super.type,
  }) : super(wordCount: 1);

  @override
  Uint16List encodeValue(bool value) =>
      Uint16List.fromList([value ? 0x0000 : 0xFF00]);

  @override
  bool decodeValue(Uint16List raw) {
    assert(raw.isNotEmpty);
    if (raw[0] > 0) {
      return true;
    } else {
      return false;
    }
  }
}

/// A Modbus [ModbusElementType.discreteInput] value element.
final class ModbusDiscreteInput extends ModbusBitElement {
  ModbusDiscreteInput({
    required super.name,
    super.description,
    required super.address,
  }) : super(type: ModbusElementType.discreteInput);
}

/// A Modbus [ModbusElementType.coil] value element.
final class ModbusCoil extends ModbusBitElement {
  ModbusCoil({
    required super.name,
    super.description,
    required super.address,
  }) : super(type: ModbusElementType.coil);
}
