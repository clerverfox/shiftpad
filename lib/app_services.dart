import 'dart:io';

import 'ble/click_device_manager.dart';
import 'ble/click_scanner.dart';
import 'ble/universal_ble_link.dart';
import 'diagnostics/app_log.dart';
import 'output/keyboard/key_injector.dart';
import 'output/keyboard/keyboard_output.dart';
import 'output/keyboard/win32_key_injector.dart';
import 'output/obc/mdns_advertiser.dart';
import 'output/obc/obc_output.dart';
import 'output/obc/windows_dnssd_advertiser.dart';
import 'output/output_router.dart';
import 'zwift/click_session.dart';

/// Everything the UI needs, wired together once at startup.
class AppServices {
  AppServices({
    required this.devices,
    required this.log,
    required this.keyboard,
    required this.obc,
  }) : router = OutputRouter(obc: obc, keyboard: keyboard);

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
    return AppServices(devices: devices, log: log, keyboard: keyboard, obc: obc);
  }

  final ClickDeviceManager devices;
  final AppLog log;
  final KeyboardOutput keyboard;
  final ObcOutput obc;
  final OutputRouter router;

  Future<void> start() async {
    log.info('app', 'start');
    devices.events.listen((e) => log.info(
        'button', '${e.button.name} ${e.pressed ? 'down' : 'up'}'));
    router.route.addListener(() => log.info('route', router.route.value.name));
    await router.start();
    await devices.start();
  }

  Future<void> stop() async {
    await devices.stop();
    await router.stop();
  }
}
