import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_slate/main.dart';
import 'package:shift_slate/planning.dart';
import 'package:shift_slate/store.dart';

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    for (final size in [
      const Size(390, 844),
      const Size(820, 900),
      const Size(1200, 800),
    ]) {
      testWidgets('$platform $size high contrast keeps board operable', (
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
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(highContrast: true);
        tester.view.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.view.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        addTearDown(
          tester.view.platformDispatcher.clearTextScaleFactorTestValue,
        );
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          ShiftSlateApp(platform: platform, store: store),
        );
        await tester.pumpAndSettle();
        expect(
          MediaQuery.of(tester.element(find.text('Events'))).highContrast,
          isTrue,
        );
        switch (platform) {
          case TargetPlatform.iOS:
            expect(find.byType(cupertino.CupertinoApp), findsOneWidget);
            expect(find.byType(material.MaterialApp), findsNothing);
          case TargetPlatform.windows:
            expect(find.byType(fluent.FluentApp), findsOneWidget);
            expect(find.byType(material.MaterialApp), findsNothing);
          default:
            expect(find.byType(material.MaterialApp), findsOneWidget);
            expect(find.byType(cupertino.CupertinoApp), findsNothing);
        }
        expect(find.text('Coverage: 0 assigned · 1 needed'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final assign = find.text('Assign Alex s1');
        await tester.ensureVisible(assign);
        final assignNode = tester.getSemantics(assign);
        expect(
          assignNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        tester.semantics.tap(
          find.semantics.byPredicate((node) => identical(node, assignNode)),
        );
        await tester.pumpAndSettle();
        expect(store.loadPlan().assignments, hasLength(1));
        expect(find.text('Coverage: 1 assigned · 0 needed'), findsOneWidget);
        final attend = find.text('Mark attended Alex s1');
        await tester.ensureVisible(attend);
        final attendNode = tester.getSemantics(attend);
        expect(
          attendNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        tester.semantics.tap(
          find.semantics.byPredicate((node) => identical(node, attendNode)),
        );
        await tester.pumpAndSettle();
        expect(store.loadPlan().assignments.single.attended, isTrue);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
}
