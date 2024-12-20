import 'dart:typed_data';

import 'modbus_element.dart';

/// A Modbus enumeration type used by [ModbusEnumRegister]
abstract interface class ModbusIntEnum {
  int get intValue;
}

/// An enumeration register. The Uin16 register value is converted into a user
/// defined enumeration.
/// Example:
///   enum BatteryStatus implements ModbusIntEnum {
///     offline(0),
///     standby(1),
///     running(2),
///     fault(3),
///     sleepMode(4);
///
///     const BatteryStatus(this.intValue);
///     @override
///     final int intValue;
///   }
///
///   var batteryStatus = ModbusEnumRegister(
///     name: "BatteryStatus",
///     address: 37000,
///     enumValues: BatteryStatus.values);
final class ModbusEnumRegister<T extends ModbusIntEnum>
    extends ModbusElement<T> {
  final List<T> enumValues;
  final T? defaultValue;

  const ModbusEnumRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      required this.enumValues,
      this.defaultValue})
      : super(wordCount: 1);

  @override
  T decodeValue(Uint16List raw) {
    assert(raw.isNotEmpty);
    return enumValues.firstWhere((v) => v.intValue == raw[0]);
  }

  @override
  Uint16List encodeValue(T value) {
    return Uint16List.fromList([value.intValue]);
  }
}
