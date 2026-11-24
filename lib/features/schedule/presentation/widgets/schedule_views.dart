import 'package:material_ui/material_ui.dart';

import '../../../../app/app_strings.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/calendar_date.dart';
import '../../domain/day_timeline.dart';
import '../../domain/schedule_item.dart';
import '../../domain/schedule_preferences.dart';
import 'schedule_tile.dart';

class DayScheduleView extends StatelessWidget {
  const DayScheduleView({
    super.key,
    required this.date,
    required this.now,
    required this.items,
    required this.preferences,
    required this.enabled,
    required this.onEdit,
    required this.onToggle,
    required this.onAddAtHour,
  });

  final CalendarDate date;
  final DateTime now;
  final List<ScheduleItem> items;
  final SchedulePreferences preferences;
  final bool enabled;
  final ValueChanged<ScheduleItem> onEdit;
  final ValueChanged<ScheduleItem> onToggle;
  final ValueChanged<int> onAddAtHour;

  @override
  Widget build(BuildContext context) {
    final untimed = items.where((item) => item.kind != ScheduleKind.timed);
    final hours = buildDayTimeline(date, items);
    final isToday = date == CalendarDate.fromLocal(now);
    final startHour = preferences.startHour;
    final earlyHours = hours.take(startHour);
    final earlyCount = {
      for (final slot in earlyHours)
        for (final item in [...slot.starts, ...slot.continues]) item.id,
    }.length;
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
        if (startHour > 0)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(AppStrings.earlierHours(startHour)),
            subtitle: earlyCount == 0 && !(isToday && now.hour < startHour)
                ? null
                : Text(
                    [
                      if (earlyCount > 0) AppStrings.count(earlyCount),
                      if (isToday && now.hour < startHour) AppStrings.now(now),
                    ].join(' · '),
                  ),
            children: [for (final slot in earlyHours) _hour(context, slot)],
          ),
        for (final slot in hours.skip(startHour))
          _hour(context, slot, showNow: isToday && now.hour == slot.hour),
      ],
    );
  }

  Widget _hour(BuildContext context, DayHour slot, {bool showNow = false}) =>
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
                if (showNow)
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
                    onPressed: enabled ? () => onAddAtHour(slot.hour) : null,
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
      );

  Widget _tile(ScheduleItem item) => ScheduleTile(
    item: item,
    category: preferences.categoryFor(item.category),
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
    required this.preferences,
    required this.onOpenDay,
    required this.onEdit,
    required this.onToggle,
    required this.enabled,
  });

  final CalendarDate selected;
  final List<ScheduleItem> items;
  final SchedulePreferences preferences;
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
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppTheme.weekendColor(date.weekday)),
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
              category: preferences.categoryFor(item.category),
              enabled: enabled,
              onEdit: () => onEdit(item),
              onToggle: () => onToggle(item),
            ),
        ],
      ),
    );
  }
}
