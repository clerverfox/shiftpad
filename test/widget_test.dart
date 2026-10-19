import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/app.dart';

import 'support/fake_services.dart';

void main() {
  testWidgets('first launch opens the setup wizard', (tester) async {
    final h = FakeServicesHarness();
    await tester.pumpWidget(ShiftPadApp(services: h.services));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('Wake your controllers'), findsOneWidget);
  });

  testWidgets('after setup the home screen opens', (tester) async {
    final h = FakeServicesHarness(prefs: {'wizardDone': true});
    await tester.pumpWidget(ShiftPadApp(services: h.services));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('ShiftPad'), findsWidgets);
    expect(find.text('Right controller'), findsOneWidget);
  });
}
