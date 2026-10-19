import 'dart:async';

import 'package:universal_ble/universal_ble.dart';

import '../core/click_button.dart';
import '../zwift/click_advertisement.dart';

class DiscoveredClick {
  const DiscoveredClick({
    required this.deviceId,
    required this.side,
    required this.name,
    this.rssi,
  });

  final String deviceId;
  final ClickSide side;
  final String name;
  final int? rssi;
}

/// Scans for Click V2 pods while listened to. Each device is reported once.
Stream<DiscoveredClick> scanClicks() {
  final seen = <String>{};
  StreamSubscription<BleDevice>? sub;
  late final StreamController<DiscoveredClick> controller;
  controller = StreamController<DiscoveredClick>(
    onListen: () async {
      UniversalBle.queueType = QueueType.perDevice;
      sub = UniversalBle.scanStream.listen((d) {
        if (seen.contains(d.deviceId)) return;
        for (final m in d.manufacturerDataList) {
          final side = sideFromManufacturerData(m.companyId, m.payload);
          if (side == null) continue;
          seen.add(d.deviceId);
          controller.add(DiscoveredClick(
            deviceId: d.deviceId,
            side: side,
            name: d.name ?? 'Click',
            rssi: d.rssi,
          ));
          return;
        }
      });
      try {
        await UniversalBle.startScan();
      } catch (e, st) {
        controller.addError(e, st);
      }
    },
    onCancel: () async {
      await sub?.cancel();
      try {
        await UniversalBle.stopScan();
      } catch (_) {}
    },
  );
  return controller.stream;
}
