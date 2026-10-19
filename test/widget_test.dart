import 'package:flutter_test/flutter_test.dart';
import 'package:shiftpad/app.dart';

void main() {
  testWidgets('shows the app title', (tester) async {
    await tester.pumpWidget(const ShiftPadApp());
    await tester.pumpAndSettle();
    expect(find.text('ShiftPad'), findsWidgets);
  });
}
