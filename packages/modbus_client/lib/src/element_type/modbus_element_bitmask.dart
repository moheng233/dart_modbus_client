import 'dart:typed_data';

import 'modbus_element.dart';

/// A Modbus bit mask type used by [ModbusBitMaskRegister].
/// If the specified register [bit] number (0 based index) is 1 then [isActive]
/// is set to true and the bit mask [value] returns the [activeValue] else the
/// [inactiveValue].
class ModbusBitMask {
  final int bit;
  final dynamic activeValue;
  final dynamic inactiveValue;

  const ModbusBitMask(this.bit, this.activeValue, [this.inactiveValue]);
}

/// This Uint16 register type sets the value of a list of [ModbusBitMask]
/// objects.
final class ModbusBitMaskRegister extends ModbusElement<int> {
  final List<ModbusBitMask> bitMasks;

  const ModbusBitMaskRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      required this.bitMasks})
      : super(wordCount: 1);

  @override
  int decodeValue(Uint16List raw) {
    assert(raw.isNotEmpty);
    return raw[0];
  }

  @override
  Uint16List encodeValue(int value) {
    return Uint16List.fromList([value]);
  }

  ///TODO:
}
