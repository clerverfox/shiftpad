import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/ui/home_screen.dart';
import 'package:shiftpad/ui/widgets/pod_status_card.dart';
import 'package:shiftpad/zwift/click_session.dart';

import '../support/fake_services.dart';
import '../support/ui.dart';

void main() {
  testWidgets('shows both pods, the route and the fallback banner', (tester) async {
    final h = FakeServicesHarness();
    await tester.runAsync(h.services.controller.start);
    await tester.pumpWidget(wrap(HomeScreen(services: h.services, onRunSetup: () {})));
    await tester.pump();

    expect(find.byType(PodStatusCard), findsNWidgets(2));
    expect(find.text('Left controller'), findsOneWidget);
    expect(find.text('Right controller'), findsOneWidget);
    expect(find.text('Searching…'), findsNWidgets(2));
    // No MyWhoosh in tests: keyboard injector unsupported, no OBC client.
    expect(find.text('MyWhoosh not found'), findsOneWidget);
    // Both-pods mode with the left pod not connected.
    expect(find.text('Left controller locked — using right-only buttons'), findsOneWidget);
    expect(find.text('Press a button to try it.'), findsOneWidget);
  });

  testWidgets('pod card labels for each state', (tester) async {
    Future<void> show(ClickStatus s) =>
        tester.pumpWidget(wrap(Scaffold(body: PodStatusCard(status: s))));

    await show(const ClickStatus(
        side: ClickSide.right, link: LinkState.ready, lock: LockState.unlocked, batteryPercent: 90));
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Battery 90%'), findsOneWidget);

    await show(const ClickStatus(side: ClickSide.right, link: LinkState.busyElsewhere));
    expect(find.text("Can't connect"), findsOneWidget);
    expect(find.textContaining('Zwift Companion open'), findsOneWidget);

    await show(const ClickStatus(
        side: ClickSide.left, link: LinkState.ready, lock: LockState.locked));
    expect(find.text('Locked'), findsOneWidget);

    await show(const ClickStatus(side: ClickSide.left, link: LinkState.connecting));
    expect(find.text('Searching…'), findsOneWidget);
  });

  testWidgets('menu opens troubleshooting', (tester) async {
    final h = FakeServicesHarness();
    await tester.pumpWidget(wrap(HomeScreen(services: h.services, onRunSetup: () {})));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Troubleshooting'));
    await tester.pumpAndSettle();
    expect(find.text('MyWhoosh does not show ShiftPad'), findsOneWidget);
  });
}
