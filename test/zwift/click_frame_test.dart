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

  // Frames captured from the owner's pods at checkpoint A (2026-10-19).
  Uint8List bytesOf(String hexText) => Uint8List.fromList(
      hexText.split(' ').map((h) => int.parse(h, radix: 16)).toList());

  test('real captures decode to the right buttons', () {
    for (final (frame, button) in [
      ('23 08 ef ff ff ff 0f', ClickButton.a),
      ('23 08 df ff ff ff 0f', ClickButton.b),
      ('23 08 bf ff ff ff 0f', ClickButton.y),
      ('23 08 ff fe ff ff 0f', ClickButton.z),
      ('23 08 ff df ff ff 0f', ClickButton.plus),
      ('23 08 fe ff ff ff 0f', ClickButton.left),
      ('23 08 fd ff ff ff 0f', ClickButton.up),
      ('23 08 fb ff ff ff 0f', ClickButton.right),
      ('23 08 f7 ff ff ff 0f', ClickButton.down),
      ('23 08 ff fd ff ff 0f', ClickButton.minus),
    ]) {
      expect((parseClickFrame(bytesOf(frame)) as ButtonsFrame).pressed, {button},
          reason: frame);
    }
  });

  test('battery frame 19 10 5a = 90 %', () {
    expect((parseClickFrame(bytesOf('19 10 5a')) as BatteryFrame).percent, 90);
  });

  test('device info frame gives firmware 1.2.0', () {
    final f = parseClickFrame(bytesOf(
        '3c 08 00 12 46 0a 44 08 83 04 12 04 00 00 02 01 1a 0b 5a 77 69 66 74 '
        '20 43 6c 69 63 6b 32 0f 30 41 2d 44 34 30 36 30 46 39 31 39 46 39 33 '
        '3a 03 42 2e 30 42 04 08 02 10 01 48 01 50 0a 5a 0c 44 34 30 36 30 46 '
        '39 31 39 46 39 33'));
    expect((f as DeviceInfoFrame).firmware, '1.2.0');
    expect((parseClickFrame(bytesOf('3c 08 10')) as DeviceInfoFrame).firmware, isNull);
  });

  test('ff 05 00 status frames are unknown, not challenges', () {
    expect(parseClickFrame(bytesOf('ff 05 00 fa 05 18 0a')), isA<UnknownFrame>());
  });

  test('truncated battery/info frames never throw', () {
    for (final f in ['19', '19 10', '19 10 ff', '3c', '3c 08 00 12 46 0a']) {
      expect(() => parseClickFrame(bytesOf(f)), returnsNormally);
    }
  });

  test('huge or negative lengths never throw (review)', () {
    final ff9 = List.filled(9, 'ff').join(' ');
    for (final f in ['3c 12 $ff9 01 00', '19 12 $ff9 01', '19 10 $ff9 01']) {
      expect(() => parseClickFrame(bytesOf(f)), returnsNormally, reason: f);
      expect(parseClickFrame(bytesOf(f)), isNot(isA<BatteryFrame>()), reason: f);
    }
  });
}
