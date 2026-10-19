import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/game_action.dart';
import 'package:shiftpad/output/keyboard/key_injector.dart';
import 'package:shiftpad/output/keyboard/keyboard_output.dart';

class FakeInjector implements KeyInjector {
  final calls = <String>[];
  bool running = true;

  @override
  Future<bool> isTargetRunning() async => running;

  @override
  Future<bool> keyDown(int virtualKey) async {
    calls.add('down ${String.fromCharCode(virtualKey)}');
    return true;
  }

  @override
  Future<bool> keyUp(int virtualKey) async {
    calls.add('up ${String.fromCharCode(virtualKey)}');
    return true;
  }
}

void main() {
  test('shiftUp press/release -> keyDown(K) then keyUp(K)', () async {
    final inj = FakeInjector();
    final out = KeyboardOutput(injector: inj);
    await out.send(GameAction.shiftUp, pressed: true);
    await out.send(GameAction.shiftUp, pressed: false);
    expect(inj.calls, ['down K', 'up K']);
  });

  test('steerLeft is held: keyDown on press, keyUp only on release', () async {
    final inj = FakeInjector();
    final out = KeyboardOutput(injector: inj);
    await out.send(GameAction.steerLeft, pressed: true);
    expect(inj.calls, ['down A']);
    await out.send(GameAction.steerLeft, pressed: false);
    expect(inj.calls, ['down A', 'up A']);
  });

  test('none action sends nothing', () async {
    final inj = FakeInjector();
    await KeyboardOutput(injector: inj).send(GameAction.none, pressed: true);
    expect(inj.calls, isEmpty);
  });

  test('available follows isTargetRunning polled every 2 s', () => fakeAsync((fa) {
        final inj = FakeInjector();
        final out = KeyboardOutput(injector: inj)..start();
        fa.flushMicrotasks();
        expect(out.available.value, isTrue);
        inj.running = false;
        fa.elapse(const Duration(milliseconds: 1900));
        expect(out.available.value, isTrue);
        fa.elapse(const Duration(milliseconds: 200));
        expect(out.available.value, isFalse);
        out.stop();
      }));

  test('custom key map overrides default', () async {
    final inj = FakeInjector();
    final out = KeyboardOutput(injector: inj, keys: {GameAction.shiftUp: 0x49});
    await out.send(GameAction.shiftUp, pressed: true);
    await out.send(GameAction.shiftDown, pressed: true);
    expect(inj.calls, ['down I', 'down I']);
  });

  test('unsupported injector is never available', () async {
    final out = KeyboardOutput(injector: const UnsupportedKeyInjector());
    await out.start();
    expect(out.available.value, isFalse);
    await out.stop();
  });
}
