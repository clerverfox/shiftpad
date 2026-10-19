import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftpad/ble/click_device_manager.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/core/game_action.dart';
import 'package:shiftpad/diagnostics/app_log.dart';
import 'package:shiftpad/mapping/keymap.dart';
import 'package:shiftpad/mapping/settings_store.dart';
import 'package:shiftpad/output/output_router.dart';
import 'package:shiftpad/shiftpad_controller.dart';
import 'package:shiftpad/zwift/click_session.dart';

import 'support/fake_output.dart';

class FakeDevices implements ClickDeviceManager {
  final controller = StreamController<ButtonEvent>.broadcast(sync: true);
  final statusNotifier = ValueNotifier<Map<ClickSide, ClickStatus>>({
    ClickSide.left: const ClickStatus(
        side: ClickSide.left, link: LinkState.ready, lock: LockState.unlocked),
    ClickSide.right: const ClickStatus(
        side: ClickSide.right, link: LinkState.ready, lock: LockState.unlocked),
  });

  void setLeft(ClickStatus s) =>
      statusNotifier.value = {...statusNotifier.value, ClickSide.left: s};

  @override
  Stream<ButtonEvent> get events => controller.stream;

  @override
  ValueListenable<Map<ClickSide, ClickStatus>> get statuses => statusNotifier;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}

  @override
  set wantedSides(Set<ClickSide> sides) {}
}

void main() {
  late FakeDevices devices;
  late FakeOutput obc;
  late AppLog log;
  late ShiftPadController c;
  final t0 = DateTime(2026, 10, 19, 12);

  Future<void> setUpController({ControlMode mode = ControlMode.bothPods}) async {
    SharedPreferences.setMockInitialValues({'mode': mode.name});
    devices = FakeDevices();
    obc = FakeOutput(available: true);
    log = AppLog();
    c = ShiftPadController(
      devices: devices,
      router: OutputRouter(obc: obc, keyboard: FakeOutput()),
      settings: SettingsStore(),
      log: log,
      now: () => t0.add(const Duration(milliseconds: 7)),
    );
    await c.start();
  }

  Future<void> press(ClickButton b, {bool release = true}) async {
    devices.controller.add(ButtonEvent(b, true, t0));
    if (release) devices.controller.add(ButtonEvent(b, false, t0));
    await pumpEventQueue();
  }

  test('bothPods: minus press sends shiftDown pressed:true then release pressed:false',
      () async {
    await setUpController();
    await press(ClickButton.minus);
    expect(obc.sent, [(GameAction.shiftDown, true), (GameAction.shiftDown, false)]);
  });

  test('10 rapid plus presses -> exactly 10 shiftUp presses sent in order', () async {
    await setUpController();
    for (var i = 0; i < 10; i++) {
      devices.controller.add(ButtonEvent(ClickButton.plus, true, t0));
      devices.controller.add(ButtonEvent(ClickButton.plus, false, t0));
    }
    await pumpEventQueue();
    expect(obc.sent.length, 20);
    for (var i = 0; i < 20; i++) {
      expect(obc.sent[i], (GameAction.shiftUp, i.isEven));
    }
  });

  test('both pods pressed at once give one shift each', () async {
    await setUpController();
    devices.controller.add(ButtonEvent(ClickButton.plus, true, t0));
    devices.controller.add(ButtonEvent(ClickButton.minus, true, t0));
    await pumpEventQueue();
    expect(obc.sent, [(GameAction.shiftUp, true), (GameAction.shiftDown, true)]);
  });

  test('left pod locked in bothPods -> fallbackToRightOnly true, B now shifts down',
      () async {
    await setUpController();
    expect(c.fallbackToRightOnly.value, isFalse);
    devices.setLeft(const ClickStatus(
        side: ClickSide.left, link: LinkState.ready, lock: LockState.locked));
    expect(c.fallbackToRightOnly.value, isTrue);
    await press(ClickButton.b);
    expect(obc.sent, [(GameAction.shiftDown, true), (GameAction.shiftDown, false)]);
  });

  test('left pod disconnected also triggers the fallback', () async {
    await setUpController();
    devices.setLeft(const ClickStatus(side: ClickSide.left, link: LinkState.disconnected));
    expect(c.fallbackToRightOnly.value, isTrue);
  });

  test('left presses that still arrive while flagged locked are used (checkpoint A)',
      () async {
    await setUpController();
    devices.setLeft(const ClickStatus(
        side: ClickSide.left, link: LinkState.ready, lock: LockState.locked));
    await press(ClickButton.minus);
    expect(obc.sent.first, (GameAction.shiftDown, true));
  });

  test('left pod unlocked again -> fallback cleared, B back to its bothPods action',
      () async {
    await setUpController();
    devices.setLeft(const ClickStatus(
        side: ClickSide.left, link: LinkState.ready, lock: LockState.locked));
    devices.setLeft(const ClickStatus(
        side: ClickSide.left, link: LinkState.ready, lock: LockState.unlocked));
    expect(c.fallbackToRightOnly.value, isFalse);
    await press(ClickButton.b);
    expect(obc.sent.first, (GameAction.emote3, true));
  });

  test('a release follows its press even if the fallback flips in between', () async {
    await setUpController();
    devices.setLeft(const ClickStatus(side: ClickSide.left, link: LinkState.disconnected));
    await press(ClickButton.b, release: false); // shiftDown in fallback
    devices.setLeft(const ClickStatus(
        side: ClickSide.left, link: LinkState.ready, lock: LockState.unlocked));
    devices.controller.add(ButtonEvent(ClickButton.b, false, t0));
    await pumpEventQueue();
    expect(obc.sent, [(GameAction.shiftDown, true), (GameAction.shiftDown, false)]);
  });

  test('rightOnly mode never falls back and ignores left buttons', () async {
    await setUpController(mode: ControlMode.rightOnly);
    devices.setLeft(const ClickStatus(side: ClickSide.left, link: LinkState.disconnected));
    expect(c.fallbackToRightOnly.value, isFalse);
    await press(ClickButton.minus);
    await press(ClickButton.b);
    expect(obc.sent, [(GameAction.shiftDown, true), (GameAction.shiftDown, false)]);
  });

  test('latency (send done - event.at) is logged per event', () async {
    await setUpController();
    await press(ClickButton.plus);
    expect(c.lastAction.value, (GameAction.shiftUp, const Duration(milliseconds: 7)));
    final lines = log.lines.where((l) => l.tag == 'action').map((l) => l.text);
    expect(lines, [
      'plus down -> shiftUp via openBikeControl 7 ms',
      'plus up -> shiftUp via openBikeControl 7 ms',
    ]);
  });
}
