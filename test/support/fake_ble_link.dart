import 'dart:async';
import 'dart:typed_data';

import 'package:shiftpad/ble/ble_link.dart';

class WriteCall {
  WriteCall(this.service, this.char, this.data);
  final String service;
  final String char;
  final Uint8List data;
}

class FakeBleLink implements BleLink {
  FakeBleLink({
    this.deviceId = 'dev',
    List<String>? services,
    this.connectError,
    Map<String, Uint8List>? readValues,
  })  : services = services ?? const [],
        readValues = readValues ?? {};

  @override
  final String deviceId;
  List<String> services;
  Object? connectError;
  final Map<String, Uint8List> readValues;

  final writeCalls = <WriteCall>[];
  final subscriptions = <(String, String, bool)>[];
  int connectCount = 0;
  int disconnectCount = 0;
  bool connected = false;

  final _connection = StreamController<bool>.broadcast(sync: true);
  final _notifications = StreamController<BleNotification>.broadcast(sync: true);

  List<Uint8List> get writes => writeCalls.map((w) => w.data).toList();

  void push(String charUuid, List<int> value) =>
      _notifications.add(BleNotification(charUuid, Uint8List.fromList(value)));

  void dropConnection() {
    connected = false;
    _connection.add(false);
  }

  @override
  Stream<bool> get connection => _connection.stream;

  @override
  Stream<BleNotification> get notifications => _notifications.stream;

  @override
  Future<void> connect({Duration timeout = const Duration(seconds: 10)}) async {
    connectCount++;
    if (connectError != null) throw connectError!;
    connected = true;
    _connection.add(true);
  }

  @override
  Future<void> disconnect() async {
    disconnectCount++;
    connected = false;
  }

  @override
  Future<List<String>> discoverServices() async => services;

  @override
  Future<void> subscribe(String service, String char, {required bool indicate}) async =>
      subscriptions.add((service, char, indicate));

  @override
  Future<void> write(String service, String char, Uint8List data,
          {bool withoutResponse = true}) async =>
      writeCalls.add(WriteCall(service, char, data));

  @override
  Future<Uint8List?> read(String service, String char) async {
    final v = readValues[char];
    if (v == null) throw StateError('not readable');
    return v;
  }
}
