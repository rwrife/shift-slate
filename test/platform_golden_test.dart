import 'dart:io';

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
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    for (final (name, size) in [
      ('phone', const Size(390, 844)),
      ('tablet', const Size(820, 900)),
      ('desktop', const Size(1200, 800)),
    ]) {
      testWidgets('$platform $name adaptive coverage golden', (tester) async {
        final store = Store.memory();
        addTearDown(store.close);
        final start = DateTime.utc(2026, 11, 1, 9);
        store.savePlan(
          Plan(
            events: [const Event('fair', 'Community fair')],
            volunteers: [const Volunteer('alex', 'Alex')],
            shifts: [
              Shift(
                id: 'setup',
                eventId: 'fair',
                startUtc: start,
                endUtc: start.add(const Duration(hours: 2)),
                startOffsetMinutes: 0,
                endOffsetMinutes: 0,
                requiredHelpers: 2,
              ),
            ],
            assignments: [const Assignment('setup', 'alex')],
          ),
        );
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          RepaintBoundary(
            child: ShiftSlateApp(platform: platform, store: store),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Coverage: 1 assigned · 1 needed'), findsOneWidget);
        expect(tester.takeException(), isNull);
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
        final eventY = tester.getTopLeft(find.text('Events')).dy;
        final volunteerY = tester.getTopLeft(find.text('Volunteers')).dy;
        if (size.width >= 700) {
          expect(volunteerY, eventY);
        } else {
          expect(volunteerY, greaterThan(eventY));
        }
        // Linux engine rasterizes checked-in goldens; Windows still checks
        // shell, geometry, coverage and render exceptions above.
        if (Platform.isLinux) {
          await expectLater(
            find.byType(RepaintBoundary).first,
            matchesGoldenFile('goldens/${platform.name}_$name.png'),
          );
        }
      });
    }

    testWidgets('$platform large text keeps primary actions usable', (
      tester,
    ) async {
      final store = Store.memory();
      addTearDown(store.close);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.platformDispatcher.textScaleFactorTestValue = 3.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(ShiftSlateApp(platform: platform, store: store));
      await tester.pumpAndSettle();
      expect(find.text('Add event'), findsOneWidget);
      expect(find.text('Add volunteer'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Add volunteer'));
      await tester.tap(find.text('Add volunteer'));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
