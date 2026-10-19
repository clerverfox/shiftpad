import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/core/click_button.dart';
import 'package:shiftpad/core/game_action.dart';
import 'package:shiftpad/mapping/keymap.dart';
import 'package:shiftpad/ui/mapping_screen.dart';

import '../support/fake_services.dart';
import '../support/ui.dart';

void main() {
  testWidgets('tap a button, choose an action, it is saved; reset restores', (tester) async {
    final h = FakeServicesHarness(prefs: {'mode': 'rightOnly'});
    await tester.pumpWidget(wrap(MappingScreen(services: h.services)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    // Right-only mode: only the right pod is listed.
    expect(find.text('Right controller'), findsOneWidget);
    expect(find.text('Left controller'), findsNothing);

    await tester.tap(find.text('Y'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an action for Y'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Shift down').last);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    final saved = await tester.runAsync(() => h.services.settings.keymap(ControlMode.rightOnly));
    expect(saved!.actionFor(ClickButton.y), GameAction.shiftDown);

    await tester.runAsync(() async {
      await tester.tap(find.text('Reset to defaults'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    final reset = await tester.runAsync(() => h.services.settings.keymap(ControlMode.rightOnly));
    expect(reset, Keymap.defaults(ControlMode.rightOnly));
  });

  testWidgets('both-pods mode lists the left pod too', (tester) async {
    final h = FakeServicesHarness(prefs: {'mode': 'bothPods'});
    await tester.pumpWidget(wrap(MappingScreen(services: h.services)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('Left controller'), findsOneWidget);
    expect(find.text('−'), findsOneWidget);
  });
}
