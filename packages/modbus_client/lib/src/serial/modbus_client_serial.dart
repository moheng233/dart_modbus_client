import 'dart:async';
import 'dart:typed_data';

import 'package:synchronized/synchronized.dart';

import '../../modbus_client.dart';
import '../modbus_response.dart';
import 'modbus_serial_port.dart';

/// The serial Modbus client class.
abstract class ModbusClientSerial extends ModbusClient {
  ModbusSerialPort serialPort;
  final Lock _lock = Lock();

  ModbusClientSerial(
      {required this.serialPort,
      super.unitId,
      super.connectionMode = ModbusConnectionMode.autoConnectAndKeepConnected,
      super.responseTimeout = const Duration(seconds: 3)});

  /// Returns the serial telegram checksum length
  int get checksumByteCount;

  /// Returns the modbus telegram out of this request's PDU
  Uint8List getTxTelegram(ModbusRequest request, int unitId);

  /// Read response from device.
  Future<ModbusResponseCode> readResponseHeader(
      ModbusSerialResponse response, Duration timeout);

  /// Reads the full pdu response from device.
  ///
  /// NOTE: response header should be read already!
  Future<ModbusResponseCode> readResponsePdu(
      ModbusSerialResponse response, Duration timeout);

  /// Returns true if connection is established
  @override
  bool get isConnected => serialPort.isOpen;

  /// Close the connection
  @override
  Future<void> disconnect() async {
    ModbusAppLogger.fine("Closing serial port ${serialPort.name}...");
    if (serialPort.isOpen) {
      await serialPort.close();
    }
  }

  /// Sends a modbus request
  @override
  Future<ModbusResponse> send(ModbusRequest request) async {
    Duration resTimeout = getResponseTimeout(request);
    var res = await _lock.synchronized<ModbusResponse>(() async {
      // Connect if needed
      try {
        if (connectionMode != ModbusConnectionMode.doNotConnect) {
          await connect();
        }
        if (!isConnected) {
          return ModbusFailedResponse(ModbusResponseCode.connectionFailed);
        }
      } catch (ex) {
        ModbusAppLogger.severe(
            "Unexpected exception in connecting to ${serialPort.name}", ex);
        return ModbusFailedResponse(ModbusResponseCode.connectionFailed);
      }

      // Start a stopwatch for the request timeout
      final reqStopwatch = Stopwatch()..start();

      // Send the request data
      var unitId = getUnitId(request);
      try {
        // Flush both tx & rx buffers (discard old pending requests & responses)
        await serialPort.flush();

        // Sent the serial telegram
        var reqTxData = getTxTelegram(request, unitId);
        int txDataCount =
            await serialPort.write(reqTxData, timeout: resTimeout);
        if (txDataCount < reqTxData.length) {
          return ModbusFailedResponse(ModbusResponseCode.requestTimeout);
        }
      } catch (ex) {
        ModbusAppLogger.severe(
            "Unexpected exception in sending data to ${serialPort.name}", ex);
        return ModbusFailedResponse(ModbusResponseCode.requestTxFailed);
      }

      // Lets check the response header (i.e.read first bytes only to check if
      // response is normal or has error)
      var response = ModbusSerialResponse(
          request: request,
          unitId: unitId,
          checksumByteCount: checksumByteCount);
      Duration remainingTime = resTimeout - reqStopwatch.elapsed;
      var responseCode = remainingTime.isNegative
          ? ModbusResponseCode.requestTimeout
          : await readResponseHeader(response, remainingTime);
      if (responseCode != ModbusResponseCode.requestSucceed) {
        return ModbusFailedResponse(responseCode);
      }

      // Lets wait the rest of the PDU response
      remainingTime = resTimeout - reqStopwatch.elapsed;
      responseCode = remainingTime.isNegative
          ? ModbusResponseCode.requestTimeout
          : await readResponsePdu(response, remainingTime);
      if (responseCode != ModbusResponseCode.requestSucceed) {
        return ModbusFailedResponse(responseCode);
      }

      return ModbusSuccessResponse(Uint16List.view(response.pdu.buffer));
    });
    // Need to disconnect?
    if (connectionMode == ModbusConnectionMode.autoConnectAndDisconnect) {
      await disconnect();
    }
    return res;
  }

  /// Connect the port if not already done or disconnected
  @override
  Future<bool> connect() async {
    if (isConnected) {
      return true;
    }
    ModbusAppLogger.fine("Opening serial port ${serialPort.name}...");
    return serialPort.open();
  }
}

/// The modbus serial response is composed from:
/// BYTE - UnitId
/// BYTE - Function code
/// BYTE - Modbus exception code if Function code & 0x80 (i.e. bit 8 == 1)
class ModbusSerialResponse {
  final ModbusRequest request;
  final int unitId;
  final int checksumByteCount;

  ModbusSerialResponse(
      {required this.request,
      required this.unitId,
      required this.checksumByteCount});

  List<int>? _rxData;
  void setRxData(List<int> rxData) =>
      _rxData = List<int>.from(rxData, growable: true);
  void addRxData(List<int> rxData) => _rxData!.addAll(rxData);

  ModbusResponseCode get headerResponseCode {
    if (_rxData == null || _rxData!.length < 3) {
      return ModbusResponseCode.requestRxFailed;
    }
    if (_rxData![0] != unitId) {
      return ModbusResponseCode.requestRxWrongUnitId;
    }
    if ((_rxData![1] & 0x80) != 0) {
      return ModbusResponseCode.fromCode(_rxData![2]);
    }
    if (_rxData![1] != request.functionCode.code) {
      return ModbusResponseCode.requestRxWrongFunctionCode;
    }
    return ModbusResponseCode.requestSucceed;
  }

  Iterable<int> getRxData({required bool includeChecksum}) => _rxData!
      .getRange(0, _rxData!.length - (includeChecksum ? 0 : checksumByteCount));

  Uint8List get pdu => // serial telegram has: <unit id> + <pdu> + <checksum>
      _rxData == null
          ? Uint8List(0)
          : Uint8List.fromList(
              _rxData!.sublist(1, _rxData!.length - checksumByteCount));

  Uint8List get checksum => _rxData == null
      ? Uint8List(0)
      : Uint8List.fromList(
          _rxData!.sublist(_rxData!.length - checksumByteCount));
}
