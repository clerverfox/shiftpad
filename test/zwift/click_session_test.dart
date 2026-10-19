import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/core/hex.dart';
import 'package:shiftpad/zwift/click_constants.dart';
import 'package:shiftpad/zwift/click_session.dart';

import '../support/fake_ble_link.dart';
import '../support/varint.dart';

void main() {
  const rideOnEcho = [0x52, 0x69, 0x64, 0x65, 0x4F, 0x6E, 0x02, 0x03];

  ClickSession startSession(FakeAsync fa, FakeBleLink link,
      {ClickSide side = ClickSide.right, bool idleReboot = true}) {
    final s = ClickSession(link: link, side: side, idleRebootEnabled: idleReboot)..start();
    fa.elapse(const Duration(milliseconds: 300));
    return s;
  }

  test('handshake writes RideOn+0203, then 000800 and 000810 ~100ms apart', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        ClickSession(link: link, side: ClickSide.right).start();
        fa.flushMicrotasks();
        expect(link.writes.map(hex), ['526964654f6e0203']);
        fa.elapse(const Duration(milliseconds: 100));
        expect(link.writes.length, 2);
        fa.elapse(const Duration(milliseconds: 200));
        expect(link.writes.take(3).map(hex), ['526964654f6e0203', '000800', '000810']);
        expect(link.writeCalls.every((w) => w.char == kSyncRxChar), isTrue);
      }));

  test('subscribes Async (notify) and SyncTx (indicate)', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        startSession(fa, link);
        expect(link.subscriptions, [
          (kClickService, kAsyncChar, false),
          (kClickService, kSyncTxChar, true),
        ]);
      }));

  test('RideOn echo -> ready + unlocked, and sends FF0400', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link);
        expect(s.status.value.link, LinkState.handshaking);
        link.push(kSyncTxChar, rideOnEcho);
        fa.flushMicrotasks();
        expect(s.status.value.link, LinkState.ready);
        expect(s.status.value.lock, LockState.unlocked);
        expect(link.writes.map(hex), contains('ff0400'));
      }));

  test('challenge FF0300 -> locked', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link, side: ClickSide.left);
        link.push(kSyncTxChar, [0xFF, 0x03, 0x00, 0x12, 0x34]);
        fa.flushMicrotasks();
        expect(s.status.value.lock, LockState.locked);
        expect(s.status.value.usable, isFalse);
      }));

  test('buttons frame on Async emits ButtonEvent', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link);
        final events = <ButtonEvent>[];
        s.events.listen(events.add);
        link.push(kAsyncChar, pressedFrame(0x1000));
        link.push(kAsyncChar, pressedFrame(0x1000)); // duplicate
        link.push(kAsyncChar, pressedFrame(0));
        fa.flushMicrotasks();
        expect(events.map((e) => (e.button, e.pressed)),
            [(ClickButton.plus, true), (ClickButton.plus, false)]);
        expect(s.status.value.lastFrameAt, isNotNull);
      }));

  test('raw frames are reported as hex', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final raw = <String>[];
        ClickSession(link: link, side: ClickSide.right, onRawFrame: (b) => raw.add(hex(b))).start();
        fa.elapse(const Duration(milliseconds: 300));
        link.push(kAsyncChar, [0x23, 0x08, 0x01]);
        expect(raw, ['230801']);
      }));

  test('keep-alive RideOn every 3 s while ready', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        startSession(fa, link);
        link.push(kSyncTxChar, rideOnEcho);
        final before = link.writes.where((w) => hex(w).startsWith('526964654f6e')).length;
        fa.elapse(const Duration(seconds: 9));
        final after = link.writes.where((w) => hex(w).startsWith('526964654f6e')).length;
        expect(after - before, greaterThanOrEqualTo(3));
      }));

  test('idle reboot writes 0x18 after 55 s without frames', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        startSession(fa, link);
        link.push(kSyncTxChar, rideOnEcho);
        fa.elapse(const Duration(seconds: 54));
        expect(link.writes.map(hex), isNot(contains('18')));
        link.push(kAsyncChar, pressedFrame(0)); // a frame resets the timer
        fa.elapse(const Duration(seconds: 54));
        expect(link.writes.map(hex), isNot(contains('18')));
        fa.elapse(const Duration(seconds: 2));
        expect(link.writes.map(hex), contains('18'));
      }));

  test('keep-alive echoes do not hold off the idle reboot (checkpoint B)', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        ClickSession(link: link, side: ClickSide.right).start();
        fa.elapse(const Duration(milliseconds: 300));
        for (var i = 0; i < 20; i++) {
          link.push(kSyncTxChar, [0x52, 0x69, 0x64, 0x65, 0x4F, 0x6E]);
          fa.elapse(const Duration(seconds: 3));
        }
        expect(link.writes.map(hex), contains('18'));
      }));

  test('idle reboot waits while its condition is false', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        var alone = false;
        ClickSession(link: link, side: ClickSide.right, idleRebootWhen: () => alone).start();
        fa.elapse(const Duration(milliseconds: 300));
        link.push(kSyncTxChar, rideOnEcho);
        fa.elapse(const Duration(seconds: 120));
        expect(link.writes.map(hex), isNot(contains('18')));
        alone = true;
        fa.elapse(const Duration(seconds: 56));
        expect(link.writes.map(hex), contains('18'));
      }));

  test('idle reboot can be disabled', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        ClickSession(link: link, side: ClickSide.right, idleRebootEnabled: false).start();
        fa.elapse(const Duration(seconds: 120));
        expect(link.writes.map(hex), isNot(contains('18')));
      }));

  test('connect failure after the pod answered once -> disconnected, not busy',
      () => fakeAsync((fa) {
            final link = FakeBleLink(services: [kClickService]);
            final s = startSession(fa, link);
            link.push(kSyncTxChar, rideOnEcho);
            link.dropConnection();
            link.connectError = Exception('Unreachable');
            s.start();
            fa.flushMicrotasks();
            expect(s.status.value.link, LinkState.disconnected);
            expect(s.status.value.error, contains('Unreachable'));
          }));

  test('connect throws -> busyElsewhere with error text, no throw', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService], connectError: Exception('in use'));
        final s = ClickSession(link: link, side: ClickSide.right);
        Object? thrown;
        s.start().catchError((Object e) => thrown = e);
        fa.flushMicrotasks();
        expect(thrown, isNull);
        expect(s.status.value.link, LinkState.busyElsewhere);
        expect(s.status.value.error, contains('in use'));
      }));

  test('uses alt service FC82 when main service absent', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickServiceAlt]);
        startSession(fa, link);
        expect(link.subscriptions.first.$1, kClickServiceAlt);
        expect(link.writeCalls.first.service, kClickServiceAlt);
      }));

  test('no Click service -> error, disconnects', () => fakeAsync((fa) {
        final link = FakeBleLink(services: ['0000180f-0000-1000-8000-00805f9b34fb']);
        final s = startSession(fa, link);
        expect(s.status.value.link, LinkState.error);
        expect(link.disconnectCount, 1);
      }));

  test('connection lost -> disconnected, held button released, timers stop', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link, side: ClickSide.left);
        link.push(kSyncTxChar, rideOnEcho);
        final events = <ButtonEvent>[];
        s.events.listen(events.add);
        link.push(kAsyncChar, pressedFrame(0x1)); // hold steer left
        link.dropConnection();
        expect(s.status.value.link, LinkState.disconnected);
        expect(events.last.pressed, isFalse);
        final writes = link.writes.length;
        fa.elapse(const Duration(seconds: 60));
        expect(link.writes.length, writes);
      }));

  test('can start again after a disconnect', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link);
        link.dropConnection();
        s.start();
        fa.elapse(const Duration(milliseconds: 300));
        expect(link.connectCount, 2);
        expect(s.status.value.link, LinkState.handshaking);
      }));

  test('reads battery and firmware when exposed', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [
          kClickService,
          kBatteryService,
          kDeviceInfoService,
        ], readValues: {
          kBatteryLevelChar: Uint8List.fromList([87]),
          kFirmwareRevisionChar: Uint8List.fromList(utf8.encode('1.2.0')),
        });
        final s = startSession(fa, link);
        expect(s.status.value.batteryPercent, 87);
        expect(s.status.value.firmware, '1.2.0');
      }));

  test('left pod relays right buttons: each session keeps only its own side',
      () => fakeAsync((fa) {
            final link = FakeBleLink(services: [kClickService]);
            final s = startSession(fa, link, side: ClickSide.left);
            final events = <ButtonEvent>[];
            s.events.listen(events.add);
            link.push(kAsyncChar, pressedFrame(0x10)); // A, relayed from right
            link.push(kAsyncChar, pressedFrame(0));
            link.push(kAsyncChar, pressedFrame(0x100)); // minus, own
            expect(events.map((e) => (e.button, e.pressed)), [(ClickButton.minus, true)]);
          }));

  test('keep-alive echo after a challenge does not clear locked', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link, side: ClickSide.left);
        link.push(kSyncTxChar, rideOnEcho);
        link.push(kSyncTxChar, [0xFF, 0x03, 0x00, 0x0a]);
        link.push(kSyncTxChar, [0x52, 0x69, 0x64, 0x65, 0x4F, 0x6E]);
        expect(s.status.value.lock, LockState.locked);
      }));

  test('own button press after a challenge proves the pod works', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link, side: ClickSide.left);
        final events = <ButtonEvent>[];
        s.events.listen(events.add);
        link.push(kSyncTxChar, [0xFF, 0x03, 0x00, 0x0a]);
        link.push(kAsyncChar, pressedFrame(0x100));
        expect(events.single.button, ClickButton.minus);
        expect(s.status.value.lock, LockState.unlocked);
      }));

  test('battery and firmware from pod frames', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link);
        link.push(kAsyncChar, [0x19, 0x10, 0x5a]);
        expect(s.status.value.batteryPercent, 90);
      }));

  test('silent pod after handshake -> busyElsewhere, disconnected (review)', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link);
        fa.elapse(const Duration(seconds: 6));
        expect(s.status.value.link, LinkState.busyElsewhere);
        expect(link.disconnectCount, 1);
      }));

  test('frames after a disconnect are ignored (review)', () => fakeAsync((fa) {
        final link = FakeBleLink(services: [kClickService]);
        final s = startSession(fa, link);
        link.push(kSyncTxChar, rideOnEcho);
        link.dropConnection();
        link.push(kSyncTxChar, rideOnEcho);
        expect(s.status.value.link, LinkState.disconnected);
      }));
}
