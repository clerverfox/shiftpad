import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/game_action.dart';
import 'package:shiftpad/output/game_output.dart';
import 'package:shiftpad/output/output_router.dart';

class FakeOutput implements GameOutput {
  FakeOutput({bool available = false, this.unsupported = const {}})
      : availableNotifier = ValueNotifier(available);

  final ValueNotifier<bool> availableNotifier;
  final Set<GameAction> unsupported;
  final sent = <(GameAction, bool)>[];

  @override
  ValueListenable<bool> get available => availableNotifier;

  @override
  bool supports(GameAction action) => !unsupported.contains(action);

  @override
  Future<void> send(GameAction action, {required bool pressed}) async =>
      sent.add((action, pressed));

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  test('prefers OBC when available, else keyboard, else none', () async {
    final obc = FakeOutput(available: true);
    final kb = FakeOutput(available: true);
    final r = OutputRouter(obc: obc, keyboard: kb);
    expect(r.route.value, OutputRoute.openBikeControl);
    expect(await r.send(GameAction.shiftUp, pressed: true), OutputRoute.openBikeControl);

    obc.availableNotifier.value = false;
    expect(r.route.value, OutputRoute.keyboard);
    kb.availableNotifier.value = false;
    expect(r.route.value, OutputRoute.none);
    expect(await r.send(GameAction.shiftDown, pressed: true), OutputRoute.none);
    expect(kb.sent, isEmpty);
  });

  test('OBC drop mid-ride: next send goes to keyboard', () async {
    final obc = FakeOutput(available: true);
    final kb = FakeOutput(available: true);
    final r = OutputRouter(obc: obc, keyboard: kb);
    await r.send(GameAction.shiftUp, pressed: true);
    await r.send(GameAction.shiftUp, pressed: false);
    obc.availableNotifier.value = false;
    await r.send(GameAction.shiftUp, pressed: true);
    expect(obc.sent, [(GameAction.shiftUp, true), (GameAction.shiftUp, false)]);
    expect(kb.sent, [(GameAction.shiftUp, true)]);

    obc.availableNotifier.value = true; // MyWhoosh reconnects
    await r.send(GameAction.shiftDown, pressed: true);
    expect(obc.sent.last, (GameAction.shiftDown, true));
  });

  test('a press routed to OBC gets its release on OBC even if route changed in between',
      () async {
    final obc = FakeOutput(available: true);
    final kb = FakeOutput(available: true);
    final r = OutputRouter(obc: obc, keyboard: kb);
    await r.send(GameAction.steerLeft, pressed: true);
    obc.availableNotifier.value = false;
    await r.send(GameAction.steerLeft, pressed: false);
    expect(obc.sent, [(GameAction.steerLeft, true), (GameAction.steerLeft, false)]);
    expect(kb.sent, isEmpty);
  });

  test('action OBC cannot express goes to the keyboard', () async {
    final obc = FakeOutput(available: true, unsupported: {GameAction.emote2});
    final kb = FakeOutput(available: true);
    final r = OutputRouter(obc: obc, keyboard: kb);
    expect(await r.send(GameAction.emote2, pressed: true), OutputRoute.keyboard);
    expect(kb.sent, [(GameAction.emote2, true)]);
  });

  test('none action is never sent', () async {
    final obc = FakeOutput(available: true);
    final r = OutputRouter(obc: obc, keyboard: FakeOutput());
    expect(await r.send(GameAction.none, pressed: true), OutputRoute.none);
    expect(obc.sent, isEmpty);
  });
}
