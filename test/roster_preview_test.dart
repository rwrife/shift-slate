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
    testWidgets('$platform preview warns before export and excludes notes', (
      tester,
    ) async {
      final store = Store.memory();
      addTearDown(store.close);
      store.savePlan(
        Plan(
          events: [const Event('e', 'Community Fair')],
          volunteers: [
            const Volunteer('v', 'Alex', contactNote: 'PRIVATE NOTE'),
          ],
          shifts: [
            Shift(
              id: 's',
              eventId: 'e',
              startUtc: DateTime.utc(2026, 11, 10),
              endUtc: DateTime.utc(2026, 11, 10, 1),
              startOffsetMinutes: 0,
              endOffsetMinutes: 0,
              requiredHelpers: 1,
            ),
          ],
          assignments: [const Assignment('s', 'v')],
        ),
      );
      await tester.pumpWidget(ShiftSlateApp(platform: platform, store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export roster'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Export contains volunteer names and attendance'),
        findsOneWidget,
      );
      expect(find.textContaining('Community Fair'), findsWidgets);
      expect(find.textContaining('PRIVATE NOTE'), findsNothing);
      expect(find.text('Export CSV'), findsOneWidget);
      if (platform == TargetPlatform.iOS) {
        expect(find.byType(cupertino.CupertinoAlertDialog), findsOneWidget);
      } else if (platform == TargetPlatform.android) {
        expect(find.byType(material.AlertDialog), findsOneWidget);
      }
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Export CSV'), findsNothing);
      expect(store.loadPlan().volunteers.single.contactNote, 'PRIVATE NOTE');
      expect(tester.takeException(), isNull);
    });
  }
}
