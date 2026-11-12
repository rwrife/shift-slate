import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_slate/main.dart';
import 'package:shift_slate/planning.dart';
import 'package:shift_slate/store.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1100, 800)]) {
    testWidgets('Windows $size mouse assigns and records attendance', (
      tester,
    ) async {
      final store = Store.memory();
      addTearDown(store.close);
      final start = DateTime.utc(2026, 11, 1, 9);
      store.savePlan(
        Plan(
          events: [const Event('fair', 'Fair')],
          volunteers: [const Volunteer('alex', 'Alex')],
          shifts: [
            Shift(
              id: 'setup',
              eventId: 'fair',
              startUtc: start,
              endUtc: start.add(const Duration(hours: 1)),
              startOffsetMinutes: 0,
              endOffsetMinutes: 0,
              requiredHelpers: 1,
            ),
          ],
          assignments: [],
        ),
      );
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ShiftSlateApp(platform: TargetPlatform.windows, store: store),
      );
      await tester.pumpAndSettle();
      expect(find.text('Coverage: 0 assigned · 1 needed'), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      final assign = find.text('Assign Alex setup');
      await tester.ensureVisible(assign);
      await mouse.addPointer(location: tester.getCenter(assign));
      await tester.pumpAndSettle();
      expect(
        tester.binding.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
      await mouse.down(tester.getCenter(assign));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(store.loadPlan().assignments, hasLength(1));
      expect(find.text('Coverage: 1 assigned · 0 needed'), findsOneWidget);

      final attend = find.text('Mark attended Alex setup');
      await tester.ensureVisible(attend);
      await mouse.moveTo(tester.getCenter(attend));
      await tester.pumpAndSettle();
      expect(
        tester.binding.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
      await mouse.down(tester.getCenter(attend));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(store.loadPlan().assignments.single.attended, isTrue);
      expect(find.text('Attended Alex setup'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
