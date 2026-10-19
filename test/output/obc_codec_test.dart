import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/game_action.dart';
import 'package:shiftpad/output/obc/obc_codec.dart';

List<int> appInfo(String id, String version, List<int> buttons) => [
      0x04, 0x01,
      id.length, ...utf8.encode(id),
      version.length, ...utf8.encode(version),
      buttons.length, ...buttons,
    ];

void main() {
  test('shift up press', () {
    expect(encodeObcButton(obcButtonId(GameAction.shiftUp)!, true), [0x01, 0x01, 0x01]);
  });
  test('shift down release', () {
    expect(encodeObcButton(obcButtonId(GameAction.shiftDown)!, false), [0x01, 0x02, 0x00]);
  });
  test('protocol ids for steering and HUD; none is unmapped', () {
    expect(obcButtonId(GameAction.steerLeft), 0x18);
    expect(obcButtonId(GameAction.steerRight), 0x19);
    expect(obcButtonId(GameAction.toggleUi), 0x44);
    expect(obcButtonId(GameAction.none), isNull);
  });
  test('status message', () => expect(encodeObcStatus(), [0x02, 0xFF, 0x01]));

  group('app message reader', () {
    test('parses app info from the protocol example', () {
      final r = ObcAppMessageReader();
      final infos = r.add(appInfo('zwift', '1.52.0', [0x01, 0x02, 0x10, 0x14]));
      expect(infos.single.appId, 'zwift');
      expect(infos.single.appVersion, '1.52.0');
      expect(infos.single.buttonIds, [0x01, 0x02, 0x10, 0x14]);
    });
    test('handles a message split across chunks', () {
      final r = ObcAppMessageReader();
      final bytes = appInfo('mywhoosh', '6.2.3', []);
      expect(r.add(bytes.sublist(0, 5)), isEmpty);
      expect(r.add(bytes.sublist(5)).single.appId, 'mywhoosh');
    });
    test('skips haptic messages, then reads app info', () {
      final r = ObcAppMessageReader();
      final infos = r.add([0x03, 0x01, 0x00, 0x00, ...appInfo('a', '1', [])]);
      expect(infos.single.appId, 'a');
    });
    test('garbage is dropped without throwing', () {
      final r = ObcAppMessageReader();
      expect(r.add([0x99, 1, 2, 3]), isEmpty);
      expect(r.add(appInfo('b', '2', [])).single.appId, 'b');
    });
  });
}
