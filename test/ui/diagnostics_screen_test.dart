import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/ble/click_scanner.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/l10n/app_localizations.dart';
import 'package:shiftpad/ui/diagnostics_screen.dart';
import 'package:shiftpad/zwift/click_constants.dart';

import '../support/fake_services.dart';

Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  testWidgets('shows a card per side and live log lines', (tester) async {
    final h = FakeServicesHarness();
    await tester.pumpWidget(wrap(DiagnosticsScreen(services: h.services)));

    expect(find.text('Left controller'), findsOneWidget);
    expect(find.text('Right controller'), findsOneWidget);
    expect(find.text('Link: disconnected'), findsNWidgets(2));
    expect(find.text('Battery: —'), findsNWidgets(2));

    await tester.runAsync(() async {
      await h.services.start();
      h.scan.add(const DiscoveredClick(
          deviceId: 'r1', side: ClickSide.right, name: 'Click'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      h.links['r1']!.push(kSyncTxChar, kRideOn);
    });
    await tester.pump();

    expect(find.text('Link: ready'), findsOneWidget);
    expect(find.text('Lock: unlocked'), findsOneWidget);

    h.log.info('test', 'hello from the log');
    await tester.pump(); // deliver the stream event
    await tester.pump(); // rebuild
    expect(find.textContaining('[test] hello from the log'), findsOneWidget);

    await tester.runAsync(h.services.stop);
  });

  testWidgets('Export logs saves a file and shows its path', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('shiftpad_ui');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final h = FakeServicesHarness(documentsDir: tmp);
    h.log.info('app', 'start');
    await tester.pumpWidget(wrap(DiagnosticsScreen(services: h.services)));

    await tester.runAsync(() async {
      await tester.tap(find.text('Export logs'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(find.textContaining('Logs saved to'), findsOneWidget);
    expect(Directory('${tmp.path}/ShiftPad').listSync(), hasLength(1));
  });
}
