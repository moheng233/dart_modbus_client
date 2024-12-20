import 'package:modbus_client/src/element_type/modbus_element.dart';

import 'modbus_request.dart';
import 'modbus_response.dart';
import 'modbus_type.dart';

/// The Modbus client definition.
///
/// The client can send a [ModbusRequest] retrieved by a [ModbusElement].
///
/// If [unitId] id specified then it is used to make requests. The [unitId] is
/// overridden in case the [send] command has it's own [unitId] defined.
///
/// Based on the [connectionMode] send command will connect in case current
/// connection is not yet established.
abstract class ModbusClient {
  final int? unitId;
  final Duration responseTimeout;
  final ModbusConnectionMode connectionMode;

  ModbusClient({
    this.unitId,
    this.responseTimeout = const Duration(seconds: 3),
    this.connectionMode = ModbusConnectionMode.autoConnectAndKeepConnected,
  });

  /// Sends the modbus requests. A [ModbusResponseCode] is returned as a future.
  ///
  /// If [request] has its own [unitId] defined, then it will override this
  /// client [unitId] (see [getUnitId]).
  ///
  /// If [request] has its own [responseTimeout] defined, then it will override
  /// this client [responseTimeout] (see [getResponseTimeout]).
  Future<ModbusResponse> send(ModbusRequest request);

  Future<T> read<T>(
    ModbusElement<T> element, {
    int? unitId,
    Duration? responseTimeout,
    ModbusEndianness? endianness,
  }) async {
    final response = await send(element.getReadRequest(
      unitId: unitId,
      responseTimeout: responseTimeout,
      endianness: endianness,
    ));

    if (response is ModbusFailedResponse) {
      throw ModbusException(
        context: response.toString(),
        msg: response.responseCode.name,
      );
    } else {
      return element.decodeValue((response as ModbusSuccessResponse).data);
    }
  }

  /// Returns true if connection to client is established.
  bool get isConnected;

  /// Connects to the client and returns true if connection is successfully
  /// established.
  Future<bool> connect();

  /// Disconnects from current client
  Future<void> disconnect();

  /// If [request] has its own [unitId] defined, then it will override this
  /// client [unitId]. If both [unitId] are not defined the a 0 is returned.
  int getUnitId(ModbusRequest request) => request.unitId != null
      ? request.unitId!
      : unitId != null
          ? unitId!
          : 0;

  /// If [request] has its own [responseTimeout] defined, then it will override
  /// this client [responseTimeout].
  Duration getResponseTimeout(ModbusRequest request) =>
      request.responseTimeout ?? responseTimeout;
}
