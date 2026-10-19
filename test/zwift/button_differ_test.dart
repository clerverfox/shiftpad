import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/zwift/button_differ.dart';

void main() {
  final t = DateTime(2026);

  test('press then release', () {
    final d = ButtonDiffer();
    expect(d.update({ClickButton.plus}, t), [ButtonEvent(ClickButton.plus, true, t)]);
    expect(d.update({}, t), [ButtonEvent(ClickButton.plus, false, t)]);
  });
  test('duplicate frames produce nothing', () {
    final d = ButtonDiffer()..update({ClickButton.plus}, t);
    expect(d.update({ClickButton.plus}, t), isEmpty);
  });
  test('ten rapid presses give ten press events in order', () {
    final d = ButtonDiffer();
    final presses = <ButtonEvent>[];
    for (var i = 0; i < 10; i++) {
      presses.addAll(d.update({ClickButton.plus}, t).where((e) => e.pressed));
      d.update({}, t);
    }
    expect(presses.length, 10);
  });
  test('two buttons at once give two events', () {
    expect(ButtonDiffer().update({ClickButton.a, ClickButton.plus}, t).length, 2);
  });
  test('releases come before presses', () {
    final d = ButtonDiffer()..update({ClickButton.plus}, t);
    expect(d.update({ClickButton.b}, t), [
      ButtonEvent(ClickButton.plus, false, t),
      ButtonEvent(ClickButton.b, true, t),
    ]);
  });
  test('reset forgets held buttons', () {
    final d = ButtonDiffer()..update({ClickButton.plus}, t);
    d.reset();
    expect(d.update({ClickButton.plus}, t), [ButtonEvent(ClickButton.plus, true, t)]);
  });
}
