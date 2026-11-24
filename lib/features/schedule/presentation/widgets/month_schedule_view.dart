import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../app/app_strings.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/calendar_date.dart';
import '../../domain/schedule_item.dart';
import 'schedule_tile.dart';

class MonthScheduleView extends StatelessWidget {
  const MonthScheduleView({
    super.key,
    required this.selected,
    required this.today,
    required this.items,
    required this.onOpenDay,
    required this.onEdit,
    required this.onToggle,
    required this.enabled,
  });

  final CalendarDate selected;
  final CalendarDate today;
  final List<ScheduleItem> items;
  final ValueChanged<CalendarDate> onOpenDay;
  final ValueChanged<ScheduleItem> onEdit;
  final ValueChanged<ScheduleItem> onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final first = selected.firstOfMonth.startOfWeek;
    final lastOfMonth = selected.firstOfMonth.addMonths(1).addDays(-1);
    final weekCount = (first.daysUntil(lastOfMonth) + 7) ~/ 7;
    final daily = <CalendarDate, List<ScheduleItem>>{
      for (var index = 0; index < weekCount * 7; index++)
        first.addDays(index): items
            .where((item) => item.occursOn(first.addDays(index)))
            .toList(),
    };
    final agenda = daily.entries.where(
      (entry) => entry.key.month == selected.month && entry.value.isNotEmpty,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      children: [
        _calendar(first, weekCount, daily),
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Text(AppStrings.monthHint),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
          child: Text(
            AppStrings.monthAgenda,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (agenda.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(AppStrings.emptyMonth),
          ),
        for (final day in agenda)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                  onPressed: () => onOpenDay(day.key),
                  child: Text(
                    AppStrings.date(day.key),
                    style: TextStyle(
                      color: AppTheme.weekendColor(day.key.weekday),
                    ),
                  ),
                ),
                for (final item in day.value)
                  ScheduleTile(
                    item: item,
                    enabled: enabled,
                    onEdit: () => onEdit(item),
                    onToggle: () => onToggle(item),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _calendar(
    CalendarDate first,
    int weekCount,
    Map<CalendarDate, List<ScheduleItem>> daily,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final width = math.max(constraints.maxWidth, 280 * scale);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              Row(
                children: [
                  for (var weekday = 1; weekday <= 7; weekday++)
                    Expanded(
                      child: Center(
                        child: Text(
                          AppStrings.weekdays[weekday - 1],
                          style: TextStyle(
                            color: AppTheme.weekendColor(weekday),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              for (var week = 0; week < weekCount; week++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var weekday = 0; weekday < 7; weekday++)
                        Expanded(
                          child: _cell(
                            context,
                            first.addDays(week * 7 + weekday),
                            daily,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _cell(
    BuildContext context,
    CalendarDate date,
    Map<CalendarDate, List<ScheduleItem>> daily,
  ) {
    final count = daily[date]!.length;
    final colors = Theme.of(context).colorScheme;
    final weekend = AppTheme.weekendColor(date.weekday);
    final inMonth = date.month == selected.month;
    return Semantics(
      label:
          '${AppStrings.date(date)} · ${AppStrings.count(count)}'
          '${date == today ? ' · ${AppStrings.today}' : ''}',
      button: true,
      selected: date == selected,
      onTap: () => onOpenDay(date),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onOpenDay(date),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.all(1),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: date == selected ? colors.primaryContainer : colors.surface,
            border: Border.all(
              color: date == today ? colors.primary : colors.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: date == today
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: inMonth
                      ? weekend ?? colors.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
              if (count > 0)
                Text(
                  AppStrings.compactCount(count),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
