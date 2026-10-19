import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/app.dart';

import 'support/fake_services.dart';

void main() {
  testWidgets('app starts', (tester) async {
    final h = FakeServicesHarness();
    await tester.pumpWidget(ShiftPadApp(services: h.services));
    await tester.pumpAndSettle();
    expect(find.text('Diagnostics'), findsOneWidget);
  });
}
