import '../../../core/calendar_date.dart';
import 'schedule_item.dart';

enum ScheduleInputError { title, dateRange, timeRange, localTime }

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
  });

  final String id;
  final String title;
  final String note;
  final ScheduleKind kind;
  final ScheduleCategory category;
  final CalendarDate startDate;
  final CalendarDate endDateInclusive;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isCompleted;

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
    return ScheduleItem(
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
    );
  }
}
