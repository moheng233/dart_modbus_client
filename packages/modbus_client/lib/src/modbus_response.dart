import 'dart:typed_data';

import '../modbus_client.dart';

sealed class ModbusResponse {
  final ModbusResponseCode responseCode;

  const ModbusResponse(this.responseCode);
}

final class ModbusSuccessResponse extends ModbusResponse {
  final Uint16List data;

  const ModbusSuccessResponse(this.data) : super(ModbusResponseCode.success);
}

final class ModbusFailedResponse extends ModbusResponse {
  ModbusFailedResponse(super.responseCode);
}
