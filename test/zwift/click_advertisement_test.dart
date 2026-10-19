import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/zwift/click_advertisement.dart';

void main() {
  test('right pod', () {
    expect(sideFromManufacturerData(0x094A, Uint8List.fromList([0x0A, 1])),
        ClickSide.right);
  });
  test('left pod', () {
    expect(sideFromManufacturerData(0x094A, Uint8List.fromList([0x0B])),
        ClickSide.left);
  });
  test('other company or device', () {
    expect(sideFromManufacturerData(0x004C, Uint8List.fromList([0x0A])),
        isNull);
    expect(sideFromManufacturerData(0x094A, Uint8List.fromList([0x09])),
        isNull);
    expect(sideFromManufacturerData(0x094A, Uint8List(0)), isNull);
  });
}
