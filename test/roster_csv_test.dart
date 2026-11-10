import 'package:flutter_test/flutter_test.dart';
import 'package:shift_slate/planning.dart';
import 'package:shift_slate/roster_csv.dart';

void main() {
  test('CSV escapes names, blocks formulas, excludes notes and shows gaps', () {
    final start = DateTime.utc(2026, 11, 10, 9);
    final plan = Plan(
      events: [const Event('fair', 'Fair,"open"\nnow')],
      volunteers: [
        const Volunteer('a', ' =HYPERLINK("bad")', contactNote: 'SECRET'),
        const Volunteer('b', '\t@command'),
      ],
      shifts: [
        Shift(
          id: 's1',
          eventId: 'fair',
          startUtc: start,
          endUtc: start.add(const Duration(hours: 1)),
          startOffsetMinutes: -420,
          endOffsetMinutes: -420,
          requiredHelpers: 3,
        ),
        Shift(
          id: 's2',
          eventId: 'fair',
          startUtc: start,
          endUtc: start.add(const Duration(hours: 1)),
          startOffsetMinutes: 0,
          endOffsetMinutes: 0,
          requiredHelpers: 1,
        ),
      ],
      assignments: [
        const Assignment('s1', 'a', attended: true),
        const Assignment('s1', 'b'),
      ],
    );
    final csv = rosterCsv(plan);
    expect(csv.startsWith('\uFEFF"Event",'), isTrue);
    expect(csv.contains('"Fair,""open""\nnow"'), isTrue);
    expect(csv.contains('"\' =HYPERLINK(""bad"")"'), isTrue);
    expect(csv.contains('"\'\t@command"'), isTrue);
    expect(csv.contains('"2026-11-10 02:00 -07:00"'), isTrue);
    expect(csv.contains('"3","2","1"'), isTrue);
    expect(csv.contains('"1","0","1","",""'), isTrue);
    expect(csv.contains('"Yes"\r\n'), isTrue);
    expect(csv.contains('SECRET'), isFalse);
    expect(csv.split('\r\n'), hasLength(5));
  });

  test('covers every formula prefix after whitespace, but not safe text', () {
    final plan = Plan(
      events: [const Event('e', ' =sum(1)')],
      volunteers: const [],
      shifts: [],
      assignments: [],
    );
    expect(rosterCsv(plan).contains('=sum'), isFalse); // no shifts
    for (final name in ['=2+2', ' +2+2', '\t-2+2', '\n@cmd', 'ordinary']) {
      final shift = Shift(
        id: 's',
        eventId: 'e',
        startUtc: DateTime.utc(2026, 1, 1),
        endUtc: DateTime.utc(2026, 1, 1, 1),
        startOffsetMinutes: 0,
        endOffsetMinutes: 0,
        requiredHelpers: 1,
      );
      final csv = rosterCsv(
        Plan(
          events: [Event('e', name)],
          volunteers: const [],
          shifts: [shift],
          assignments: const [],
        ),
      );
      expect(csv.contains('"${name == 'ordinary' ? '' : "'"}$name"'), isTrue);
    }
  });
}
