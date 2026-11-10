import 'planning.dart';

/// Roster is public-facing: never include private contact notes.
String rosterCsv(Plan plan) {
  String cell(Object value) {
    var text = '$value';
    if (RegExp(r'^[=+\-@]').hasMatch(text.trimLeft())) {
      text = "'$text";
    }
    return '"${text.replaceAll('"', '""')}"';
  }

  String row(List<Object> values) => '${values.map(cell).join(',')}\r\n';
  String time(DateTime utc, int offset) {
    final local = utc.add(Duration(minutes: offset));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)} '
        '${offset < 0 ? '-' : '+'}${two(offset.abs() ~/ 60)}:${two(offset.abs() % 60)}';
  }

  final volunteers = {for (final v in plan.volunteers) v.id: v};
  final events = {for (final e in plan.events) e.id: e};
  final out = StringBuffer('\uFEFF');
  out.write(
    row([
      'Event',
      'Start (local UTC offset)',
      'End (local UTC offset)',
      'Helpers required',
      'Helpers assigned',
      'Helpers missing',
      'Volunteer',
      'Attended',
    ]),
  );
  for (final shift in plan.shifts) {
    final assigned = plan.assignments
        .where((a) => a.shiftId == shift.id)
        .toList();
    final coverage = plan.coverage(shift);
    final prefix = <Object>[
      events[shift.eventId]!.name,
      time(shift.startUtc, shift.startOffsetMinutes),
      time(shift.endUtc, shift.endOffsetMinutes),
      shift.requiredHelpers,
      coverage.filled,
      coverage.missing,
    ];
    if (assigned.isEmpty) {
      out.write(row([...prefix, '', '']));
    } else {
      for (final assignment in assigned) {
        out.write(
          row([
            ...prefix,
            volunteers[assignment.volunteerId]!.name,
            assignment.attended ? 'Yes' : 'No',
          ]),
        );
      }
    }
  }
  return out.toString();
}
