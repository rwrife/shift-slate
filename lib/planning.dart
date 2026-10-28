/// Shift boundaries are UTC instants; offsets record how each boundary was
/// displayed locally. Callers must supply offsets from the event's time zone.
/// This preserves DST folds/gaps without guessing from the device time zone.
class Event {
  const Event(this.id, this.name);
  final String id;
  final String name;
}

class Volunteer {
  const Volunteer(this.id, this.name, {this.contactNote = ''});
  final String id;
  final String name;
  final String contactNote;
}

class Shift {
  Shift({
    required this.id,
    required this.eventId,
    required this.startUtc,
    required this.endUtc,
    required this.startOffsetMinutes,
    required this.endOffsetMinutes,
    required this.requiredHelpers,
  }) {
    if (!startUtc.isUtc ||
        !endUtc.isUtc ||
        !endUtc.isAfter(startUtc) ||
        startUtc.microsecond != 0 ||
        endUtc.microsecond != 0) {
      // ponytail: SQLite stores millisecond epochs; reject finer precision
      // until schema adds microsecond columns rather than silently truncate.
      throw ArgumentError('Shift needs ordered UTC millisecond boundaries');
    }
    if (requiredHelpers < 0 ||
        startOffsetMinutes.abs() > 14 * 60 ||
        endOffsetMinutes.abs() > 14 * 60) {
      throw ArgumentError('Invalid helper count or UTC offset');
    }
  }

  final String id;
  final String eventId;
  final DateTime startUtc;
  final DateTime endUtc;
  final int startOffsetMinutes;
  final int endOffsetMinutes;
  final int requiredHelpers;

  DateTime get localStart =>
      startUtc.add(Duration(minutes: startOffsetMinutes));
  DateTime get localEnd => endUtc.add(Duration(minutes: endOffsetMinutes));
}

class Assignment {
  const Assignment(this.shiftId, this.volunteerId, {this.attended = false});
  final String shiftId;
  final String volunteerId;
  final bool attended;
}

class Coverage {
  const Coverage(this.filled, this.missing, this.extra);
  final int filled;
  final int missing;
  final int extra;
}

class Conflict {
  const Conflict(this.volunteerId, this.firstShiftId, this.secondShiftId);
  final String volunteerId;
  final String firstShiftId;
  final String secondShiftId;
}

class Plan {
  Plan({
    required List<Event> events,
    required List<Volunteer> volunteers,
    required List<Shift> shifts,
    required List<Assignment> assignments,
  }) : events = List.unmodifiable(events),
       volunteers = List.unmodifiable(volunteers),
       shifts = List.unmodifiable(shifts),
       assignments = List.unmodifiable(assignments) {
    final eventIds = events.map((e) => e.id).toSet();
    final volunteerIds = volunteers.map((v) => v.id).toSet();
    final shiftIds = shifts.map((s) => s.id).toSet();
    if (eventIds.length != events.length ||
        volunteerIds.length != volunteers.length ||
        shiftIds.length != shifts.length ||
        events.any((e) => e.id.isEmpty || e.name.trim().isEmpty) ||
        volunteers.any((v) => v.id.isEmpty || v.name.trim().isEmpty) ||
        shifts.any((s) => s.id.isEmpty || !eventIds.contains(s.eventId))) {
      throw ArgumentError('Invalid or duplicate plan records');
    }
    final keys = <(String, String)>{};
    for (final assignment in assignments) {
      if (!shiftIds.contains(assignment.shiftId) ||
          !volunteerIds.contains(assignment.volunteerId) ||
          !keys.add((assignment.shiftId, assignment.volunteerId))) {
        throw ArgumentError('Invalid or duplicate assignment');
      }
    }
  }

  final List<Event> events;
  final List<Volunteer> volunteers;
  final List<Shift> shifts;
  final List<Assignment> assignments;

  Coverage coverage(Shift shift) {
    final filled = assignments.where((a) => a.shiftId == shift.id).length;
    return Coverage(
      filled,
      (shift.requiredHelpers - filled).clamp(0, shift.requiredHelpers),
      (filled - shift.requiredHelpers).clamp(0, filled),
    );
  }

  List<Conflict> get conflicts {
    final byId = {for (final shift in shifts) shift.id: shift};
    final result = <Conflict>[];
    for (var i = 0; i < assignments.length; i++) {
      for (var j = i + 1; j < assignments.length; j++) {
        final a = assignments[i];
        final b = assignments[j];
        if (a.volunteerId != b.volunteerId) continue;
        final first = byId[a.shiftId]!;
        final second = byId[b.shiftId]!;
        if (first.startUtc.isBefore(second.endUtc) &&
            second.startUtc.isBefore(first.endUtc)) {
          result.add(Conflict(a.volunteerId, first.id, second.id));
        }
      }
    }
    return result;
  }
}
