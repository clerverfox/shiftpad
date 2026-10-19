import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ble/click_device_manager.dart';
import 'core/click_button.dart';
import 'core/game_action.dart';
import 'diagnostics/app_log.dart';
import 'mapping/keymap.dart';
import 'mapping/settings_store.dart';
import 'output/output_router.dart';

/// Turns pod button events into game actions, in order, one per press.
class ShiftPadController {
  ShiftPadController({
    required this._devices,
    required this._router,
    required this._settings,
    required this._log,
    this._now = DateTime.now,
  });

  final ClickDeviceManager _devices;
  final OutputRouter _router;
  final SettingsStore _settings;
  final AppLog _log;
  final DateTime Function() _now;

  final _fallback = ValueNotifier(false);
  final _lastAction = ValueNotifier<(GameAction, Duration)?>(null);
  final _mode = ValueNotifier(ControlMode.bothPods);
  final _keymaps = <ControlMode, Keymap>{
    for (final m in ControlMode.values) m: Keymap.defaults(m),
  };

  /// Action each held button triggered, so its release matches its press
  /// even if the mapping changed in between.
  final _held = <ClickButton, GameAction>{};

  StreamSubscription<ButtonEvent>? _sub;
  Future<void> _queue = Future.value();

  /// True while "both pods" is chosen but the left pod is not usable: the
  /// right pod then also gets the right-only buttons (B = shift down).
  ValueListenable<bool> get fallbackToRightOnly => _fallback;

  /// Last action sent and the time from the pod frame to the send.
  ValueListenable<(GameAction, Duration)?> get lastAction => _lastAction;

  ValueListenable<ControlMode> get mode => _mode;

  Future<void> start() async {
    await reloadSettings();
    _devices.statuses.addListener(_updateFallback);
    _updateFallback();
    _queue = Future.value(); // created in the zone that runs the controller
    _sub = _devices.events.listen((e) {
      // Chained so sends stay in press order even when one is slow.
      _queue = _queue.then((_) => _handle(e)).catchError((Object err) {
        // One failure must not stop every later shift.
        _log.info('controller', 'send failed: $err');
      });
    });
  }

  Future<void> stop() async {
    _devices.statuses.removeListener(_updateFallback);
    await _sub?.cancel();
    _sub = null;
    await _queue;
  }

  /// Re-reads mode and keymaps, e.g. after the mapping screen saved them.
  Future<void> reloadSettings() async {
    _mode.value = await _settings.mode();
    for (final m in ControlMode.values) {
      _keymaps[m] = await _settings.keymap(m);
    }
    _updateFallback();
  }

  void _updateFallback() {
    final left = _devices.statuses.value[ClickSide.left];
    final fallback =
        _mode.value == ControlMode.bothPods && !(left?.usable ?? false);
    if (fallback != _fallback.value) {
      _log.info('controller',
          fallback ? 'left pod not usable: right-only buttons on' : 'left pod usable again');
      _fallback.value = fallback;
    }
  }

  GameAction _actionFor(ClickButton b) {
    final mode = b.side == ClickSide.right && _fallback.value
        ? ControlMode.rightOnly
        : _mode.value;
    return _keymaps[mode]!.actionFor(b);
  }

  Future<void> _handle(ButtonEvent e) async {
    final action =
        e.pressed ? _actionFor(e.button) : (_held.remove(e.button) ?? GameAction.none);
    if (e.pressed) {
      if (action == GameAction.none) return;
      _held[e.button] = action;
    } else if (action == GameAction.none) {
      return;
    }
    final route = await _router.send(action, pressed: e.pressed);
    final latency = _now().difference(e.at);
    if (e.pressed) _lastAction.value = (action, latency);
    _log.info('action', '${e.button.name} ${e.pressed ? 'down' : 'up'} -> '
        '${action.name} via ${route.name} ${latency.inMilliseconds} ms');
  }
}
