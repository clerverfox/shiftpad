import 'dart:typed_data';

class BleNotification {
  const BleNotification(this.charUuid, this.value);

  /// Lowercase 128-bit UUID of the characteristic.
  final String charUuid;
  final Uint8List value;
}

/// One BLE connection to one device. UUIDs are lowercase 128-bit strings.
abstract class BleLink {
  String get deviceId;

  /// Emits true when connected, false when the connection is lost.
  Stream<bool> get connection;

  Future<void> connect({Duration timeout = const Duration(seconds: 10)});
  Future<void> disconnect();

  /// Returns the UUIDs of the services the device exposes.
  Future<List<String>> discoverServices();

  Future<void> subscribe(String service, String char, {required bool indicate});
  Stream<BleNotification> get notifications;

  Future<void> write(String service, String char, Uint8List data,
      {bool withoutResponse = true});
  Future<Uint8List?> read(String service, String char);
}
