import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../ble/ble_link.dart';
import '../core/click_button.dart';
import 'button_differ.dart';
import 'click_constants.dart';
import 'click_frame.dart';

enum LinkState { disconnected, connecting, handshaking, ready, busyElsewhere, error }

enum LockState { unknown, unlocked, locked }

class ClickStatus {
  const ClickStatus({
    required this.side,
    this.link = LinkState.disconnected,
    this.lock = LockState.unknown,
    this.firmware,
    this.batteryPercent,
    this.lastFrameAt,
    this.error,
  });

  final ClickSide side;
  final LinkState link;
  final LockState lock;
  final String? firmware;
  final int? batteryPercent;
  final DateTime? lastFrameAt;
  final String? error;

  static const _keep = Object();

  ClickStatus copyWith({
    LinkState? link,
    LockState? lock,
    Object? firmware = _keep,
    Object? batteryPercent = _keep,
    Object? lastFrameAt = _keep,
    Object? error = _keep,
  }) =>
      ClickStatus(
        side: side,
        link: link ?? this.link,
        lock: lock ?? this.lock,
        firmware: identical(firmware, _keep) ? this.firmware : firmware as String?,
        batteryPercent: identical(batteryPercent, _keep)
            ? this.batteryPercent
            : batteryPercent as int?,
        lastFrameAt: identical(lastFrameAt, _keep)
            ? this.lastFrameAt
            : lastFrameAt as DateTime?,
        error: identical(error, _keep) ? this.error : error as String?,
      );

  /// True when this pod's buttons can be trusted to arrive.
  bool get usable => link == LinkState.ready && lock != LockState.locked;
}

/// Talks to one Click V2 pod: handshake, button frames, keep-alive.
class ClickSession {
  ClickSession({
    required this._link,
    required ClickSide side,
    this._onRawFrame,
    this._onInfo,
    this._keepAliveEvery = const Duration(seconds: 3),
    this._idleRebootAfter = const Duration(seconds: 55),
    this._idleRebootEnabled = true,
    this._idleRebootWhen,
    this._connectTimeout = const Duration(seconds: 10),
    this._now = DateTime.now,
  }) : _status = ValueNotifier(ClickStatus(side: side));

  final BleLink _link;
  final void Function(Uint8List bytes)? _onRawFrame;
  final void Function(String message)? _onInfo;
  final Duration _keepAliveEvery;
  final Duration _idleRebootAfter;
  final bool _idleRebootEnabled;

  /// Extra condition checked when the idle clock runs out, e.g. "the other
  /// pod is not connected" (a connected pair does not get dropped).
  final bool Function()? _idleRebootWhen;
  final Duration _connectTimeout;
  final DateTime Function() _now;

  final ValueNotifier<ClickStatus> _status;
  final _events = StreamController<ButtonEvent>.broadcast(sync: true);
  final _differ = ButtonDiffer();

  StreamSubscription<BleNotification>? _notifySub;
  StreamSubscription<bool>? _connectionSub;
  Timer? _keepAlive;
  Timer? _idle;
  String? _service;
  bool _running = false;

  /// Whether this pod answered at least once since the app started. A pod
  /// that never answered may be held by a Zwift app; one that did and now
  /// fails to connect has most likely gone to sleep.
  bool _everReady = false;

  BleLink get link => _link;
  Stream<ButtonEvent> get events => _events.stream;
  ValueListenable<ClickStatus> get status => _status;

  ClickStatus get _s => _status.value;
  set _s(ClickStatus v) => _status.value = v;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _notifySub ??= _link.notifications.listen(_onNotification);
    _connectionSub ??= _link.connection.listen((connected) {
      if (!connected) _onConnectionLost();
    });

    _s = _s.copyWith(link: LinkState.connecting, error: null);
    try {
      await _link.connect(timeout: _connectTimeout);
    } catch (e) {
      _running = false;
      _s = _s.copyWith(
          link: _everReady ? LinkState.disconnected : LinkState.busyElsewhere,
          error: '$e');
      _onInfo?.call('connect failed: $e');
      return;
    }
    if (!_running) return;

