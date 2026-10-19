import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/zwift/click_frame.dart';

import '../support/varint.dart';

void main() {
  test('release frame has no buttons pressed', () {
    final f = parseClickFrame(
        Uint8List.fromList([0x23, 0x08, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F]));
    expect((f as ButtonsFrame).pressed, isEmpty);
  });
  test('plus pressed (bit 0x1000 cleared)', () {
    expect(
        (parseClickFrame(buttonsFrame(0xFFFFFFFF & ~0x1000)) as ButtonsFrame)
            .pressed,
        {ClickButton.plus});
  });
  test('minus and up pressed together', () {
    expect(
        (parseClickFrame(buttonsFrame(0xFFFFFFFF & ~0x100 & ~0x2))
                as ButtonsFrame)
            .pressed,
        {ClickButton.minus, ClickButton.up});
  });
  test('RideOn echo', () {
    expect(
        parseClickFrame(Uint8List.fromList(
            [0x52, 0x69, 0x64, 0x65, 0x4F, 0x6E, 0x02, 0x03])),
        isA<RideOnFrame>());
  });
  test('lock challenge', () {
    expect(parseClickFrame(Uint8List.fromList([0xFF, 0x03, 0x00, 0x01, 0x02])),
        isA<LockChallengeFrame>());
  });
  test('garbage never throws', () {
    for (final b in [
      <int>[],
      [0x23],
      [0x23, 0x08],
      [0x23, 0x08, 0xFF],
      [0x99, 1, 2],
      [0x23, 0x10, 0x01],
      [0x23, 0x08, ...List.filled(12, 0xFF)],
    ]) {
      expect(() => parseClickFrame(Uint8List.fromList(b)), returnsNormally);
    }
    expect(parseClickFrame(Uint8List.fromList([0x23])), isA<UnknownFrame>());
    expect(parseClickFrame(Uint8List.fromList([0x23, 0x08, 0xFF])),
        isA<UnknownFrame>());
  });
}
