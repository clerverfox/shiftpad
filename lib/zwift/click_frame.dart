import 'dart:typed_data';

import '../core/click_button.dart';
import 'click_constants.dart';

sealed class ClickFrame {
  const ClickFrame();
}

class ButtonsFrame extends ClickFrame {
  const ButtonsFrame(this.pressed);
  final Set<ClickButton> pressed;
}

class RideOnFrame extends ClickFrame {
  const RideOnFrame();
}

class LockChallengeFrame extends ClickFrame {
  const LockChallengeFrame(this.bytes);
  final Uint8List bytes;
}

/// Opcode 0x19, e.g. `19 10 5a` = 90 % (seen on hardware, checkpoint A).
class BatteryFrame extends ClickFrame {
  const BatteryFrame(this.percent);
  final int percent;
}

/// Opcode 0x3C, sent after `00 08 00`. Firmware is best-effort.
class DeviceInfoFrame extends ClickFrame {
  const DeviceInfoFrame(this.firmware);
  final String? firmware;
}

class UnknownFrame extends ClickFrame {
  const UnknownFrame(this.bytes);
  final Uint8List bytes;
}

/// Parses one notification from a Click V2. Never throws.
ClickFrame parseClickFrame(Uint8List bytes) {
  if (bytes.isEmpty) return UnknownFrame(bytes);
  if (_startsWith(bytes, kRideOn)) return const RideOnFrame();
  if (bytes.length >= 2 && bytes[0] == kOpLockChallenge && bytes[1] == 0x03) {
    return LockChallengeFrame(bytes);
  }
  if (bytes[0] == kOpButtons) {
    final bitmap = _readField1Varint(bytes, 1);
    if (bitmap == null) return UnknownFrame(bytes);
    return ButtonsFrame({
      for (final b in ClickButton.values)
        if (bitmap & b.mask == 0) b,
    });
  }
  if (bytes[0] == kOpBattery) {
    final fields = _readFields(bytes, 1);
    final percent = fields?[2];
    if (percent is int && percent <= 100) return BatteryFrame(percent);
    return UnknownFrame(bytes);
  }
  if (bytes[0] == kOpDeviceInfo) {
    return DeviceInfoFrame(_firmwareFromInfo(bytes));
  }
  return UnknownFrame(bytes);
}

/// `3c 08 00 12 <len> 0a <len> 08 .. 12 04 00 00 02 01 ...`: the 4-byte
/// field 2 of the nested record reads 1.2.0 when reversed.
String? _firmwareFromInfo(Uint8List bytes) {
  final outer = _readFields(bytes, 1)?[2];
  if (outer is! Uint8List) return null;
  final record = _readFields(outer, 0)?[1];
  if (record is! Uint8List) return null;
  final fw = _readFields(record, 0)?[2];
  if (fw is! Uint8List || fw.length != 4) return null;
  return '${fw[3]}.${fw[2]}.${fw[1]}';
}

/// Minimal protobuf reader: varints (wire type 0) as int, length-delimited
/// (wire type 2) as bytes. Returns null on anything else or on truncation.
Map<int, Object>? _readFields(Uint8List bytes, int offset) {
  final out = <int, Object>{};
  var i = offset;
  (int, int)? varint() {
    var value = 0;
    var shift = 0;
    while (i < bytes.length && shift < 64) {
      final b = bytes[i++];
      value |= (b & 0x7F) << shift;
      if (b & 0x80 == 0) return (value, i);
      shift += 7;
    }
    return null;
  }

  while (i < bytes.length) {
    final key = varint();
    if (key == null) return null;
    final field = key.$1 >> 3;
    switch (key.$1 & 0x7) {
      case 0:
        final v = varint();
        if (v == null) return null;
        out[field] = v.$1;
      case 2:
        final len = varint();
        if (len == null || i + len.$1 > bytes.length) return null;
        out[field] = Uint8List.sublistView(bytes, i, i + len.$1);
        i += len.$1;
      default:
        return null;
    }
  }
  return out;
}

bool _startsWith(Uint8List bytes, Uint8List prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

/// Reads protobuf field 1 (varint, tag 0x08) starting at [offset].
int? _readField1Varint(Uint8List bytes, int offset) {
  if (offset >= bytes.length || bytes[offset] != 0x08) return null;
  var value = 0;
  var shift = 0;
  for (var i = offset + 1; i < bytes.length && shift < 64; i++) {
    final b = bytes[i];
    value |= (b & 0x7F) << shift;
    if (b & 0x80 == 0) return value;
    shift += 7;
  }
  return null;
}
