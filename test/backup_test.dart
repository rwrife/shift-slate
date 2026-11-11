import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_slate/backup.dart';
import 'package:shift_slate/planning.dart';
import 'package:shift_slate/store.dart';

void main() {
  test('private notes, attendance, times and offsets round-trip', () {
    final plan = Plan(
      events: [const Event('e', 'Fair')],
      volunteers: [const Volunteer('v', 'Ada', contactNote: '555-1234')],
      shifts: [
        Shift(
          id: 's',
          eventId: 'e',
          startUtc: DateTime.utc(2026, 11, 1, 8),
          endUtc: DateTime.utc(2026, 11, 1, 9),
          startOffsetMinutes: -420,
          endOffsetMinutes: -480,
          requiredHelpers: 2,
        ),
      ],
      assignments: [const Assignment('s', 'v', attended: true)],
    );
    final encoded = encodeBackup(plan);
    final restored = decodeBackup(encoded);
    expect(restored.volunteers.single.contactNote, '555-1234');
    expect(restored.shifts.single.startOffsetMinutes, -420);
    expect(restored.shifts.single.endOffsetMinutes, -480);
    expect(restored.assignments.single.attended, isTrue);
    expect(jsonDecode(encodeBackup(restored)), jsonDecode(encoded));
  });

  test('malformed and unsupported backups never replace SQLite plan', () {
    final store = Store.memory();
    addTearDown(store.close);
    store.savePlan(
      Plan(
        events: [const Event('original', 'Keep me')],
        volunteers: [],
        shifts: [],
        assignments: [],
      ),
    );
    final valid =
        jsonDecode(encodeBackup(store.loadPlan())) as Map<String, dynamic>;
    for (final bad in [
      '{',
      '{}',
      jsonEncode({...valid, 'version': 2}),
      jsonEncode({
        ...valid,
        'events': [
          {'id': 'x', 'name': ''},
        ],
      }),
      jsonEncode({
        ...valid,
        'shifts': [
          {'id': 's'},
        ],
      }),
      jsonEncode({...valid, 'extra': 'unexpected'}),
      jsonEncode({
        ...valid,
        'events': [valid['events'][0], valid['events'][0]],
      }),
    ]) {
      expect(() => store.savePlan(decodeBackup(bad)), throwsA(isA<Object>()));
      expect(store.loadPlan().events.single.name, 'Keep me');
    }
  });
}
