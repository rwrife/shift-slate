import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'planning.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationSupportDirectory();
  runApp(
    ShiftSlateApp(
      store: Store.open(
        '${directory.path}${Platform.pathSeparator}shift_slate.db',
      ),
    ),
  );
}

class ShiftSlateApp extends StatefulWidget {
  const ShiftSlateApp({super.key, this.platform, this.store});
  final TargetPlatform? platform;
  final Store? store;

  @override
  State<ShiftSlateApp> createState() => _ShiftSlateAppState();
}

class _ShiftSlateAppState extends State<ShiftSlateApp> {
  late final Store store;
  late Plan plan;
  int counter = 0;

  @override
  void initState() {
    super.initState();
    store = widget.store ?? Store.memory();
    plan = store.loadPlan();
  }

  @override
  void dispose() {
    if (widget.store == null) store.close();
    super.dispose();
  }

  String id() => '${DateTime.now().microsecondsSinceEpoch}-${counter++}';

  void update({
    List<Event>? events,
    List<Volunteer>? volunteers,
    List<Shift>? shifts,
    List<Assignment>? assignments,
  }) {
    final next = Plan(
      events: events ?? plan.events,
      volunteers: volunteers ?? plan.volunteers,
      shifts: shifts ?? plan.shifts,
      assignments: assignments ?? plan.assignments,
    );
    store.savePlan(next);
    setState(() => plan = next);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.platform ?? defaultTargetPlatform;
    final editor = _Editor(target: target, plan: plan, update: update, id: id);
    switch (target) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return cupertino.CupertinoApp(
          title: 'Shift Slate',
          home: cupertino.CupertinoPageScaffold(
            navigationBar: const cupertino.CupertinoNavigationBar(
              middle: cupertino.Text('Shift Slate'),
            ),
            child: cupertino.SafeArea(child: editor),
          ),
        );
      case TargetPlatform.windows:
        return fluent.FluentApp(
          title: 'Shift Slate',
          home: fluent.NavigationView(
            content: fluent.ScaffoldPage(
              header: const fluent.PageHeader(
                title: fluent.Text('Shift Slate'),
              ),
              content: editor,
            ),
          ),
        );
      case TargetPlatform.android:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return material.MaterialApp(
          title: 'Shift Slate',
          theme: material.ThemeData(useMaterial3: true),
          home: material.Scaffold(
            appBar: material.AppBar(title: const material.Text('Shift Slate')),
            body: editor,
          ),
        );
    }
  }
}

typedef UpdatePlan = void Function({
  List<Event>? events,
  List<Volunteer>? volunteers,
  List<Shift>? shifts,
  List<Assignment>? assignments,
});

class _Editor extends StatelessWidget {
  const _Editor({
    required this.target,
    required this.plan,
    required this.update,
    required this.id,
  });
  final TargetPlatform target;
  final Plan plan;
  final UpdatePlan update;
  final String Function() id;

  bool get apple =>
      target == TargetPlatform.iOS || target == TargetPlatform.macOS;
  bool get windows => target == TargetPlatform.windows;

  Widget text(String value) => apple
      ? cupertino.Text(value)
      : windows
      ? fluent.Text(value)
      : material.Text(value);
  Widget button(String label, VoidCallback action) => apple
      ? cupertino.CupertinoButton(
          onPressed: action,
          child: cupertino.Text(label),
        )
      : windows
      ? fluent.Button(onPressed: action, child: fluent.Text(label))
      : material.TextButton(onPressed: action, child: material.Text(label));
  Widget field(String label, TextEditingController controller) => apple
      ? cupertino.CupertinoTextField(controller: controller, placeholder: label)
      : windows
      ? fluent.TextBox(controller: controller, placeholder: label)
      : material.TextField(
          controller: controller,
          decoration: material.InputDecoration(labelText: label),
        );

