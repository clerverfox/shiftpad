import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/game_action.dart';
import '../game_output.dart';
import 'key_injector.dart';

/// Delivers actions as key presses in the game window.
class KeyboardOutput implements GameOutput {
  KeyboardOutput({
    required this._injector,
    Map<GameAction, int>? keys,
    this._pollEvery = const Duration(seconds: 2),
  }) : keys = {...defaultKeys, ...?keys};

  /// Windows virtual-key codes. Shift keys checked at checkpoint B.
  static const defaultKeys = <GameAction, int>{
    GameAction.shiftUp: 0x4B, // K
    GameAction.shiftDown: 0x49, // I
    GameAction.steerLeft: 0x41, // A
    GameAction.steerRight: 0x44, // D
    GameAction.toggleUi: 0x48, // H
    GameAction.emote1: 0x31, // 1
    GameAction.emote2: 0x32, // 2
    GameAction.emote3: 0x33, // 3
    GameAction.emote4: 0x34, // 4
  };

  final KeyInjector _injector;
  final Duration _pollEvery;
  Map<GameAction, int> keys;

  final _available = ValueNotifier(false);
  Timer? _poll;

  @override
  ValueListenable<bool> get available => _available;

  @override
  Future<void> start() async {
    _poll ??= Timer.periodic(_pollEvery, (_) => _check());
    await _check();
  }

  @override
  Future<void> stop() async {
    _poll?.cancel();
    _poll = null;
    _available.value = false;
  }

  Future<void> _check() async {
    try {
      _available.value = await _injector.isTargetRunning();
    } catch (_) {
      _available.value = false;
    }
  }

  @override
  bool supports(GameAction action) =>
      action != GameAction.none && keys.containsKey(action);

  @override
  Future<void> send(GameAction action, {required bool pressed}) async {
    final key = keys[action];
    if (action == GameAction.none || key == null) return;
    pressed ? await _injector.keyDown(key) : await _injector.keyUp(key);
  }
}
