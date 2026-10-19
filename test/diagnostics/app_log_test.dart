import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/diagnostics/app_log.dart';

void main() {
  test('ring buffer keeps only the last capacity lines', () {
    final log = AppLog(capacity: 3);
    for (var i = 0; i < 5; i++) {
      log.info('t', 'line $i');
    }
    expect(log.lines.map((l) => l.text), ['line 2', 'line 3', 'line 4']);
  });

  test('raw text is lowercase hex with spaces', () {
    final log = AppLog();
    log.raw(ClickSide.right, Uint8List.fromList([0x23, 0x08, 0xFF]));
    expect(log.lines.single.text, '23 08 ff');
    expect(log.lines.single.tag, 'rx-right');
  });

  test('stream emits new lines', () async {
    final log = AppLog();
    final next = log.stream.first;
    log.info('ble', 'hello');
    expect((await next).text, 'hello');
  });

  test('export writes every line with ISO timestamp first', () async {
    final tmp = await Directory.systemTemp.createTemp('shiftpad_log');
    addTearDown(() => tmp.delete(recursive: true));
    final t = DateTime(2026, 10, 19, 7, 5, 9);
    final log = AppLog(documentsDir: () async => tmp, now: () => t);
    log.info('app', 'start');
    log.info('ble', 'found');

    final file = await log.export();

    expect(file.path.replaceAll('\\', '/'),
        '${tmp.path.replaceAll('\\', '/')}/ShiftPad/shiftpad-logs-20261019-070509.txt');
    final lines = await file.readAsLines();
    expect(lines, [
      '${t.toIso8601String()} [app] start',
      '${t.toIso8601String()} [ble] found',
    ]);
  });
}
