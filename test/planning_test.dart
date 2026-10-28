import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_slate/planning.dart';
import 'package:shift_slate/store.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final event = Event('fair', 'School fair');
  final volunteer = Volunteer('amy', 'Amy', contactNote: 'private');
  Shift shift(
    String id,
    String start,
    String end, {
    int required = 1,
    int startOffset = 0,
    int endOffset = 0,
  }) => Shift(
    id: id,
    eventId: event.id,
    startUtc: DateTime.parse(start),
    endUtc: DateTime.parse(end),
    startOffsetMinutes: startOffset,
    endOffsetMinutes: endOffset,
    requiredHelpers: required,
  );
  Plan plan(List<Shift> shifts, List<Assignment> assignments) => Plan(
    events: [event],
    volunteers: [volunteer, const Volunteer('ben', 'Ben')],
    shifts: shifts,
    assignments: assignments,
  );

  test('zero, underfill, overfill and duplicate assignment', () {
    final zero = shift(
      'zero',
      '2026-11-01T00:00:00Z',
      '2026-11-01T01:00:00Z',
      required: 0,
    );
    final one = shift(
      'one',
      '2026-11-01T01:00:00Z',
      '2026-11-01T02:00:00Z',
      required: 1,
    );
    final p = plan(
      [zero, one],
      [
        const Assignment('zero', 'amy'),
        const Assignment('one', 'amy'),
        const Assignment('one', 'ben'),
      ],
    );
    expect(
      [
        p.coverage(zero).filled,
        p.coverage(zero).missing,
        p.coverage(zero).extra,
      ],
      [1, 0, 1],
    );
    expect(
      [p.coverage(one).filled, p.coverage(one).missing, p.coverage(one).extra],
      [2, 0, 1],
    );
    expect(plan([one], []).coverage(one).missing, 1);
    expect(
      () => plan(
        [one],
        [const Assignment('one', 'amy'), const Assignment('one', 'amy')],
      ),
      throwsArgumentError,
    );
  });

  test(
    'midnight overlap uses UTC instants; adjacent slots do not conflict',
    () {
      final a = shift('a', '2026-10-31T23:30:00Z', '2026-11-01T00:30:00Z');
      final b = shift('b', '2026-11-01T00:00:00Z', '2026-11-01T01:00:00Z');
      final c = shift('c', '2026-11-01T00:30:00Z', '2026-11-01T02:00:00Z');
      final p = plan(
        [a, b, c],
        [
          const Assignment('a', 'amy'),
          const Assignment('b', 'amy'),
          const Assignment('c', 'amy'),
        ],
      );
      expect(
        p.conflicts.map((c) => '${c.firstShiftId}-${c.secondShiftId}').toList(),
        ['a-b', 'b-c'],
      );
    },
  );

  test(
    'DST fall-back fold records differing offsets without collapsing instants',
    () {
      final before = shift(
        'before',
        '2026-11-01T05:30:00Z',
        '2026-11-01T06:30:00Z',
        startOffset: -240,
        endOffset: -300,
      );
      final after = shift(
        'after',
        '2026-11-01T06:00:00Z',
        '2026-11-01T07:00:00Z',
        startOffset: -300,
        endOffset: -300,
      );
      expect(before.localStart.hour, 1);
      expect(before.localEnd.hour, 1);
      expect(after.localStart.hour, 1);
      expect(
        plan(
          [before, after],
          [const Assignment('before', 'amy'), const Assignment('after', 'amy')],
        ).conflicts,
        hasLength(1),
      );
      expect(
        () => shift('bad', '2026-11-01T07:00:00Z', '2026-11-01T06:00:00Z'),
        throwsArgumentError,
      );
    },
  );

  test('database reload and v1 migration preserve roster', () {
    final directory = Directory.systemTemp.createTempSync('shift-slate-test-');
    final path = '${directory.path}/roster.db';
    try {
      final db = sqlite3.open(path);
      db.execute('''
CREATE TABLE events (id TEXT PRIMARY KEY, name TEXT NOT NULL);
CREATE TABLE volunteers (id TEXT PRIMARY KEY, name TEXT NOT NULL, contact_note TEXT NOT NULL DEFAULT '');
CREATE TABLE shifts (id TEXT PRIMARY KEY, event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE, start_utc INTEGER NOT NULL, end_utc INTEGER NOT NULL, start_offset_minutes INTEGER NOT NULL, end_offset_minutes INTEGER NOT NULL, required_helpers INTEGER NOT NULL);
CREATE TABLE assignments (shift_id TEXT NOT NULL REFERENCES shifts(id) ON DELETE CASCADE, volunteer_id TEXT NOT NULL REFERENCES volunteers(id) ON DELETE CASCADE, PRIMARY KEY (shift_id, volunteer_id));
PRAGMA user_version = 1;
INSERT INTO events VALUES ('fair', 'Old fair');
INSERT INTO volunteers VALUES ('amy', 'Amy', 'private');
INSERT INTO shifts VALUES ('old', 'fair', 1793511000000, 1793514600000, -240, -300, 1);
INSERT INTO assignments VALUES ('old', 'amy');
''');
      db.close();
      final migrated = Store.open(path);
      expect(migrated.db.select('PRAGMA user_version;').first.values.first, 2);
      expect(migrated.loadPlan().assignments.single.attended, false);
      expect(migrated.loadPlan().volunteers.first.contactNote, 'private');
      migrated.savePlan(
        plan(
          [
            shift(
              'new',
              '2026-11-01T05:30:00Z',
              '2026-11-01T06:30:00Z',
              startOffset: -240,
              endOffset: -300,
            ),
          ],
          [const Assignment('new', 'amy', attended: true)],
        ),
      );
      migrated.close();
      final reopened = Store.open(path);
      final loaded = reopened.loadPlan();
      expect(loaded.events.single.name, 'School fair');
      expect(loaded.assignments.single.attended, true);
      expect(loaded.shifts.single.endOffsetMinutes, -300);
      expect(loaded.volunteers.first.contactNote, 'private');
      reopened.close();
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('invalid replacement rolls back without losing stored roster', () {
    final store = Store.memory();
    final original = plan(
      [shift('one', '2026-11-01T01:00:00Z', '2026-11-01T02:00:00Z')],
      [const Assignment('one', 'amy')],
    );
    store.savePlan(original);
    store.db.execute('''
CREATE TRIGGER reject_new BEFORE INSERT ON events
WHEN NEW.id = 'blocked' BEGIN SELECT RAISE(ABORT, 'rejected'); END;
''');
    expect(
      () => store.savePlan(
        Plan(
          events: [const Event('blocked', 'Blocked')],
          volunteers: [],
          shifts: [],
          assignments: [],
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
    expect(store.loadPlan().events.single.name, 'School fair');
    expect(store.loadPlan().assignments.single.volunteerId, 'amy');
    store.close();
  });

  test('submillisecond boundaries reject before persistence', () {
    expect(
      () => shift(
        'too-fine',
        '2026-11-01T01:00:00.000100Z',
        '2026-11-01T01:00:00.000900Z',
      ),
      throwsArgumentError,
    );
  });

  test('future database version fails closed', () {
    final db = sqlite3.openInMemory();
    db.execute('PRAGMA user_version = 3;');
    expect(() => Store.from(db), throwsStateError);
    db.close();
  });
}
