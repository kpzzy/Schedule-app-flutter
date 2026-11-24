import '../../../core/calendar_date.dart';
import 'schedule_item.dart';

/// A readable hour-based agenda, with exact minute values retained in each item.
final class DayHour {
  const DayHour({
    required this.hour,
    required this.starts,
    required this.continues,
    this.isSkipped = false,
  });

  final int hour;
  final List<ScheduleItem> starts;
  final List<ScheduleItem> continues;
  final bool isSkipped;
  bool get isOccupied => starts.isNotEmpty || continues.isNotEmpty;
}

List<DayHour> buildDayTimeline(CalendarDate day, List<ScheduleItem> items) {
  final timed =
      items
          .where(
            (item) => item.kind == ScheduleKind.timed && item.occursOn(day),
          )
          .toList()
        ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
  return List.generate(24, (hour) {
    final start = DateTime(day.year, day.month, day.day, hour);
    final end = DateTime(day.year, day.month, day.day, hour + 1);
    if (!end.isAfter(start)) {
      return DayHour(
        hour: hour,
        starts: const [],
        continues: const [],
        isSkipped: true,
      );
    }
    final overlaps = timed.where(
      (item) => item.startsAt!.isBefore(end) && item.endsAt!.isAfter(start),
    );
    return DayHour(
      hour: hour,
      starts: overlaps
          .where((item) => !item.startsAt!.isBefore(start) || hour == 0)
          .toList(),
      continues: overlaps
          .where((item) => item.startsAt!.isBefore(start) && hour != 0)
          .toList(),
    );
  });
}
