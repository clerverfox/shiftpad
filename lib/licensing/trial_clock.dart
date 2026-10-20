import 'pricing.dart';
import 'trial_store.dart';

class TrialStatus {
  const TrialStatus({required this.active, required this.daysLeft, required this.endsAt});

  final bool active;

  /// Whole days left, rounded up (13 h left counts as 1 day).
  final int daysLeft;
  final DateTime endsAt;
}

/// Counts the free trial from the first app start.
class TrialClock {
  TrialClock({
    required this._store,
    this._now = DateTime.now,
    this._length = kTrialLength,
  });

  final TrialStore _store;
  final DateTime Function() _now;
  final Duration _length;

  Future<TrialStatus> check() async {
    final wallClock = _now().toUtc();
    var first = await _store.firstStart();
    if (first == null) {
      first = wallClock;
      await _store.setFirstStart(first);
    }
    // Setting the clock back must not give days back.
    final lastSeen = await _store.lastSeen();
    final now = lastSeen != null && lastSeen.isAfter(wallClock) ? lastSeen : wallClock;
    if (lastSeen == null || now.isAfter(lastSeen)) await _store.setLastSeen(now);

    final endsAt = first.add(_length);
    final left = endsAt.difference(now);
    final active = left > Duration.zero;
    final daysLeft = active ? (left.inSeconds / Duration.secondsPerDay).ceil() : 0;
    return TrialStatus(active: active, daysLeft: daysLeft, endsAt: endsAt);
  }
}
