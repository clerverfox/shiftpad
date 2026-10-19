import 'dart:io';

import 'ble/click_device_manager.dart';
import 'ble/click_scanner.dart';
import 'ble/universal_ble_link.dart';
import 'diagnostics/app_log.dart';
import 'mapping/settings_store.dart';
import 'output/keyboard/key_injector.dart';
import 'output/keyboard/keyboard_output.dart';
import 'output/keyboard/win32_key_injector.dart';
import 'output/obc/mdns_advertiser.dart';
import 'output/obc/obc_output.dart';
import 'output/obc/windows_dnssd_advertiser.dart';
import 'output/output_router.dart';
import 'shiftpad_controller.dart';
import 'zwift/click_session.dart';

/// Everything the UI needs, wired together once at startup.
class AppServices {
  AppServices({
    required this.devices,
    required this.log,
    required this.keyboard,
    required this.obc,
    required this.settings,
  }) : router = OutputRouter(obc: obc, keyboard: keyboard) {
    controller = ShiftPadController(
        devices: devices, router: router, settings: settings, log: log);
  }

  /// Real Bluetooth wiring for the running app.
  factory AppServices.create() {
    final log = AppLog();
    final devices = ClickDeviceManager(
      scan: scanClicks,
      linkFactory: UniversalBleLink.new,
      sessionFactory: (link, side) => ClickSession(
        link: link,
        side: side,
        onRawFrame: (bytes) => log.raw(side, bytes),
        onInfo: (m) => log.info(side.name, m),
      ),
      onInfo: (m) => log.info('ble', m),
    );
    final keyboard = KeyboardOutput(
      injector: Platform.isWindows
          ? Win32KeyInjector(onInfo: (m) => log.info('keyboard', m))
          : const UnsupportedKeyInjector(),
    );
    final obc = ObcOutput(
      advertiser: Platform.isWindows
          ? WindowsDnsSdAdvertiser(onInfo: (m) => log.info('obc', m))
          : const NoopMdnsAdvertiser(),
      log: log,
    );
    return AppServices(
      devices: devices,
      log: log,
      keyboard: keyboard,
      obc: obc,
      settings: SettingsStore(),
    );
  }

  final ClickDeviceManager devices;
  final AppLog log;
  final KeyboardOutput keyboard;
  final ObcOutput obc;
  final OutputRouter router;
  final SettingsStore settings;
  late final ShiftPadController controller;

  Future<void> start() async {
    log.info('app', 'start');
    keyboard.keys = {...KeyboardOutput.defaultKeys, ...await settings.keyboardKeys()};
    router.route.addListener(() => log.info('route', router.route.value.name));
    await router.start();
    await controller.start();
    await devices.start();
  }

  Future<void> stop() async {
    await devices.stop();
    await controller.stop();
    await router.stop();
  }
}
