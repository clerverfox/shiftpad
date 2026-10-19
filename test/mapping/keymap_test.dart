import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/core/game_action.dart';
import 'package:shiftpad/mapping/keymap.dart';

void main() {
  test('rightOnly defaults: + up, B down', () {
    final k = Keymap.defaults(ControlMode.rightOnly);
    expect(k.actionFor(ClickButton.plus), GameAction.shiftUp);
    expect(k.actionFor(ClickButton.b), GameAction.shiftDown);
    expect(k.actionFor(ClickButton.minus), GameAction.none);
  });

  test('bothPods defaults: + up, − down, arrows steer', () {
    final k = Keymap.defaults(ControlMode.bothPods);
    expect(k.actionFor(ClickButton.plus), GameAction.shiftUp);
    expect(k.actionFor(ClickButton.minus), GameAction.shiftDown);
    expect(k.actionFor(ClickButton.left), GameAction.steerLeft);
    expect(k.actionFor(ClickButton.right), GameAction.steerRight);
    expect(k.actionFor(ClickButton.z), GameAction.none);
  });

  test('keymap json round-trip', () {
    final k = Keymap.defaults(ControlMode.bothPods)
        .rebind(ClickButton.z, GameAction.toggleUi);
    expect(Keymap.fromJson(k.toJson()), k);
  });

  test('fromJson ignores unknown buttons and actions', () {
    final k = Keymap.fromJson({'plus': 'shiftUp', 'turbo': 'shiftUp', 'b': 'fly'});
    expect(k.actionFor(ClickButton.plus), GameAction.shiftUp);
    expect(k.actionFor(ClickButton.b), GameAction.none);
  });
}
