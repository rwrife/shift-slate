import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_slate/main.dart';

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    for (final size in [const Size(390, 844), const Size(1100, 800)]) {
      testWidgets('$platform $size keyboard follows primary actions', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ShiftSlateApp(platform: platform));
        await tester.pumpAndSettle();
        final event = find.text('Add event');
        final volunteer = find.text('Add volunteer');
        expect(event, findsOneWidget);
        expect(volunteer, findsOneWidget);
        if (size.width >= 700) {
          expect(
            tester.getTopLeft(event).dx,
            lessThan(tester.getTopLeft(volunteer).dx),
          );
        } else {
          expect(
            tester.getTopLeft(event).dy,
            lessThan(tester.getTopLeft(volunteer).dy),
          );
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(Focus.of(tester.element(event)).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(Focus.of(tester.element(volunteer)).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Private contact note'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
