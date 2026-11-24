import 'package:material_ui/material_ui.dart';

import '../../../../app/app_strings.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/calendar_date.dart';
import '../../domain/day_timeline.dart';
import '../../domain/schedule_item.dart';
import 'schedule_tile.dart';

class DayScheduleView extends StatelessWidget {
  const DayScheduleView({
    super.key,
    required this.date,
    required this.now,
    required this.items,
    required this.enabled,
    required this.onEdit,
    required this.onToggle,
    required this.onAddAtHour,
  });

  final CalendarDate date;
  final DateTime now;
  final List<ScheduleItem> items;
  final bool enabled;
  final ValueChanged<ScheduleItem> onEdit;
  final ValueChanged<ScheduleItem> onToggle;
  final ValueChanged<int> onAddAtHour;

  @override
  Widget build(BuildContext context) {
    final untimed = items.where((item) => item.kind != ScheduleKind.timed);
    final hours = buildDayTimeline(date, items);
    final isToday = date == CalendarDate.fromLocal(now);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Text(
          AppStrings.completedCount(
            items.where((item) => item.isCompleted).length,
            items.length,
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(Icons.wb_sunny_outlined, size: 36),
                SizedBox(height: 12),
                Text(AppStrings.emptyDay),
                SizedBox(height: 4),
                Text(AppStrings.emptyHint, textAlign: TextAlign.center),
              ],
            ),
          ),
        if (untimed.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(AppStrings.dateOnly),
          const SizedBox(height: 8),
          for (final item in untimed) _tile(item),
        ],
        const SizedBox(height: 16),
        Text(
          AppStrings.timeline,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final slot in hours)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(AppStrings.hour(slot.hour)),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 1),
                    if (isToday && now.hour == slot.hour)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          AppStrings.now(now),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    for (final item in slot.continues)
                      TextButton(
                        onPressed: enabled ? () => onEdit(item) : null,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${AppStrings.ongoing} · ${item.title}'),
                        ),
                      ),
                    for (final item in slot.starts) _tile(item),
                    if (slot.isSkipped)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(AppStrings.skippedTime),
                      ),
                    if (!slot.isOccupied && !slot.isSkipped)
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: enabled
                            ? () => onAddAtHour(slot.hour)
                            : null,
                        child: Semantics(
                          label: AppStrings.addAtHour(slot.hour),
                          excludeSemantics: true,
                          child: const Text(AppStrings.freeTime),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _tile(ScheduleItem item) => ScheduleTile(
    item: item,
    enabled: enabled,
    onEdit: () => onEdit(item),
    onToggle: () => onToggle(item),
  );
}

class WeekScheduleView extends StatelessWidget {
  const WeekScheduleView({
    super.key,
    required this.selected,
    required this.items,
    required this.onOpenDay,
    required this.onEdit,
    required this.onToggle,
    required this.enabled,
  });

  final CalendarDate selected;
  final List<ScheduleItem> items;
  final ValueChanged<CalendarDate> onOpenDay;
  final ValueChanged<ScheduleItem> onEdit;
  final ValueChanged<ScheduleItem> onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
    children: [
      const Text(AppStrings.weekHint),
      const SizedBox(height: 12),
      for (var index = 0; index < 7; index++)
        _day(context, selected.startOfWeek.addDays(index)),
    ],
  );

  Widget _day(BuildContext context, CalendarDate date) {
    final dayItems = items.where((item) => item.occursOn(date)).toList();
    final hours = buildDayTimeline(date, dayItems);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton(
            onPressed: () => onOpenDay(date),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${AppStrings.shortDate(date)} · ${AppStrings.count(dayItems.length)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Row(
            children: [
              for (final hour in hours)
                Expanded(
                  child: Semantics(
                    label:
                        '${AppStrings.hour(hour.hour)} · '
                        '${hour.isOccupied ? AppStrings.count(hour.starts.length + hour.continues.length) : AppStrings.freeTime}',
                    child: Container(
                      height: hour.isOccupied ? 16 : 8,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: hour.isOccupied
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0'),
              Text('6'),
              Text('12'),
              Text('18'),
              Text('24'),
            ],
          ),
          const SizedBox(height: 8),
          if (dayItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(AppStrings.emptyWeekDay),
            ),
          for (final item in dayItems)
            ScheduleTile(
              item: item,
              enabled: enabled,
              onEdit: () => onEdit(item),
              onToggle: () => onToggle(item),
            ),
        ],
      ),
    );
  }
}

class MonthScheduleView extends StatelessWidget {
  const MonthScheduleView({
    super.key,
    required this.selected,
    required this.today,
    required this.items,
    required this.onOpenDay,
  });

  final CalendarDate selected;
  final CalendarDate today;
  final List<ScheduleItem> items;
  final ValueChanged<CalendarDate> onOpenDay;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Preserve readable dates at large font sizes, using horizontal scrolling.
      final scaled = MediaQuery.textScalerOf(context).scale(14) / 14;
      final minimumWidth = 350.0 * scaled;
      final width = constraints.maxWidth > minimumWidth
          ? constraints.maxWidth
          : minimumWidth;
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(AppStrings.monthHint),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final day in AppStrings.weekdays)
                          Expanded(child: Center(child: Text(day))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var week = 0; week < 6; week++)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var weekday = 0; weekday < 7; weekday++)
                              Expanded(
                                child: _cell(
                                  context,
                                  selected.firstOfMonth.startOfWeek.addDays(
                                    week * 7 + weekday,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _cell(BuildContext context, CalendarDate date) {
    final dayItems = items.where((item) => item.occursOn(date)).toList();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label:
          '${AppStrings.date(date)} · ${AppStrings.count(dayItems.length)}'
          '${date == today ? ' · ${AppStrings.today}' : ''}',
      button: true,
      selected: date == selected,
      child: InkWell(
        onTap: () => onOpenDay(date),
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: date == selected ? colors.primaryContainer : colors.surface,
            border: Border.all(
              color: date == today ? colors.primary : colors.outlineVariant,
              width: date == today ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: date == today
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: date.month == selected.month
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              for (final item in dayItems.take(2))
                Text(
                  '${item.isCompleted ? '✓ ' : ''}${item.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.categoryColor(item.category),
                  ),
                ),
              if (dayItems.length > 2)
                Text(AppStrings.more(dayItems.length - 2)),
            ],
          ),
        ),
      ),
    );
  }
}
