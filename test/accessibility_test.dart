import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_slate/main.dart';
import 'package:shift_slate/planning.dart';
import 'package:shift_slate/store.dart';

void main() {
  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.windows,
  ]) {
    for (final size in [const Size(390, 844), const Size(1100, 800)]) {
      testWidgets('$platform $size exposes headings and live warnings', (
        tester,
      ) async {
        final store = Store.memory();
        addTearDown(store.close);
        final start = DateTime.utc(2026, 11, 1, 9);
        store.savePlan(
          Plan(
            events: [const Event('event', 'Fair')],
            volunteers: [const Volunteer('v', 'Alex')],
            shifts: [
              for (final id in ['one', 'two'])
                Shift(
                  id: id,
                  eventId: 'event',
                  startUtc: start,
                  endUtc: start.add(const Duration(hours: 1)),
                  startOffsetMinutes: 0,
                  endOffsetMinutes: 0,
                  requiredHelpers: 2,
                ),
            ],
            assignments: [
              const Assignment('one', 'v'),
              const Assignment('two', 'v'),
            ],
          ),
        );
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          ShiftSlateApp(platform: platform, store: store),
        );
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.header == true &&
                widget.child is Text &&
                (widget.child as Text).data == 'Events',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.header == true &&
                widget.child is Text &&
                (widget.child as Text).data == 'Volunteers',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.liveRegion == true &&
                widget.child is Text &&
                (widget.child as Text).data!.startsWith('Coverage'),
          ),
          findsNWidgets(3),
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.liveRegion == true &&
                widget.child is Text &&
                (widget.child as Text).data!.startsWith(
                  'Schedule conflict: Alex',
                ),
          ),
          findsOneWidget,
        );
      });
    }
  }

  testWidgets('Windows keyboard tabs to primary action and opens form', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ShiftSlateApp(platform: TargetPlatform.windows),
    );
    await tester.pumpAndSettle();
    final action = find.text('Add event');
    for (var i = 0; i < 10 && !Focus.of(tester.element(action)).hasFocus; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(Focus.of(tester.element(action)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Add event'), findsWidgets);
    expect(find.text('Save'), findsOneWidget);
  });
}
