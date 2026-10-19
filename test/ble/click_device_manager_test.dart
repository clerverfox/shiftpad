import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/ble/click_device_manager.dart';
import 'package:shiftpad/ble/click_scanner.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/zwift/click_constants.dart';
import 'package:shiftpad/zwift/click_session.dart';

import '../support/fake_ble_link.dart';
import '../support/varint.dart';

void main() {
  late StreamController<DiscoveredClick> scan;
  late Map<String, FakeBleLink> links;
  late int scanListens;

  ClickDeviceManager makeManager() {
    scan = StreamController<DiscoveredClick>.broadcast(
        onListen: () => scanListens++);
    links = {};
    scanListens = 0;
    return ClickDeviceManager(
      scan: () => scan.stream,
      linkFactory: (id) =>
          links[id] ??= FakeBleLink(deviceId: id, services: [kClickService]),
    );
  }

  DiscoveredClick found(String id, ClickSide side) =>
      DiscoveredClick(deviceId: id, side: side, name: 'Click');

  test('connects one session per side, ignores second device of same side',
      () => fakeAsync((fa) {
            final m = makeManager()..start();
            fa.flushMicrotasks();
            scan.add(found('r1', ClickSide.right));
            scan.add(found('r2', ClickSide.right));
            scan.add(found('l1', ClickSide.left));
            fa.elapse(const Duration(milliseconds: 300));
            expect(links.keys, ['r1', 'l1']);
            expect(links['r1']!.connectCount, 1);
            expect(m.statuses.value[ClickSide.right]!.link, LinkState.handshaking);
            expect(m.statuses.value[ClickSide.left]!.link, LinkState.handshaking);
          }));

  test('merges events from both sides', () => fakeAsync((fa) {
        final m = makeManager()..start();
        fa.flushMicrotasks();
        final events = <ButtonEvent>[];
        m.events.listen(events.add);
        scan.add(found('r1', ClickSide.right));
        scan.add(found('l1', ClickSide.left));
        fa.elapse(const Duration(milliseconds: 300));
        links['r1']!.push(kAsyncChar, pressedFrame(0x1000));
        links['l1']!.push(kAsyncChar, pressedFrame(0x100));
        expect(events.map((e) => e.button), [ClickButton.plus, ClickButton.minus]);
      }));

  test('reconnects after disconnect with backoff 1s, 2s, 5s, 5s', () => fakeAsync((fa) {
        makeManager().start();
        fa.flushMicrotasks();
        scan.add(found('r1', ClickSide.right));
        fa.elapse(const Duration(milliseconds: 300));
        final link = links['r1']!;
        expect(link.connectCount, 1);

        for (final (wait, expected) in [(1, 2), (2, 3), (5, 4), (5, 5)]) {
          link.dropConnection();
          fa.elapse(Duration(seconds: wait) - const Duration(milliseconds: 10));
          expect(link.connectCount, expected - 1, reason: 'too early ($wait s)');
          fa.elapse(const Duration(milliseconds: 20));
          expect(link.connectCount, expected, reason: 'after $wait s');
        }
      }));

  test('backoff resets once the pod is ready', () => fakeAsync((fa) {
        makeManager().start();
        fa.flushMicrotasks();
        scan.add(found('r1', ClickSide.right));
        fa.elapse(const Duration(milliseconds: 300));
        final link = links['r1']!;
        link.dropConnection();
        fa.elapse(const Duration(seconds: 1, milliseconds: 300));
        link.push(kSyncTxChar, [0x52, 0x69, 0x64, 0x65, 0x4F, 0x6E]);
        link.dropConnection();
        fa.elapse(const Duration(milliseconds: 1010));
        expect(link.connectCount, 3);
      }));

  test('busyElsewhere side is retried every 5 s', () => fakeAsync((fa) {
        final m = makeManager()..start();
        fa.flushMicrotasks();
        links['r1'] = FakeBleLink(
            deviceId: 'r1', services: [kClickService], connectError: Exception('busy'));
        scan.add(found('r1', ClickSide.right));
        fa.flushMicrotasks();
        expect(m.statuses.value[ClickSide.right]!.link, LinkState.busyElsewhere);
        fa.elapse(const Duration(seconds: 15, milliseconds: 10));
        expect(links['r1']!.connectCount, 4);
        links['r1']!.connectError = null;
        fa.elapse(const Duration(seconds: 5, milliseconds: 300));
        expect(m.statuses.value[ClickSide.right]!.link, LinkState.handshaking);
      }));

  test('stops scanning once both sides are found', () => fakeAsync((fa) {
        makeManager().start();
        fa.flushMicrotasks();
        expect(scan.hasListener, isTrue);
        scan.add(found('r1', ClickSide.right));
        scan.add(found('l1', ClickSide.left));
        fa.flushMicrotasks();
        expect(scan.hasListener, isFalse);
        expect(scanListens, 1);
      }));

  test('stop disconnects sessions', () => fakeAsync((fa) {
        final m = makeManager()..start();
        fa.flushMicrotasks();
        scan.add(found('r1', ClickSide.right));
        fa.elapse(const Duration(milliseconds: 300));
        m.stop();
        fa.elapse(const Duration(seconds: 10));
        expect(links['r1']!.disconnectCount, 1);
        expect(links['r1']!.connectCount, 1);
      }));

  test('right-only: scanning stops once the right pod is found', () => fakeAsync((fa) {
        final m = makeManager()..wantedSides = {ClickSide.right};
        m.start();
        fa.flushMicrotasks();
        expect(scan.hasListener, isTrue);
        scan.add(found('r1', ClickSide.right));
        fa.flushMicrotasks();
        expect(scan.hasListener, isFalse);

        m.wantedSides = ClickSide.values.toSet(); // switched to both pods
        fa.flushMicrotasks();
        expect(scan.hasListener, isTrue);
        m.stop();
      }));
}
