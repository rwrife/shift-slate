import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import 'planning.dart';

/// Schema version 1: events, volunteers, shifts, assignments.
/// Version 2: attendance flag on assignments.
class Store {
  Store._(this.db);

  final CommonDatabase db;

  static const currentVersion = 2;

  factory Store.open([String path = 'shift_slate.db']) =>
      Store.from(sqlite3.open(path));

  factory Store.memory() => Store.from(sqlite3.openInMemory());

  factory Store.from(CommonDatabase db) {
    db.execute('PRAGMA foreign_keys = ON;');
    _migrate(db);
    return Store._(db);
  }

  static void _migrate(CommonDatabase db) {
    final version = db.select('PRAGMA user_version;').first.values.first as int;
    if (version < 0 || version > currentVersion) {
      throw StateError('Unsupported database version $version');
    }
    if (version == currentVersion) return;
    db.execute('BEGIN TRANSACTION;');
    try {
      if (version < 1) {
        db.execute('''
CREATE TABLE events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL
);
CREATE TABLE volunteers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  contact_note TEXT NOT NULL DEFAULT ''
);
CREATE TABLE shifts (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  start_utc INTEGER NOT NULL,
  end_utc INTEGER NOT NULL,
  start_offset_minutes INTEGER NOT NULL,
  end_offset_minutes INTEGER NOT NULL,
  required_helpers INTEGER NOT NULL
);
CREATE TABLE assignments (
  shift_id TEXT NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
  volunteer_id TEXT NOT NULL REFERENCES volunteers(id) ON DELETE CASCADE,
  PRIMARY KEY (shift_id, volunteer_id)
);
''');
      }
      if (version < 2) {
        db.execute(
          'ALTER TABLE assignments ADD COLUMN attended INTEGER NOT NULL DEFAULT 0;',
        );
      }
      db.execute('PRAGMA user_version = $currentVersion;');
      db.execute('COMMIT;');
    } catch (_) {
      db.execute('ROLLBACK;');
      rethrow;
    }
  }

  void savePlan(Plan plan) {
    db.execute('BEGIN TRANSACTION;');
    try {
      db.execute('DELETE FROM assignments;');
      db.execute('DELETE FROM shifts;');
      db.execute('DELETE FROM volunteers;');
      db.execute('DELETE FROM events;');

      final insertEvent = db.prepare(
        'INSERT INTO events (id, name) VALUES (?, ?);',
      );
      for (final event in plan.events) {
        insertEvent.execute([event.id, event.name]);
      }
      insertEvent.close();

      final insertVolunteer = db.prepare(
        'INSERT INTO volunteers (id, name, contact_note) VALUES (?, ?, ?);',
      );
      for (final volunteer in plan.volunteers) {
        insertVolunteer.execute([
          volunteer.id,
          volunteer.name,
          volunteer.contactNote,
        ]);
      }
      insertVolunteer.close();

      final insertShift = db.prepare('''
INSERT INTO shifts (
  id, event_id, start_utc, end_utc, start_offset_minutes, end_offset_minutes, required_helpers
) VALUES (?, ?, ?, ?, ?, ?, ?);
''');
      for (final shift in plan.shifts) {
        insertShift.execute([
          shift.id,
          shift.eventId,
          shift.startUtc.millisecondsSinceEpoch,
          shift.endUtc.millisecondsSinceEpoch,
          shift.startOffsetMinutes,
          shift.endOffsetMinutes,
          shift.requiredHelpers,
        ]);
      }
      insertShift.close();

      final insertAssignment = db.prepare(
        'INSERT INTO assignments (shift_id, volunteer_id, attended) VALUES (?, ?, ?);',
      );
      for (final assignment in plan.assignments) {
        insertAssignment.execute([
          assignment.shiftId,
          assignment.volunteerId,
          assignment.attended ? 1 : 0,
        ]);
      }
      insertAssignment.close();

      db.execute('COMMIT;');
    } catch (_) {
      db.execute('ROLLBACK;');
      rethrow;
    }
  }

  Plan loadPlan() {
    final events = db
        .select('SELECT id, name FROM events;')
        .map((r) => Event(r['id'] as String, r['name'] as String))
        .toList();

    final volunteers = db
        .select('SELECT id, name, contact_note FROM volunteers;')
        .map(
          (r) => Volunteer(
            r['id'] as String,
            r['name'] as String,
            contactNote: (r['contact_note'] as String?) ?? '',
          ),
        )
        .toList();

    final shifts = db
        .select('''
SELECT id, event_id, start_utc, end_utc, start_offset_minutes, end_offset_minutes, required_helpers
FROM shifts;
''')
        .map(
          (r) => Shift(
            id: r['id'] as String,
            eventId: r['event_id'] as String,
            startUtc: DateTime.fromMillisecondsSinceEpoch(
              r['start_utc'] as int,
              isUtc: true,
            ),
            endUtc: DateTime.fromMillisecondsSinceEpoch(
              r['end_utc'] as int,
              isUtc: true,
            ),
            startOffsetMinutes: r['start_offset_minutes'] as int,
            endOffsetMinutes: r['end_offset_minutes'] as int,
            requiredHelpers: r['required_helpers'] as int,
          ),
        )
        .toList();

    final assignments = db
        .select('SELECT shift_id, volunteer_id, attended FROM assignments;')
        .map(
          (r) => Assignment(
            r['shift_id'] as String,
            r['volunteer_id'] as String,
            attended: (r['attended'] as int) == 1,
          ),
        )
        .toList();

    return Plan(
      events: events,
      volunteers: volunteers,
      shifts: shifts,
      assignments: assignments,
    );
  }

  void close() => db.close();
}
