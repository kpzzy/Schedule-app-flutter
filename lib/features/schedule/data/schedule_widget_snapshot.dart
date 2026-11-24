import '../../../app/app_strings.dart';
import '../../../core/calendar_date.dart';
import '../domain/schedule_item.dart';

/// A bounded, read-only projection shared by Android and iOS widgets.
Map<String, Object> buildScheduleWidgetSnapshot(
  CalendarDate today,
  List<ScheduleItem> items,
) {
  final firstMonth = today.firstOfMonth;
  final endMonth = firstMonth.addMonths(3);
  final firstDay = firstMonth.startOfWeek;
  final lastDay = endMonth.addDays(7);
  final displayOrder = [...items]
    ..sort((a, b) {
      final kind = a.kind.index.compareTo(b.kind.index);
      if (kind != 0) return kind;
      final start = a.startsAt;
      if (start != null) {
        final time = start.compareTo(b.startsAt!);
        if (time != 0) return time;
      }
      return a.id.compareTo(b.id);
    });

  final days = <String, Object>{};
  final weeks = <String, Object>{};
  final months = <String, Object>{};
  for (var day = firstDay; day.compareTo(lastDay) < 0; day = day.addDays(1)) {
    final daily = displayOrder.where((item) => item.occursOn(day)).toList();
    days[day.toString()] = {
      'count': daily.length,
      'items': [
        // Avoid sharing notes or IDs with the widget. Bound data sent to the launcher.
        for (final item in daily.take(7))
          {
            'lead': _lead(item, day),
            'title': String.fromCharCodes(item.title.runes.take(100)),
            'done': item.isCompleted,
          },
      ],
    };
    if (day.weekday == DateTime.monday && day.compareTo(endMonth) < 0) {
      weeks[day.toString()] = _count(items, day, day.addDays(7));
    }
    if (day.day == 1 && day.compareTo(endMonth) < 0) {
      months[day.toString().substring(0, 7)] = _count(
        items,
        day,
        day.addMonths(1),
      );
    }
  }

  return {'version': 1, 'days': days, 'weeks': weeks, 'months': months};
}

int _count(List<ScheduleItem> items, CalendarDate start, CalendarDate end) =>
    items.where((item) => item.occursIn(start, end)).length;

String _lead(ScheduleItem item, CalendarDate day) {
  if (item.kind != ScheduleKind.timed) return AppStrings.kindName(item.kind);
  final start = item.startsAt!.toLocal();
  return CalendarDate.fromLocal(start) == day
      ? AppStrings.time(start)
      : AppStrings.ongoing;
}