    try {
      final services = (await _link.discoverServices())
          .map((s) => s.toLowerCase())
          .toList();
      _service = services.contains(kClickService)
          ? kClickService
          : services.contains(kClickServiceAlt)
              ? kClickServiceAlt
              : null;
      if (_service == null) {
        throw StateError('Click service not found (got $services)');
      }
      _s = _s.copyWith(link: LinkState.handshaking);
      await _link.subscribe(_service!, kAsyncChar, indicate: false);
      await _link.subscribe(_service!, kSyncTxChar, indicate: true);
      _resetIdleTimer();
      await _write(kHandshakeV2);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await _write(kActivate1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await _write(kActivate2);
      unawaited(_readInfo(services));
    } catch (e) {
      _onInfo?.call('setup failed: $e');
      _s = _s.copyWith(link: LinkState.error, error: '$e');
      _stopTimers();
      _running = false;
      try {
        await _link.disconnect();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    _running = false;
    _stopTimers();
    _releaseAll();
    try {
      await _link.disconnect();
    } catch (_) {}
    _s = _s.copyWith(link: LinkState.disconnected);
  }

  Future<void> dispose() async {
    await stop();
    await _notifySub?.cancel();
    await _connectionSub?.cancel();
    await _events.close();
  }

  void _onNotification(BleNotification n) {
    final at = _now();
    _onRawFrame?.call(n.value);
    _s = _s.copyWith(lastFrameAt: at);

    switch (parseClickFrame(n.value)) {
      case RideOnFrame():
        // Keep-alive echoes also arrive after a challenge: they do not prove
        // an unlock, so they only settle an unknown state.
        _markReady(_s.lock == LockState.unknown ? LockState.unlocked : _s.lock);
        unawaited(_write(kKeepUnlocked).catchError((_) {}));
      case LockChallengeFrame():
        _markReady(LockState.locked);
      case ButtonsFrame(:final pressed):
        // Windows drops a lone pod ~60 s after its last button frame
        // (keep-alive echoes do not count), so the idle clock follows
        // button frames only.
        _resetIdleTimer();
        // The left pod relays the right pod's buttons (checkpoint A), so each
        // session only reports its own side to avoid double shifts.
        final own = {
          for (final b in pressed)
            if (b.side == _s.side) b,
        };
        final events = _differ.update(own, at);
        // A pod that still sends its own presses is usable, challenge or not.
        final lock = events.isNotEmpty ? LockState.unlocked : _s.lock;
        if (_s.link != LinkState.ready || lock != _s.lock) _markReady(lock);
        for (final e in events) {
          _events.add(e);
        }
      case BatteryFrame(:final percent):
        if (percent != _s.batteryPercent) {
          _s = _s.copyWith(batteryPercent: percent);
        }
      case DeviceInfoFrame(:final firmware):
        if (firmware != null && firmware != _s.firmware) {
          _s = _s.copyWith(firmware: firmware);
        }
      case UnknownFrame():
        break;
    }
  }

  void _markReady(LockState lock) {
    if (lock != _s.lock) _onInfo?.call('lock: ${lock.name}');
    _everReady = true;
    _s = _s.copyWith(link: LinkState.ready, lock: lock, error: null);
    _keepAlive ??= Timer.periodic(_keepAliveEvery, (_) {
      unawaited(_write(kRideOn).catchError((_) {}));
    });
  }

  void _onConnectionLost() {
    if (!_running) return;
    _onInfo?.call('connection lost');
    _running = false;
    _stopTimers();
    _releaseAll();
    _s = _s.copyWith(link: LinkState.disconnected);
  }

  /// Emits releases for any held button so nothing stays stuck down.
  void _releaseAll() {
    for (final e in _differ.update(const {}, _now())) {
      _events.add(e);
    }
  }

  void _resetIdleTimer() {
    _idle?.cancel();
    if (!_idleRebootEnabled) return;
    _idle = Timer(_idleRebootAfter, () {
      if (!(_idleRebootWhen?.call() ?? true)) {
        _resetIdleTimer();
        return;
      }
      _onInfo?.call('idle ${_idleRebootAfter.inSeconds}s: reboot');
      unawaited(_write(kReboot).catchError((_) {}));
    });
  }

  void _stopTimers() {
    _keepAlive?.cancel();
    _keepAlive = null;
    _idle?.cancel();
    _idle = null;
  }

  Future<void> _write(Uint8List data) =>
      _link.write(_service!, kSyncRxChar, data, withoutResponse: true);

  Future<void> _readInfo(List<String> services) async {
    if (services.contains(kBatteryService)) {
      try {
        final v = await _link.read(kBatteryService, kBatteryLevelChar);
        if (v != null && v.isNotEmpty) _s = _s.copyWith(batteryPercent: v[0]);
      } catch (_) {}
    }
    if (services.contains(kDeviceInfoService)) {
      try {
        final v = await _link.read(kDeviceInfoService, kFirmwareRevisionChar);
        if (v != null && v.isNotEmpty) {
          _s = _s.copyWith(firmware: utf8.decode(v, allowMalformed: true).trim());
        }
      } catch (_) {}
    }
  }
}
