import 'dart:async';
import 'dart:io';

import 'package:shiftpad/app_services.dart';
import 'package:shiftpad/ble/click_device_manager.dart';
import 'package:shiftpad/ble/click_scanner.dart';
import 'package:shiftpad/diagnostics/app_log.dart';
import 'package:shiftpad/output/keyboard/key_injector.dart';
import 'package:shiftpad/output/keyboard/keyboard_output.dart';
import 'package:shiftpad/output/obc/mdns_advertiser.dart';
import 'package:shiftpad/output/obc/obc_output.dart';
import 'package:shiftpad/zwift/click_constants.dart';

import 'fake_ble_link.dart';

/// AppServices backed by fake BLE; push discoveries through [scan].
class FakeServicesHarness {
  FakeServicesHarness({Directory? documentsDir}) {
    log = AppLog(
        documentsDir: () async => documentsDir ?? Directory.systemTemp);
    devices = ClickDeviceManager(
      scan: () => scan.stream,
      linkFactory: (id) =>
          links[id] ??= FakeBleLink(deviceId: id, services: [kClickService]),
    );
    keyboard = KeyboardOutput(injector: const UnsupportedKeyInjector());
    obc = ObcOutput(
        advertiser: const NoopMdnsAdvertiser(),
        log: log,
        bindAddress: InternetAddress.loopbackIPv4,
        port: 0);
    services = AppServices(
        devices: devices, log: log, keyboard: keyboard, obc: obc);
  }

  final scan = StreamController<DiscoveredClick>.broadcast();
  final links = <String, FakeBleLink>{};
  late final AppLog log;
  late final ClickDeviceManager devices;
  late final KeyboardOutput keyboard;
  late final ObcOutput obc;
  late final AppServices services;
}
