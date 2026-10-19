import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/game_action.dart';
import 'package:shiftpad/diagnostics/app_log.dart';
import 'package:shiftpad/output/obc/mdns_advertiser.dart';
import 'package:shiftpad/output/obc/obc_output.dart';

class FakeAdvertiser implements MdnsAdvertiser {
  final registered = <Map<String, Object>>[];
  int unregisters = 0;

  @override
  Future<void> register({
    required String instanceName,
    required String serviceType,
    required int port,
    required Map<String, String> txt,
  }) async =>
      registered.add({'name': instanceName, 'type': serviceType, 'port': port, 'txt': txt});

  @override
  Future<void> unregister() async => unregisters++;
}

/// Reads bytes from a socket into a list the test can await on.
class Received {
  Received(Socket s) {
    s.listen(bytes.addAll, onDone: () => closed = true);
  }
  final bytes = <int>[];
  bool closed = false;

  Future<void> waitFor(bool Function() ok) async {
    for (var i = 0; i < 100 && !ok(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }
}

Future<void> until(bool Function() ok) async {
  for (var i = 0; i < 100 && !ok(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late FakeAdvertiser adv;
  late ObcOutput out;

  setUp(() async {
    adv = FakeAdvertiser();
    out = ObcOutput(
        advertiser: adv,
        log: AppLog(),
        instanceName: 'ShiftPad-test',
        bindAddress: InternetAddress.loopbackIPv4,
        port: 0);
    await out.start();
  });
  tearDown(() => out.stop());

  Future<Socket> connect() => Socket.connect(InternetAddress.loopbackIPv4, out.port!);

  test('registers mDNS with bound port and TXT from protocol spec', () async {
    final r = adv.registered.single;
    expect(r['name'], 'ShiftPad-test');
    expect(r['type'], '_openbikecontrol._tcp');
    expect(r['port'], out.port);
    expect(r['port'], isNot(0));
    expect((r['txt'] as Map).keys,
        containsAll(['version', 'id', 'name', 'service-uuids', 'manufacturer', 'model']));
    expect((r['txt'] as Map)['version'], '1');
  });

  test('client connect -> available; send writes bytes; client close -> unavailable',
      () async {
    expect(out.available.value, isFalse);
    final c = await connect();
    final rx = Received(c);
    await until(() => out.available.value);
    expect(out.available.value, isTrue);

    await rx.waitFor(() => rx.bytes.length >= 3);
    expect(rx.bytes.take(3), [0x02, 0xFF, 0x01]); // status on connect

    await out.send(GameAction.shiftUp, pressed: true);
    await out.send(GameAction.shiftUp, pressed: false);
    await rx.waitFor(() => rx.bytes.length >= 9);
    expect(rx.bytes.skip(3), [0x01, 0x01, 0x01, 0x01, 0x01, 0x00]);

    await c.close();
    await until(() => !out.available.value);
    expect(out.available.value, isFalse);
  });

  test('app info message (0x04) from client is logged and exposed as connectedAppName',
      () async {
    final c = await connect();
    c.add([0x04, 0x01, 8, ...utf8.encode('mywhoosh'), 3, ...utf8.encode('6.2'), 0]);
    await until(() => out.connectedAppName.value != null);
    expect(out.connectedAppName.value, 'mywhoosh');
    c.destroy();
    await until(() => out.connectedAppName.value == null);
    expect(out.connectedAppName.value, isNull);
  });

  test('actions the app did not list are not supported', () async {
    final c = await connect();
    expect(out.supports(GameAction.toggleUi), isTrue); // no app info yet
    c.add([0x04, 0x01, 8, ...utf8.encode('mywhoosh'), 5, ...utf8.encode('5.7.0'),
        3, 0x01, 0x02, 0x18]);
    await until(() => out.connectedAppName.value != null);
    expect(out.supports(GameAction.shiftUp), isTrue);
    expect(out.supports(GameAction.steerLeft), isTrue);
    expect(out.supports(GameAction.toggleUi), isFalse);
    c.destroy();
  });

  test('falls back to a free port when the fixed one is taken', () async {
    final blocker = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final other = ObcOutput(
        advertiser: FakeAdvertiser(),
        log: AppLog(),
        bindAddress: InternetAddress.loopbackIPv4,
        port: blocker.port);
    await other.start();
    expect(other.port, isNot(blocker.port));
    await other.stop();
    await blocker.close();
  });

  test('second client replaces first', () async {
    final first = await connect();
    final rx1 = Received(first);
    await until(() => out.available.value);
    final second = await connect();
    final rx2 = Received(second);
    await rx1.waitFor(() => rx1.closed);
    expect(rx1.closed, isTrue);
    expect(out.available.value, isTrue);

    await rx2.waitFor(() => rx2.bytes.length >= 3);
    await out.send(GameAction.shiftDown, pressed: true);
    await rx2.waitFor(() => rx2.bytes.length >= 6);
    expect(rx2.bytes.skip(3), [0x01, 0x02, 0x01]);
    second.destroy();
  });

  test('stop unregisters mDNS and closes the client', () async {
    final c = await connect();
    final rx = Received(c);
    await until(() => out.available.value);
    await out.stop();
    await rx.waitFor(() => rx.closed);
    expect(rx.closed, isTrue);
    expect(adv.unregisters, 1);
    expect(out.available.value, isFalse);
  });
}
