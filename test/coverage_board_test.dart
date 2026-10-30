import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart' as material;
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
    testWidgets('coverage, conflict and attendance persist on $platform', (
      tester,
    ) async {
      final store = Store.memory();
      addTearDown(store.close);
      final start = DateTime.utc(2026, 10, 30, 9);
      store.savePlan(
        Plan(
          events: [const Event('event', 'Fair')],
          volunteers: [const Volunteer('v', 'Alex')],
          shifts: [
            Shift(
              id: 's1',
              eventId: 'event',
              startUtc: start,
              endUtc: start.add(const Duration(hours: 2)),
              startOffsetMinutes: 0,
              endOffsetMinutes: 0,
              requiredHelpers: 2,
            ),
            Shift(
              id: 's2',
              eventId: 'event',
              startUtc: start.add(const Duration(hours: 1)),
              endUtc: start.add(const Duration(hours: 3)),
              startOffsetMinutes: 0,
              endOffsetMinutes: 0,
              requiredHelpers: 1,
            ),
          ],
          assignments: [
            const Assignment('s1', 'v'),
            const Assignment('s2', 'v'),
          ],
        ),
      );
      await tester.pumpWidget(ShiftSlateApp(platform: platform, store: store));
      await tester.pumpAndSettle();
      expect(find.text('Coverage: 2 assigned · 1 needed'), findsOneWidget);
      expect(find.text('Coverage 1/2 · 1 needed · 0 extra'), findsOneWidget);
      expect(find.textContaining('Schedule conflict: Alex'), findsOneWidget);
      switch (platform) {
        case TargetPlatform.iOS:
          expect(find.byType(cupertino.CupertinoApp), findsOneWidget);
          expect(find.byType(material.MaterialApp), findsNothing);
        case TargetPlatform.windows:
          expect(find.byType(fluent.FluentApp), findsOneWidget);
          expect(find.byType(material.MaterialApp), findsNothing);
        default:
          expect(find.byType(material.MaterialApp), findsOneWidget);
      }
      final mark = find.text('Mark attended Alex s1');
      await tester.ensureVisible(mark);
      await tester.tap(mark);
      await tester.pumpAndSettle();
      expect(find.text('Attended Alex s1'), findsOneWidget);
      expect(store.loadPlan().assignments.first.attended, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(ShiftSlateApp(platform: platform, store: store));
      await tester.pumpAndSettle();
      expect(find.text('Attended Alex s1'), findsOneWidget);
    });
  }

  testWidgets('desktop board has two panes; compact board stacks', (
    tester,
  ) async {
    final store = Store.memory();
    addTearDown(store.close);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1100, 800);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ShiftSlateApp(platform: TargetPlatform.windows, store: store),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Events')).dy,
      tester.getTopLeft(find.text('Volunteers')).dy,
    );
    tester.view.physicalSize = const Size(390, 800);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Volunteers')).dy,
      greaterThan(tester.getTopLeft(find.text('Events')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
