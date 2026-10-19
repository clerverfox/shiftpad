import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/click_button.dart';
import '../zwift/click_session.dart';
import 'ble_link.dart';
import 'click_scanner.dart';

/// Finds one pod per side, keeps each connected, and merges their events.
class ClickDeviceManager {
  ClickDeviceManager({
    required this._scan,
    required this._linkFactory,
    ClickSession Function(BleLink link, ClickSide side)? sessionFactory,
    this._onInfo,
  }) : _sessionFactory = sessionFactory ??
            ((link, side) => ClickSession(link: link, side: side));

  static const backoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];
  static const busyRetry = Duration(seconds: 5);

  final Stream<DiscoveredClick> Function() _scan;
  final BleLink Function(String deviceId) _linkFactory;
  final ClickSession Function(BleLink link, ClickSide side) _sessionFactory;
  final void Function(String message)? _onInfo;

  final _events = StreamController<ButtonEvent>.broadcast(sync: true);
  final _statuses = ValueNotifier<Map<ClickSide, ClickStatus>>({
    for (final side in ClickSide.values) side: ClickStatus(side: side),
  });
  final _sessions = <ClickSide, ClickSession>{};
  final _subs = <StreamSubscription<Object?>>[];
  final _listeners = <ClickSide, VoidCallback>{};
  final _retry = <ClickSide, Timer>{};
  final _failures = <ClickSide, int>{};
  StreamSubscription<DiscoveredClick>? _scanSub;
  bool _running = false;

  Stream<ButtonEvent> get events => _events.stream;
  ValueListenable<Map<ClickSide, ClickStatus>> get statuses => _statuses;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _startScanIfNeeded();
  }

  Future<void> stop() async {
    _running = false;
    // Cancels are not awaited: nothing depends on their completion.
    unawaited(_scanSub?.cancel());
    _scanSub = null;
    for (final t in _retry.values) {
      t.cancel();
    }
    _retry.clear();
    for (final e in _sessions.entries) {
      e.value.status.removeListener(_listeners[e.key]!);
      await e.value.stop();
    }
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _sessions.clear();
    _listeners.clear();
  }

  void _startScanIfNeeded() {
    if (!_running || _scanSub != null) return;
    if (ClickSide.values.every(_sessions.containsKey)) return;
    _onInfo?.call('scanning');
    _scanSub = _scan().listen(_onDiscovered, onError: (Object e) {
      _onInfo?.call('scan error: $e');
    });
  }

  void _onDiscovered(DiscoveredClick d) {
    if (!_running || _sessions.containsKey(d.side)) return;
    _onInfo?.call('found ${d.side.name} pod ${d.deviceId} rssi ${d.rssi}');
    final session = _sessionFactory(_linkFactory(d.deviceId), d.side);
    _sessions[d.side] = session;
    _subs.add(session.events.listen(_events.add));
    void listener() => _onStatus(d.side, session.status.value);
    _listeners[d.side] = listener;
    session.status.addListener(listener);
    _onStatus(d.side, session.status.value);
    unawaited(session.start());

    if (ClickSide.values.every(_sessions.containsKey)) {
      unawaited(_scanSub?.cancel());
      _scanSub = null;
    }
  }

  void _onStatus(ClickSide side, ClickStatus status) {
    final previous = _statuses.value[side]!.link;
    _statuses.value = {..._statuses.value, side: status};
    if (!_running || status.link == previous) return;
    switch (status.link) {
      case LinkState.ready:
        _failures[side] = 0;
      case LinkState.busyElsewhere:
        _scheduleRetry(side, busyRetry);
      case LinkState.disconnected || LinkState.error:
        final n = _failures[side] ?? 0;
        _failures[side] = n + 1;
        _scheduleRetry(side, backoff[n.clamp(0, backoff.length - 1)]);
      case LinkState.connecting || LinkState.handshaking:
        break;
    }
  }

  void _scheduleRetry(ClickSide side, Duration delay) {
    if (_retry[side]?.isActive ?? false) return;
    _onInfo?.call('${side.name} pod: retry in ${delay.inSeconds}s');
    _retry[side] = Timer(delay, () {
      final s = _sessions[side];
      if (_running && s != null) unawaited(s.start());
    });
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
  }
}
