import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';

/// Where the trial dates are kept.
abstract class TrialStore {
  Future<DateTime?> firstStart();
  Future<void> setFirstStart(DateTime t);
  Future<DateTime?> lastSeen();
  Future<void> setLastSeen(DateTime t);
}

/// Dates in shared_preferences (removed with the app's data).
class PrefsTrialStore implements TrialStore {
  PrefsTrialStore({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  Future<DateTime?> _get(String key) async =>
      DateTime.tryParse((await _prefs()).getString(key) ?? '');

  Future<void> _set(String key, DateTime t) async =>
      (await _prefs()).setString(key, t.toUtc().toIso8601String());

  @override
  Future<DateTime?> firstStart() => _get('trial.firstStart');
  @override
  Future<void> setFirstStart(DateTime t) => _set('trial.firstStart', t);
  @override
  Future<DateTime?> lastSeen() => _get('trial.lastSeen');
  @override
  Future<void> setLastSeen(DateTime t) => _set('trial.lastSeen', t);
}

/// Dates in `HKCU\Software\ShiftPad`, which survives deleting the app folder
/// and its settings.
class RegistryTrialStore implements TrialStore {
  RegistryTrialStore([this._subKey = r'Software\ShiftPad']);

  final String _subKey;

  DateTime? _get(String name) => using((arena) {
        final size = arena<Uint32>()..value = 256;
        final buffer = arena<Uint16>(128).cast<Utf16>();
        final result = RegGetValue(
          HKEY_CURRENT_USER,
          PCWSTR(_subKey.toNativeUtf16(allocator: arena)),
          PCWSTR(name.toNativeUtf16(allocator: arena)),
          RRF_RT_REG_SZ,
          null,
          buffer,
          size,
        );
        if (result != ERROR_SUCCESS) return null;
        return DateTime.tryParse(buffer.toDartString());
      });

  void _set(String name, DateTime t) => using((arena) {
        final value = t.toUtc().toIso8601String().toNativeUtf16(allocator: arena);
        RegSetKeyValue(
          HKEY_CURRENT_USER,
          PCWSTR(_subKey.toNativeUtf16(allocator: arena)),
          PCWSTR(name.toNativeUtf16(allocator: arena)),
          REG_SZ,
          value,
          (t.toUtc().toIso8601String().length + 1) * 2,
        );
      });

  @override
  Future<DateTime?> firstStart() async => _get('TrialFirstStart');
  @override
  Future<void> setFirstStart(DateTime t) async => _set('TrialFirstStart', t);
  @override
  Future<DateTime?> lastSeen() async => _get('TrialLastSeen');
  @override
  Future<void> setLastSeen(DateTime t) async => _set('TrialLastSeen', t);
}

/// Reads every store and keeps the dates least favourable to resetting the
/// trial: the earliest first start and the latest "last seen". Writes go to
/// all stores.
class CombinedTrialStore implements TrialStore {
  CombinedTrialStore(this._stores);

  final List<TrialStore> _stores;

  Future<List<DateTime>> _all(Future<DateTime?> Function(TrialStore) read) async {
    final out = <DateTime>[];
    for (final s in _stores) {
      try {
        final v = await read(s);
        if (v != null) out.add(v);
      } catch (_) {}
    }
    return out;
  }

  Future<void> _writeAll(Future<void> Function(TrialStore) write) async {
    for (final s in _stores) {
      try {
        await write(s);
      } catch (_) {}
    }
  }

  @override
  Future<DateTime?> firstStart() async {
    final all = await _all((s) => s.firstStart());
    return all.isEmpty ? null : all.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  @override
  Future<void> setFirstStart(DateTime t) => _writeAll((s) => s.setFirstStart(t));

  @override
  Future<DateTime?> lastSeen() async {
    final all = await _all((s) => s.lastSeen());
    return all.isEmpty ? null : all.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Future<void> setLastSeen(DateTime t) => _writeAll((s) => s.setLastSeen(t));
}
