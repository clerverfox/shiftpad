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
  return UnknownFrame(bytes);
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
