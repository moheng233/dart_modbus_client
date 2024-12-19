import 'dart:typed_data';

extension IntConvert on int {
  Uint8List toUint8List() {
    final raw = Uint8List(4);
    ByteData.view(raw.buffer).setInt64(0, this);
    return raw;
  }

  Uint16List toUint16List() {
    final raw = Uint16List(2);
    ByteData.view(raw.buffer).setInt64(0, this);
    return raw;
  }
}
