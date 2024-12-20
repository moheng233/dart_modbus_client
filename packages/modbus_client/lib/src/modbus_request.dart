import 'dart:typed_data';

import 'element_type/modbus_element.dart';
import 'modbus_response.dart';
import 'modbus_type.dart';

/// The base Modbus request
///
/// For each Modbus request, a PDU response function code + 0x80
/// means the request has an exception.
/// The [ModbusResponseCode] defines possible modbus Exception.
///
/// Exception response PDU
/// ----------------------
/// BYTE - Function Code + 0x80
/// BYTE - Exception Code
sealed class ModbusRequest {
  final int? unitId;
  final Duration? responseTimeout;
  final ModbusEndianness endianness;

  Uint8List get protocolDataUnit;
  FunctionCode get functionCode;
  int get responsePduLength;

  const ModbusRequest({
    this.unitId,
    this.responseTimeout,
    this.endianness = ModbusEndianness.ABCD,
  });

  Uint16List _getPayloadData(Uint8List pdu);

  ModbusResponse getPayload(Uint8List pdu) {
    var pduView = ByteData.view(pdu.buffer);
    int functionCode = pduView.getUint8(0);

    // Any error code?
    if ((functionCode & 0x80) != 0) {
      int exceptionCode = pduView.getUint8(1);
      return ModbusFailedResponse(ModbusResponseCode.fromCode(exceptionCode));
    }

    return ModbusSuccessResponse(_getPayloadData(pdu));
  }
}

/// A request for a modbus element.
sealed class ModbusElementRequest extends ModbusRequest {
  const ModbusElementRequest({super.unitId, super.responseTimeout, super.endianness});

  @override
  Uint16List _getPayloadData(Uint8List pdu) {
    if (functionCode.type == FunctionType.read) {
      return Uint16List.sublistView(pdu, 2);
    } else if (functionCode.type == FunctionType.writeSingle) {
      return Uint16List.sublistView(pdu, 3);
    }
    if (functionCode.type == FunctionType.writeMultiple) {
      return Uint16List.sublistView(pdu, 6);
    }

    switch(functionCode.type) {
      case FunctionType.read:
        return Uint16List.sublistView(pdu, 2);
      case FunctionType.writeSingle:
        return Uint16List.sublistView(pdu, 3);
      case FunctionType.writeMultiple:
        return Uint16List.sublistView(pdu, 6);
      case FunctionType.custom:
        return Uint16List(0);
    }
  }
}

/// A read request of a single element.
final class ModbusReadRequest extends ModbusElementRequest {
  // Request PDU
  // -----------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Elements Count
  //
  // Response PDU
  // ------------
  // BYTE - Function Code
  // BYTE - Byte Count
  // N BYTES - Element Values

  @override
  final FunctionCode functionCode;
  @override
  final Uint8List protocolDataUnit;
  final ModbusElement element;
  
  const ModbusReadRequest(this.element, this.protocolDataUnit, this.functionCode,
      {super.unitId, super.responseTimeout, super.endianness});

  @override
  int get responsePduLength => 2 + element.wordCount;
}

/// A write request of a single element.
final class ModbusWriteRequest extends ModbusElementRequest {
  @override
  final FunctionCode functionCode;
  @override
  final Uint8List protocolDataUnit;
  final ModbusElement element;
  const ModbusWriteRequest(this.element, this.protocolDataUnit, this.functionCode,
      {super.unitId, super.responseTimeout, super.endianness});

  // Request PDU
  // -----------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Register Value
  //
  // Response PDU
  // ------------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Register Value

  @override
  int get responsePduLength => 5;
}

/// A write request of an elements group.
/* TODO: define multiple write "strategy"!
class ModbusWriteGroupRequest extends ModbusElementRequest {
  // Request PDU
  // -----------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Register Count
  // BYTE - Byte Count
  // N WORDS - Register values
  //
  // Response PDU
  // ------------
  // BYTE - Function Code
  // WORD - First Address
  // WORD - Register Count

  final ModbusElementsGroup elementGroup;
  ModbusWriteGroupRequest(this.elementGroup, super.protocolDataUnit, [super.unitId]);

  @override
  int get responsePduLength => 5;

  @override
  void internalSetElementData(Uint8List data);
}
*/
