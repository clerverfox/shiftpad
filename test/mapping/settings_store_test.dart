import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/core/game_action.dart';
import 'package:shiftpad/mapping/keymap.dart';
import 'package:shiftpad/mapping/settings_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults when nothing is saved', () async {
    final s = SettingsStore();
    expect(await s.mode(), ControlMode.bothPods);
    expect(await s.keymap(ControlMode.rightOnly), Keymap.defaults(ControlMode.rightOnly));
    expect(await s.keyboardKeys(), isEmpty);
    expect(await s.wizardDone(), isFalse);
  });

  test('settings persist mode and keymap', () async {
    final custom = Keymap.defaults(ControlMode.rightOnly)
        .rebind(ClickButton.y, GameAction.shiftDown);
    await SettingsStore().setMode(ControlMode.rightOnly);
    await SettingsStore().setKeymap(ControlMode.rightOnly, custom);
    await SettingsStore().setKeyboardKeys({GameAction.shiftUp: 0x49});
    await SettingsStore().setWizardDone(true);

    final s = SettingsStore(); // fresh instance, same storage
    expect(await s.mode(), ControlMode.rightOnly);
    expect(await s.keymap(ControlMode.rightOnly), custom);
    expect(await s.keymap(ControlMode.bothPods), Keymap.defaults(ControlMode.bothPods));
    expect(await s.keyboardKeys(), {GameAction.shiftUp: 0x49});
    expect(await s.wizardDone(), isTrue);
  });

  test('corrupt keymap falls back to defaults', () async {
    SharedPreferences.setMockInitialValues({'keymap.bothPods': 'not json'});
    expect(await SettingsStore().keymap(ControlMode.bothPods),
        Keymap.defaults(ControlMode.bothPods));
  });
}
