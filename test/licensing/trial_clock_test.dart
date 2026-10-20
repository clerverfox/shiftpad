import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/licensing/trial_clock.dart';
import 'package:shiftpad/licensing/trial_store.dart';

class MemoryTrialStore implements TrialStore {
  DateTime? first;
  DateTime? last;

  @override
  Future<DateTime?> firstStart() async => first;
  @override
  Future<void> setFirstStart(DateTime t) async => first = t;
  @override
  Future<DateTime?> lastSeen() async => last;
  @override
  Future<void> setLastSeen(DateTime t) async => last = t;
}

void main() {
  final day0 = DateTime.utc(2026, 11, 1, 18);

  Future<TrialStatus> checkAt(MemoryTrialStore s, Duration after) =>
      TrialClock(store: s, now: () => day0.add(after)).check();

  test('first check records the first start: 14 days left', () async {
    final s = MemoryTrialStore();
    final t = await checkAt(s, Duration.zero);
    expect(s.first, day0);
    expect(t.active, isTrue);
    expect(t.daysLeft, 14);
  });

  test('day 13 -> 1 day left; just after day 14 -> ended', () async {
    final s = MemoryTrialStore();
    await checkAt(s, Duration.zero);
    expect((await checkAt(s, const Duration(days: 13))).daysLeft, 1);
    final ended = await checkAt(s, const Duration(days: 14, seconds: 1));
    expect(ended.active, isFalse);
    expect(ended.daysLeft, 0);
  });

  test('setting the clock back does not give days back', () async {
    final s = MemoryTrialStore();
    await checkAt(s, Duration.zero);
    await checkAt(s, const Duration(days: 5));
    final back = await checkAt(s, const Duration(days: -5));
    expect(back.daysLeft, 9);
  });

  test('combined store: the earliest first start wins (reinstall case)', () async {
    final prefs = MemoryTrialStore(); // wiped by a reinstall
    final registry = MemoryTrialStore()..first = day0;
    final combined = CombinedTrialStore([prefs, registry]);
    final t = await TrialClock(
            store: combined, now: () => day0.add(const Duration(days: 20)))
        .check();
    expect(t.active, isFalse);
    expect(prefs.first, isNull); // not overwritten with a later date
  });

  test('registry store round-trip (Windows)', () async {
    final key = r'Software\ShiftPadTest';
    addTearDown(() => Process.run('reg', ['delete', r'HKCU' + key, '/f']));
    final r = RegistryTrialStore(key);
    expect(await r.firstStart(), isNull);
    await r.setFirstStart(day0);
    await r.setLastSeen(day0.add(const Duration(days: 2)));
    expect(await RegistryTrialStore(key).firstStart(), day0);
    expect(await RegistryTrialStore(key).lastSeen(), day0.add(const Duration(days: 2)));
  }, skip: !Platform.isWindows);

  test('combined store: a failing store is skipped', () async {
    final ok = MemoryTrialStore();
    final t = await TrialClock(
            store: CombinedTrialStore([_Failing(), ok]), now: () => day0)
        .check();
    expect(t.daysLeft, 14);
    expect(ok.first, day0);
  });
}

class _Failing implements TrialStore {
  @override
  Future<DateTime?> firstStart() => throw StateError('no registry');
  @override
  Future<void> setFirstStart(DateTime t) => throw StateError('no registry');
  @override
  Future<DateTime?> lastSeen() => throw StateError('no registry');
  @override
  Future<void> setLastSeen(DateTime t) => throw StateError('no registry');
}
