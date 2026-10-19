import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/ble/click_scanner.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/mapping/keymap.dart';
import 'package:shiftpad/ui/setup_wizard.dart';
import 'package:shiftpad/zwift/click_constants.dart';

import '../support/fake_services.dart';
import '../support/ui.dart';
import '../support/varint.dart';

void main() {
  testWidgets('walks through the steps; + press unlocks Finish; saves settings',
      (tester) async {
    final h = FakeServicesHarness();
    var done = false;
    await tester.runAsync(() async {
      await h.services.controller.start();
      await h.devices.start();
    });
    await tester.pumpWidget(wrap(SetupWizard(services: h.services, onDone: () => done = true)));
    await tester.pumpAndSettle();

    expect(find.text('Wake your controllers'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Choose how you ride'), findsOneWidget);
    await tester.tap(find.text('Right controller only'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Next'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(await tester.runAsync(h.services.settings.mode), ControlMode.rightOnly);

    expect(find.text('Connect MyWhoosh'), findsOneWidget);
    expect(find.textContaining('OpenBikeControl'), findsWidgets);
    await tester.tap(find.text('Next'));
    await tester.pump(); // the waiting spinner never settles

    expect(find.text('Press + to test'), findsOneWidget);
    expect(find.text('Waiting for +…'), findsOneWidget);

    // A real + press arrives from the right pod.
    await tester.runAsync(() async {
      h.scan.add(const DiscoveredClick(deviceId: 'r1', side: ClickSide.right, name: 'Click'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      h.links['r1']!.push(kSyncTxChar, kRideOn);
      h.links['r1']!.push(kAsyncChar, pressedFrame(0x1000));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.text('It works!'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Finish'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    expect(done, isTrue);
    expect(await tester.runAsync(h.services.settings.wizardDone), isTrue);
    await tester.runAsync(h.devices.stop);
  });
}
