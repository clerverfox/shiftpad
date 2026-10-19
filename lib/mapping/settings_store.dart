import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_action.dart';
import 'keymap.dart';

/// User settings, persisted with shared_preferences.
class SettingsStore {
  SettingsStore({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  static const _modeKey = 'mode';
  static const _wizardKey = 'wizardDone';
  static const _keyboardKey = 'keyboardKeys';
  static String _keymapKey(ControlMode m) => 'keymap.${m.name}';

  Future<ControlMode> mode() async {
    final name = (await _prefs()).getString(_modeKey);
    return ControlMode.values.asNameMap()[name] ?? ControlMode.bothPods;
  }

  Future<void> setMode(ControlMode m) async =>
      (await _prefs()).setString(_modeKey, m.name);

  Future<Keymap> keymap(ControlMode m) async {
    final raw = (await _prefs()).getString(_keymapKey(m));
    if (raw == null) return Keymap.defaults(m);
    try {
      return Keymap.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Keymap.defaults(m);
    }
  }

  Future<void> setKeymap(ControlMode m, Keymap k) async =>
      (await _prefs()).setString(_keymapKey(m), jsonEncode(k.toJson()));

  /// Custom keyboard keys (Windows virtual-key codes); empty means defaults.
  Future<Map<GameAction, int>> keyboardKeys() async {
    final raw = (await _prefs()).getString(_keyboardKey);
    if (raw == null) return {};
    try {
      return {
        for (final MapEntry(:key, :value)
            in (jsonDecode(raw) as Map<String, dynamic>).entries)
          if (GameAction.values.asNameMap()[key] case final a?)
            if (value is int) a: value,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> setKeyboardKeys(Map<GameAction, int> keys) async =>
      (await _prefs()).setString(
          _keyboardKey, jsonEncode({for (final e in keys.entries) e.key.name: e.value}));

  Future<bool> wizardDone() async =>
      (await _prefs()).getBool(_wizardKey) ?? false;

  Future<void> setWizardDone(bool done) async =>
      (await _prefs()).setBool(_wizardKey, done);
}
