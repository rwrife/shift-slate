import 'dart:convert';

import 'planning.dart';

/// Versioned local snapshot. Notes are private and included in this backup.
String encodeBackup(Plan plan) => jsonEncode({
  'version': 1,
  'events': [
    for (final e in plan.events) {'id': e.id, 'name': e.name},
  ],
  'volunteers': [
    for (final v in plan.volunteers)
      {'id': v.id, 'name': v.name, 'contactNote': v.contactNote},
  ],
  'shifts': [
    for (final s in plan.shifts)
      {
        'id': s.id,
        'eventId': s.eventId,
        'startUtc': s.startUtc.millisecondsSinceEpoch,
        'endUtc': s.endUtc.millisecondsSinceEpoch,
        'startOffsetMinutes': s.startOffsetMinutes,
        'endOffsetMinutes': s.endOffsetMinutes,
        'requiredHelpers': s.requiredHelpers,
      },
  ],
  'assignments': [
    for (final a in plan.assignments)
      {
        'shiftId': a.shiftId,
        'volunteerId': a.volunteerId,
        'attended': a.attended,
      },
  ],
});

Plan decodeBackup(String input) {
  // ponytail: 8 MiB cap; raise with streaming parser if large events need it.
  if (utf8.encode(input).length > 8 * 1024 * 1024) {
    throw const FormatException('Backup too large');
  }
  try {
    final root = _object(jsonDecode(input), {
      'version',
      'events',
      'volunteers',
      'shifts',
      'assignments',
    });
    if (root['version'] != 1 || root['version'].runtimeType != int) {
      throw const FormatException('Unsupported backup version');
    }
    List<T> rows<T>(String key, T Function(Map<String, dynamic>) parse) {
      final value = root[key];
      if (value is! List || value.length > 10000) {
        throw const FormatException('Invalid backup rows');
      }
      return [for (final row in value) parse(_object(row, null))];
    }

    return Plan(
      events: rows('events', (e) {
        _fields(e, {'id', 'name'});
        return Event(_string(e, 'id'), _string(e, 'name'));
      }),
      volunteers: rows('volunteers', (v) {
        _fields(v, {'id', 'name', 'contactNote'});
        return Volunteer(
          _string(v, 'id'),
          _string(v, 'name'),
          contactNote: _string(v, 'contactNote'),
        );
      }),
      shifts: rows('shifts', (s) {
        _fields(s, {
          'id',
          'eventId',
          'startUtc',
          'endUtc',
          'startOffsetMinutes',
          'endOffsetMinutes',
          'requiredHelpers',
        });
        return Shift(
          id: _string(s, 'id'),
          eventId: _string(s, 'eventId'),
          startUtc: DateTime.fromMillisecondsSinceEpoch(
            _integer(s, 'startUtc'),
            isUtc: true,
          ),
          endUtc: DateTime.fromMillisecondsSinceEpoch(
            _integer(s, 'endUtc'),
            isUtc: true,
          ),
          startOffsetMinutes: _integer(s, 'startOffsetMinutes'),
          endOffsetMinutes: _integer(s, 'endOffsetMinutes'),
          requiredHelpers: _integer(s, 'requiredHelpers'),
        );
      }),
      assignments: rows('assignments', (a) {
        _fields(a, {'shiftId', 'volunteerId', 'attended'});
        if (a['attended'] is! bool) {
          throw const FormatException('Invalid attendance');
        }
        return Assignment(
          _string(a, 'shiftId'),
          _string(a, 'volunteerId'),
          attended: a['attended'] as bool,
        );
      }),
    );
  } on FormatException {
    rethrow;
  } on Object catch (_) {
    throw const FormatException('Invalid backup');
  }
}

Map<String, dynamic> _object(Object? input, Set<String>? keys) {
  if (input is! Map<String, dynamic>) {
    throw const FormatException('Invalid backup object');
  }
  if (keys != null) _fields(input, keys);
  return input;
}

void _fields(Map<String, dynamic> value, Set<String> keys) {
  if (value.keys.toSet().difference(keys).isNotEmpty ||
      keys.difference(value.keys.toSet()).isNotEmpty) {
    throw const FormatException('Invalid backup fields');
  }
}

String _string(Map<String, dynamic> value, String key) {
  if (value[key] is! String) throw const FormatException('Invalid backup text');
  return value[key] as String;
}

int _integer(Map<String, dynamic> value, String key) {
  if (value[key] is! int) throw const FormatException('Invalid backup number');
  return value[key] as int;
}
