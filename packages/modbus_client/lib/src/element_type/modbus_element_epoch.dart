import 'dart:typed_data';

import 'modbus_element.dart';
import '../util/convert.dart';

/// The Modbus epoch type used by [ModbusEpochRegister].
enum ModbusEpochType { seconds, milliseconds }

// TODO: lets have a uint64 register for the milliseconds implementation!

/// This Uint32 register type converts the device epoch value into a [DateTime].
final class ModbusEpochRegister extends ModbusElement<DateTime> {
  final bool isUtc;
  final ModbusEpochType epochType = ModbusEpochType.seconds;

  const ModbusEpochRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      this.isUtc = false})
      : super(wordCount: 2);

  @override
  DateTime decodeValue(Uint16List raw) {
    var rawValue = ByteData.view(raw.buffer).getUint32(0);
    return DateTime.fromMillisecondsSinceEpoch(
        epochType == ModbusEpochType.seconds ? rawValue * 1000 : rawValue);
  }

  @override
  Uint16List encodeValue(DateTime value) {
    return (epochType == ModbusEpochType.milliseconds
            ? value.millisecondsSinceEpoch
            : value.millisecondsSinceEpoch ~/ 1000)
        .toUint16List();
  }
}
