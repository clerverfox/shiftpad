import 'package:flutter/foundation.dart';

import '../core/game_action.dart';
import 'game_output.dart';

enum OutputRoute { none, openBikeControl, keyboard }

/// Sends each action to OpenBikeControl when MyWhoosh is connected to it,
/// otherwise to the keyboard, otherwise nowhere.
class OutputRouter {
  OutputRouter({required this._obc, required this._keyboard}) {
    _obc.available.addListener(_update);
    _keyboard.available.addListener(_update);
    _update();
  }

  final GameOutput _obc;
  final GameOutput _keyboard;
  final _route = ValueNotifier(OutputRoute.none);

  /// Where each held action's press went, so its release goes there too.
  final _held = <GameAction, GameOutput>{};

  ValueListenable<OutputRoute> get route => _route;

  void _update() {
    _route.value = _obc.available.value
        ? OutputRoute.openBikeControl
        : _keyboard.available.value
            ? OutputRoute.keyboard
            : OutputRoute.none;
  }

  Future<void> start() async {
    await Future.wait([_obc.start(), _keyboard.start()]);
    _update();
  }

  Future<void> stop() async {
    await Future.wait([_obc.stop(), _keyboard.stop()]);
    _held.clear();
  }

  /// Returns the route the action went to.
  Future<OutputRoute> send(GameAction action, {required bool pressed}) async {
    if (action == GameAction.none) return OutputRoute.none;
    final GameOutput? target;
    if (pressed) {
      target = _pick(action);
      if (target == null) return OutputRoute.none;
      _held[action] = target;
    } else {
      target = _held.remove(action) ?? _pick(action);
      if (target == null) return OutputRoute.none;
    }
    await target.send(action, pressed: pressed);
    return identical(target, _obc) ? OutputRoute.openBikeControl : OutputRoute.keyboard;
  }

  GameOutput? _pick(GameAction action) {
    if (_obc.available.value && _obc.supports(action)) return _obc;
    if (_keyboard.available.value && _keyboard.supports(action)) return _keyboard;
    return null;
  }
}
