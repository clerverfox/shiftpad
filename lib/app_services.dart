import 'ble/click_device_manager.dart';
import 'ble/click_scanner.dart';
import 'ble/universal_ble_link.dart';
import 'diagnostics/app_log.dart';
import 'zwift/click_session.dart';

/// Everything the UI needs, wired together once at startup.
class AppServices {
  AppServices({required this.devices, required this.log});

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
    return AppServices(devices: devices, log: log);
  }

  final ClickDeviceManager devices;
  final AppLog log;

  Future<void> start() async {
    log.info('app', 'start');
    devices.events.listen((e) => log.info(
        'button', '${e.button.name} ${e.pressed ? 'down' : 'up'}'));
    await devices.start();
  }

  Future<void> stop() => devices.stop();
}
