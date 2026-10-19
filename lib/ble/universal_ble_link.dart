import 'dart:async';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import 'ble_link.dart';

/// [BleLink] backed by the `universal_ble` plugin (WinRT on Windows).
class UniversalBleLink implements BleLink {
  UniversalBleLink(this.deviceId);

  @override
  final String deviceId;

  final _notifications = StreamController<BleNotification>.broadcast(sync: true);
  final _valueSubs = <String, StreamSubscription<Uint8List>>{};

  @override
  Stream<bool> get connection => UniversalBle.connectionStream(deviceId);

  @override
  Stream<BleNotification> get notifications => _notifications.stream;

  @override
  Future<void> connect({Duration timeout = const Duration(seconds: 10)}) =>
      UniversalBle.connect(deviceId, timeout: timeout);

  @override
  Future<void> disconnect() async {
    for (final s in _valueSubs.values) {
      await s.cancel();
    }
    _valueSubs.clear();
    await UniversalBle.disconnect(deviceId);
  }

  @override
  Future<List<String>> discoverServices() async =>
      (await UniversalBle.discoverServices(deviceId))
          .map((s) => s.uuid.toLowerCase())
          .toList();

  @override
  Future<void> subscribe(String service, String char,
      {required bool indicate}) async {
    final key = char.toLowerCase();
    // Listen before enabling so the first value is not missed.
    await _valueSubs.remove(key)?.cancel();
    _valueSubs[key] = UniversalBle.characteristicValueStream(deviceId, char)
        .listen((v) => _notifications.add(BleNotification(key, v)));
    if (indicate) {
      await UniversalBle.subscribeIndications(deviceId, service, char);
    } else {
      await UniversalBle.subscribeNotifications(deviceId, service, char);
    }
  }

  @override
  Future<void> write(String service, String char, Uint8List data,
          {bool withoutResponse = true}) =>
      UniversalBle.write(deviceId, service, char, data,
          withoutResponse: withoutResponse);

  @override
  Future<Uint8List?> read(String service, String char) =>
      UniversalBle.read(deviceId, service, char);
}
