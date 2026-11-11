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
    testWidgets(
      '$platform private backup warns and cancellation does not mutate data',
      (tester) async {
        final store = Store.memory();
        addTearDown(store.close);
        store.savePlan(
          Plan(
            events: [const Event('e', 'Community Fair')],
            volunteers: [
              const Volunteer('v', 'Alex', contactNote: 'PRIVATE NOTE'),
            ],
            shifts: [],
            assignments: [],
          ),
        );
        await tester.pumpWidget(
          ShiftSlateApp(platform: platform, store: store),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Export private backup'));
        await tester.tap(find.text('Export private backup'));
        await tester.pumpAndSettle();
        expect(find.textContaining('private contact notes'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        if (platform == TargetPlatform.iOS) {
          expect(find.byType(cupertino.CupertinoAlertDialog), findsOneWidget);
        } else if (platform == TargetPlatform.android) {
          expect(find.byType(material.AlertDialog), findsOneWidget);
        }
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Continue'), findsNothing);
        expect(store.loadPlan().volunteers.single.contactNote, 'PRIVATE NOTE');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
