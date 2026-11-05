import 'package:flutter/rendering.dart';
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

  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform semantic tap toggles assignment and attendance', (
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
            Shift(
              id: 's1',
              eventId: 'event',
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
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(ShiftSlateApp(platform: platform, store: store));
      await tester.pumpAndSettle();

      final assignFinder = find.text('Assign Alex s1');
      expect(assignFinder, findsOneWidget);
      await tester.ensureVisible(assignFinder);
      final assignNode = tester.getSemantics(assignFinder);
      expect(
        assignNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.tap(
        find.semantics.byPredicate((node) => identical(node, assignNode)),
      );
      await tester.pumpAndSettle();

      final unassignFinder = find.text('Unassign Alex s1');
      expect(unassignFinder, findsOneWidget);
      final attendFinder = find.text('Mark attended Alex s1');
      expect(attendFinder, findsOneWidget);
      expect(store.loadPlan().assignments, hasLength(1));
      expect(store.loadPlan().assignments.first.attended, isFalse);
      expect(find.text('Coverage: 1 assigned · 0 needed'), findsOneWidget);
      expect(find.text('Coverage 1/1 · 0 needed · 0 extra'), findsOneWidget);

      await tester.ensureVisible(attendFinder);
      final attendNode = tester.getSemantics(attendFinder);
      expect(
        attendNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.tap(
        find.semantics.byPredicate((node) => identical(node, attendNode)),
      );
      await tester.pumpAndSettle();

      final attendedFinder = find.text('Attended Alex s1');
      expect(attendedFinder, findsOneWidget);
      expect(store.loadPlan().assignments.first.attended, isTrue);

      await tester.ensureVisible(attendedFinder);
      final attendedNode = tester.getSemantics(attendedFinder);
      tester.semantics.tap(
        find.semantics.byPredicate((node) => identical(node, attendedNode)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark attended Alex s1'), findsOneWidget);
      expect(store.loadPlan().assignments.first.attended, isFalse);
      final unassignNode = tester.getSemantics(unassignFinder);
      expect(
        unassignNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      tester.semantics.tap(
        find.semantics.byPredicate((node) => identical(node, unassignNode)),
      );
      await tester.pumpAndSettle();
      expect(store.loadPlan().assignments, isEmpty);
      expect(find.text('Coverage: 0 assigned · 1 needed'), findsOneWidget);
      handle.dispose();
    });
  }

  testWidgets('Windows keyboard activates assignment and attendance', (
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
          Shift(
            id: 's1',
            eventId: 'event',
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
    await tester.pumpWidget(
      ShiftSlateApp(platform: TargetPlatform.windows, store: store),
    );
    await tester.pumpAndSettle();

    final assignAction = find.text('Assign Alex s1');
    for (
      var i = 0;
      i < 20 && !Focus.of(tester.element(assignAction)).hasFocus;
      i++
    ) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(Focus.of(tester.element(assignAction)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Unassign Alex s1'), findsOneWidget);
    expect(find.text('Mark attended Alex s1'), findsOneWidget);
    expect(store.loadPlan().assignments, hasLength(1));

    final attendAction = find.text('Mark attended Alex s1');
    for (
      var i = 0;
      i < 10 && !Focus.of(tester.element(attendAction)).hasFocus;
      i++
    ) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(Focus.of(tester.element(attendAction)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(find.text('Attended Alex s1'), findsOneWidget);
    expect(store.loadPlan().assignments.first.attended, isTrue);
  });
}