  Future<void> form(
    BuildContext context,
    String title,
    List<Widget> fields,
    VoidCallback save,
  ) async {
    final error = ValueNotifier<String>('');
    final content = SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(title),
              const SizedBox(height: 12),
              for (final item in fields) ...[item, const SizedBox(height: 12)],
              button('Save', () {
                try {
                  save();
                  Navigator.of(context, rootNavigator: true).pop();
                } on Object catch (e) {
                  error.value = '$e';
                }
              }),
              ValueListenableBuilder<String>(
                valueListenable: error,
                builder: (_, message, _) => text(message),
              ),
            ],
          ),
        ),
      ),
    );
    if (apple) {
      await cupertino.showCupertinoDialog<void>(
        context: context,
        builder: (_) => cupertino.CupertinoAlertDialog(content: content),
      );
    } else if (windows) {
      await fluent.showDialog<void>(
        context: context,
        builder: (_) => fluent.ContentDialog(content: content),
      );
    } else {
      await material.showDialog<void>(
        context: context,
        builder: (_) => material.Dialog(child: content),
      );
    }
    // ponytail: dialog-owned controllers should be disposed by a dedicated StatefulWidget
    // when forms gain more fields; route transitions can outlive showDialog's Future.
  }

  (DateTime, int) time(String input) {
    final value = input.trim();
    final match = RegExp(r'(Z|([+-])(\d\d):(\d\d))$').firstMatch(value);
    if (match == null) {
      throw const FormatException(
        'Enter ISO time with UTC offset, e.g. 2026-10-29T09:00:00-07:00',
      );
    }
    final minutes = match.group(2) == null
        ? 0
        : int.parse(match.group(3)!) * 60 + int.parse(match.group(4)!);
    if (minutes > 840 ||
        (match.group(4) != null && int.parse(match.group(4)!) > 59)) {
      throw const FormatException('Invalid UTC offset');
    }
    final utc = DateTime.parse(value).toUtc();
    if (utc.microsecond != 0) {
      throw const FormatException(
        'Time must use millisecond precision or less',
      );
    }
    return (utc, match.group(2) == '-' ? -minutes : minutes);
  }

  String displayTime(DateTime utc, int offset) {
    final local = utc.add(Duration(minutes: offset));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}T${two(local.hour)}:${two(local.minute)}:${two(local.second)}${offset < 0 ? '-' : '+'}${two(offset.abs() ~/ 60)}:${two(offset.abs() % 60)}';
  }

  void editEvent(BuildContext context, [Event? old]) {
    final name = TextEditingController(text: old?.name);
    form(
      context,
      old == null ? 'Add event' : 'Edit event',
      [field('Event name', name)],
      () {
        if (name.text.trim().isEmpty) {
          throw const FormatException('Event name required');
        }
        update(
          events: [
            for (final event in plan.events)
              if (event.id != old?.id) event,
            Event(old?.id ?? id(), name.text.trim()),
          ],
        );
      },
    );
  }

  void editVolunteer(BuildContext context, [Volunteer? old]) {
    final name = TextEditingController(text: old?.name);
    final note = TextEditingController(text: old?.contactNote);
    form(
      context,
      old == null ? 'Add volunteer' : 'Edit volunteer',
      [
        field('Volunteer name', name),
        field('Private contact note', note),
        text('Notes stay on this device unless you manually export a backup.'),
      ],
      () {
        if (name.text.trim().isEmpty) {
          throw const FormatException('Volunteer name required');
        }
        update(
          volunteers: [
            for (final volunteer in plan.volunteers)
              if (volunteer.id != old?.id) volunteer,
            Volunteer(
              old?.id ?? id(),
              name.text.trim(),
              contactNote: note.text,
            ),
          ],
        );
      },
    );
  }

  void editShift(BuildContext context, Event event, [Shift? old]) {
    final start = TextEditingController(
      text: old == null
          ? ''
          : displayTime(old.startUtc, old.startOffsetMinutes),
    );
    final end = TextEditingController(
      text: old == null ? '' : displayTime(old.endUtc, old.endOffsetMinutes),
    );
    final needed = TextEditingController(
      text: old?.requiredHelpers.toString() ?? '1',
    );
    form(
      context,
      old == null ? 'Add shift' : 'Edit shift',
      [
        field('Start (ISO with UTC offset)', start),
        field('End (ISO with UTC offset)', end),
        field('Helpers needed', needed),
        if (old != null && plan.assignments.any((a) => a.shiftId == old.id))
          text(
            'Existing assignments stay attached. Check schedule conflicts after editing.',
          ),
      ],
      () {
        final (from, fromOffset) = time(start.text);
        final (to, toOffset) = time(end.text);
        update(
          shifts: [
            for (final shift in plan.shifts)
              if (shift.id != old?.id) shift,
            Shift(
              id: old?.id ?? id(),
              eventId: event.id,
              startUtc: from,
              endUtc: to,
              startOffsetMinutes: fromOffset,
              endOffsetMinutes: toOffset,
              requiredHelpers: int.parse(needed.text.trim()),
            ),
          ],
        );
      },
    );
  }

  void deleteEvent(Event event) {
    final removed = plan.shifts
        .where((s) => s.eventId == event.id)
        .map((s) => s.id)
        .toSet();
    update(
      events: plan.events.where((e) => e.id != event.id).toList(),
      shifts: plan.shifts.where((s) => s.eventId != event.id).toList(),
      assignments: plan.assignments
          .where((a) => !removed.contains(a.shiftId))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      final events = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text('Events'),
          text(
            'Coverage: ${plan.shifts.fold<int>(0, (sum, s) => sum + plan.coverage(s).filled)} assigned · ${plan.shifts.fold<int>(0, (sum, s) => sum + plan.coverage(s).missing)} needed',
          ),
          button('Add event', () => editEvent(context)),
          for (final event in plan.events) ...[
            text(event.name),
            Wrap(
              spacing: 8,
              children: [
                button(
                  'Edit event ${event.name}',
                  () => editEvent(context, event),
                ),
                button('Delete event ${event.name}', () => deleteEvent(event)),
                button(
                  'Add shift to ${event.name}',
                  () => editShift(context, event),
                ),
              ],
            ),
            for (final shift in plan.shifts.where(
              (s) => s.eventId == event.id,
            )) ...[
              text(
                '${displayTime(shift.startUtc, shift.startOffsetMinutes)} – ${displayTime(shift.endUtc, shift.endOffsetMinutes)} · ${shift.requiredHelpers} helpers',
              ),
              text(
                'Coverage ${plan.coverage(shift).filled}/${shift.requiredHelpers} · ${plan.coverage(shift).missing} needed · ${plan.coverage(shift).extra} extra',
              ),
              Wrap(
                spacing: 8,
                children: [
                  button(
                    'Edit shift ${shift.id}',
                    () => editShift(context, event, shift),
                  ),
                  button(
                    'Delete shift ${shift.id}',
                    () => update(
                      shifts: plan.shifts
                          .where((s) => s.id != shift.id)
                          .toList(),
                      assignments: plan.assignments
                          .where((a) => a.shiftId != shift.id)
                          .toList(),
                    ),
                  ),
                  for (final assignment in plan.assignments.where(
                    (a) => a.shiftId == shift.id,
                  ))
                    button(
                      '${assignment.attended ? 'Attended' : 'Mark attended'} ${plan.volunteers.firstWhere((v) => v.id == assignment.volunteerId).name} ${shift.id}',
                      () => update(
                        assignments: [
                          for (final a in plan.assignments)
                            if (a == assignment)
                              Assignment(
                                a.shiftId,
                                a.volunteerId,
                                attended: !a.attended,
                              )
                            else
                              a,
                        ],
                      ),
                    ),
                  for (final volunteer in plan.volunteers)
                    button(
                      '${plan.assignments.any((a) => a.shiftId == shift.id && a.volunteerId == volunteer.id) ? 'Unassign' : 'Assign'} ${volunteer.name} ${shift.id}',
                      () {
                        final assigned = plan.assignments.any(
                          (a) =>
                              a.shiftId == shift.id &&
                              a.volunteerId == volunteer.id,
                        );
                        update(
                          assignments: assigned
                              ? plan.assignments
                                    .where(
                                      (a) =>
                                          a.shiftId != shift.id ||
                                          a.volunteerId != volunteer.id,
                                    )
                                    .toList()
                              : [
                                  ...plan.assignments,
                                  Assignment(shift.id, volunteer.id),
                                ],
                        );
                      },
                    ),
                ],
              ),
            ],
          ],
          for (final conflict in plan.conflicts)
            text(
              'Schedule conflict: ${plan.volunteers.firstWhere((v) => v.id == conflict.volunteerId).name} has overlapping shifts.',
            ),
        ],
      );
      final volunteers = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text('Volunteers'),
          button('Add volunteer', () => editVolunteer(context)),
          for (final volunteer in plan.volunteers)
            Wrap(
              spacing: 8,
              children: [
                text(volunteer.name),
                button(
                  'Edit volunteer ${volunteer.name}',
                  () => editVolunteer(context, volunteer),
                ),
                button(
                  'Delete volunteer ${volunteer.name}',
                  () => update(
                    volunteers: plan.volunteers
                        .where((v) => v.id != volunteer.id)
                        .toList(),
                    assignments: plan.assignments
                        .where((a) => a.volunteerId != volunteer.id)
                        .toList(),
                  ),
                ),
              ],
            ),
        ],
      );
      final body = wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: events),
                const SizedBox(width: 24),
                SizedBox(width: 320, child: volunteers),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [events, const SizedBox(height: 20), volunteers],
            );
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(padding: const EdgeInsets.all(16), child: body),
          ),
        ),
      );
    },
  );
}
