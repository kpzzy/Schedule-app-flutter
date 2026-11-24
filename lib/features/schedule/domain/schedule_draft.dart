import '../../../core/calendar_date.dart';
import 'schedule_item.dart';
import 'schedule_occurrences.dart';
import 'schedule_recurrence.dart';

enum ScheduleInputError {
  title,
  dateRange,
  timeRange,
  localTime,
  recurrenceDays,
  recurrenceEnd,
  recurrenceEmpty,
}

final class ScheduleInputException implements Exception {
  const ScheduleInputException(this.reason);
  final ScheduleInputError reason;
}

/// Form values remain local until this boundary converts timed items to UTC.
final class ScheduleDraft {
  const ScheduleDraft({
    required this.id,
    required this.title,
    required this.note,
    required this.kind,
    required this.category,
    required this.startDate,
    required this.endDateInclusive,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.isCompleted,
    this.frequency,
    this.firstWeek = const {},
    this.secondWeek = const {},
    this.repeatUntil,
  });

  final String id;
  final String title;
  final String note;
  final ScheduleKind kind;
  final String category;
  final CalendarDate startDate;
  final CalendarDate endDateInclusive;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isCompleted;
  final RecurrenceFrequency? frequency;
  final Set<int> firstWeek;
  final Set<int> secondWeek;
  final CalendarDate? repeatUntil;

  DateTime _instant(CalendarDate date, int hour, int minute) {
    final value = DateTime(date.year, date.month, date.day, hour, minute);
    if (CalendarDate.fromLocal(value) != date ||
        value.hour != hour ||
        value.minute != minute) {
      throw const ScheduleInputException(ScheduleInputError.localTime);
    }
    return value;
  }

  ScheduleItem build() {
    if (title.trim().isEmpty) {
      throw const ScheduleInputException(ScheduleInputError.title);
    }
    DateTime? start;
    DateTime? end;
    if (kind == ScheduleKind.timed) {
      start = _instant(startDate, startHour, startMinute);
      end = _instant(endDateInclusive, endHour, endMinute);
      if (!end.isAfter(start)) {
        throw const ScheduleInputException(ScheduleInputError.timeRange);
      }
    } else if (kind == ScheduleKind.allDay &&
        endDateInclusive.compareTo(startDate) < 0) {
      throw const ScheduleInputException(ScheduleInputError.dateRange);
    }
    final type = frequency;
    final until = repeatUntil;
    if (type != null && until != null && until.compareTo(startDate) < 0) {
      throw const ScheduleInputException(ScheduleInputError.recurrenceEnd);
    }
    if (type == RecurrenceFrequency.weekly && firstWeek.isEmpty ||
        type == RecurrenceFrequency.alternatingWeeks &&
            firstWeek.isEmpty &&
            secondWeek.isEmpty) {
      throw const ScheduleInputException(ScheduleInputError.recurrenceDays);
    }
    final item = ScheduleItem(
      id: id,
      title: title,
      kind: kind,
      category: category,
      note: note,
      isCompleted: isCompleted,
      startsAt: start,
      endsAt: end,
      date: kind == ScheduleKind.timed ? null : startDate,
      endDateExclusive: kind == ScheduleKind.allDay
          ? endDateInclusive.addDays(1)
          : null,
      recurrence: type == null
          ? null
          : ScheduleRecurrence(
              frequency: type,
              startsOn: startDate,
              until: until,
              daySpan: kind == ScheduleKind.unscheduled
                  ? 0
                  : startDate.daysUntil(endDateInclusive),
              startMinute: kind == ScheduleKind.timed
                  ? startHour * 60 + startMinute
                  : null,
              endMinute: kind == ScheduleKind.timed
                  ? endHour * 60 + endMinute
                  : null,
              firstWeek: type == RecurrenceFrequency.daily
                  ? const {}
                  : firstWeek,
              secondWeek: type == RecurrenceFrequency.alternatingWeeks
                  ? secondWeek
                  : const {},
            ),
    );
    if (type != null &&
        scheduleOccurrences([item], startDate, startDate.addDays(28)).isEmpty) {
      throw const ScheduleInputException(ScheduleInputError.recurrenceEmpty);
    }
    return item;
  }
}
