import '../../../core/calendar_date.dart';
import 'schedule_item.dart';
import 'schedule_recurrence.dart';

/// Resolves stored series to independent occurrences for the requested range.
Iterable<ScheduleItem> scheduleOccurrences(
  Iterable<ScheduleItem> source,
  CalendarDate start,
  CalendarDate endExclusive,
) sync* {
  if (start.compareTo(endExclusive) >= 0) return;
  for (final item in source) {
    final rule = item.recurrence;
    if (rule == null) {
      if (item.occursIn(start, endExclusive)) yield item;
      continue;
    }

    var day = start.addDays(-rule.daySpan);
    if (day.compareTo(rule.startsOn) < 0) day = rule.startsOn;
    final until = rule.until;
    for (
      ;
      day.compareTo(endExclusive) < 0 &&
          (until == null || day.compareTo(until) <= 0);
      day = day.addDays(1)
    ) {
      if (!rule.includes(day) || item.overrides.containsKey(day)) continue;
      final instance = _occurrence(item, rule, day);
      if (instance != null && instance.occursIn(start, endExclusive)) {
        yield instance;
      }
    }

    // A moved instance can enter this range from any original occurrence date.
    for (final entry in item.overrides.entries) {
      final replacement = entry.value;
      if (replacement != null &&
          rule.includes(entry.key) &&
          replacement.occursIn(start, endExclusive)) {
        yield replacement.withOrigin((seriesId: item.id, date: entry.key));
      }
    }
  }
}

ScheduleItem? _occurrence(
  ScheduleItem item,
  ScheduleRecurrence rule,
  CalendarDate day,
) {
  final timed = item.kind == ScheduleKind.timed;
  final lastDay = day.addDays(rule.daySpan);
  final start = timed ? rule.localInstant(day, rule.startMinute!) : null;
  final end = timed ? rule.localInstant(lastDay, rule.endMinute!) : null;
  if (timed && (start == null || end == null || !end.isAfter(start))) {
    return null;
  }
  return ScheduleItem(
    id: ScheduleItem.occurrenceId(item.id, day),
    title: item.title,
    note: item.note,
    kind: item.kind,
    category: item.category,
    isCompleted: item.completedDates.contains(day),
    startsAt: start,
    endsAt: end,
    date: timed ? null : day,
    endDateExclusive: item.kind == ScheduleKind.allDay
        ? lastDay.addDays(1)
        : null,
    origin: (seriesId: item.id, date: day),
  );
}
