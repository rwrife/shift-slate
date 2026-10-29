import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_slate/main.dart';
import 'package:shift_slate/planning.dart';
import 'package:shift_slate/store.dart';

void main() {
  testWidgets('adds event and volunteer then assigns and flags conflict', (
    tester,
  ) async {
    final store = Store.memory();
    addTearDown(store.close);

    await tester.pumpWidget(
      ShiftSlateApp(platform: TargetPlatform.android, store: store),
    );
    await tester.pumpAndSettle();

    // 1. Add event
    await tester.tap(find.text('Add event'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(material.TextField).first,
      'Spring Fair',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Spring Fair'), findsOneWidget);

    // 2. Add volunteer with private contact note
    await tester.tap(find.text('Add volunteer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(material.TextField).at(0), 'Alex');
    await tester.enterText(
      find.byType(material.TextField).at(1),
      'alex@example.com (private)',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);

    // 3. Add first shift
    await tester.tap(find.text('Add shift to Spring Fair'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(material.TextField).at(0),
      '2026-10-29T09:00:00-07:00',
    );
    await tester.enterText(
      find.byType(material.TextField).at(1),
      '2026-10-29T11:00:00-07:00',
    );
    await tester.enterText(find.byType(material.TextField).at(2), '2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // 4. Assign Alex to shift
    final assignButton = find.textContaining('Assign Alex');
    expect(assignButton, findsOneWidget);
    await tester.tap(assignButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Unassign Alex'), findsOneWidget);

    // 5. Add overlapping shift
    await tester.tap(find.text('Add shift to Spring Fair'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(material.TextField).at(0),
      '2026-10-29T10:00:00-07:00',
    );
    await tester.enterText(
      find.byType(material.TextField).at(1),
      '2026-10-29T12:00:00-07:00',
    );
    await tester.enterText(find.byType(material.TextField).at(2), '1');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // 6. Assign Alex to overlapping shift -> triggers visible conflict banner
    final secondAssign = find.textContaining('Assign Alex');
    expect(secondAssign, findsOneWidget);
    await tester.ensureVisible(secondAssign);
    await tester.pumpAndSettle();
    await tester.tap(secondAssign);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Schedule conflict: Alex has overlapping shifts.'),
      findsOneWidget,
    );

    // 7. Restart simulation from same persisted store
    await tester.pumpWidget(
      ShiftSlateApp(platform: TargetPlatform.iOS, store: store),
    );
    await tester.pumpAndSettle();
    expect(find.text('Spring Fair'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(
      find.textContaining('Schedule conflict: Alex has overlapping shifts.'),
      findsOneWidget,
    );

    // Verify contact note is preserved in store
    final reloaded = store.loadPlan();
    expect(reloaded.volunteers.first.contactNote, 'alex@example.com (private)');
  });
}
