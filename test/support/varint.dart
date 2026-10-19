import 'dart:typed_data';

/// LEB128 varint encoder (test helper).
Uint8List encodeVarint(int v) {
  final out = <int>[];
  do {
    var b = v & 0x7F;
    v >>= 7;
    if (v != 0) b |= 0x80;
    out.add(b);
  } while (v != 0);
  return Uint8List.fromList(out);
}

Uint8List buttonsFrame(int bitmap) =>
    Uint8List.fromList([0x23, 0x08, ...encodeVarint(bitmap)]);

/// Buttons frame where only the buttons in [pressedMask] are pressed.
Uint8List pressedFrame(int pressedMask) =>
    buttonsFrame(0xFFFFFFFF & ~pressedMask);
