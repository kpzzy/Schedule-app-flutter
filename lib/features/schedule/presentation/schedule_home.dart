import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_strings.dart';
import '../../../core/calendar_date.dart';
import '../domain/schedule_item.dart';
import 'schedule_controller.dart';
import 'schedule_editor.dart';
import 'widgets/schedule_views.dart';

enum ScheduleView { day, week, month }

class ScheduleHome extends StatefulWidget {
  const ScheduleHome({super.key, required this.controller});

  final ScheduleController controller;

  @override
  State<ScheduleHome> createState() => _ScheduleHomeState();
}

class _ScheduleHomeState extends State<ScheduleHome>
    with WidgetsBindingObserver {
  CalendarDate _selected = CalendarDate.fromLocal(DateTime.now());
  ScheduleView _view = ScheduleView.day;
  DateTime _now = DateTime.now();
  late final Timer _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => _refreshClock());
  }

  void _refreshClock() {
    if (mounted) setState(() => _now = DateTime.now());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshClock();
  }

  @override
  void dispose() {
    _clock.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _move(int direction) => setState(() {
    _selected = switch (_view) {
      ScheduleView.day => _selected.addDays(direction),
      ScheduleView.week => _selected.addDays(direction * 7),
      ScheduleView.month => _selected.addMonths(direction),
    };
  });

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _selected.localMidnight,
      firstDate: DateTime(_selected.year < 1900 ? _selected.year : 1900),
      lastDate: DateTime(_selected.year > 2100 ? _selected.year : 2100, 12, 31),
    );
    if (chosen != null && mounted) {
      setState(() => _selected = CalendarDate.fromLocal(chosen));
    }
  }

  Future<void> _edit({ScheduleItem? item, int? hour}) async {
    if (!widget.controller.isReady || widget.controller.isSaving) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ScheduleEditor(
          controller: widget.controller,
          selectedDate: _selected,
          item: item,
          initialHour: hour,
        ),
      ),
    );
  }

  Future<void> _toggle(ScheduleItem item) async {
    final saved = await widget.controller.toggleCompleted(item);
    if (!saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.updateFailure)));
    }
  }

  void _openDay(CalendarDate day) => setState(() {
    _selected = day;
    _view = ScheduleView.day;
  });

  String get _heading => switch (_view) {
    ScheduleView.day => AppStrings.date(_selected),
    ScheduleView.week =>
      '${AppStrings.shortDate(_selected.startOfWeek)} – '
          '${AppStrings.shortDate(_selected.startOfWeek.addDays(6))}',
    ScheduleView.month => AppStrings.monthTitle(_selected),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          actions: [
            TextButton(
              onPressed: () => setState(() {
                _now = DateTime.now();
                _selected = CalendarDate.fromLocal(_now);
              }),
              child: const Text(AppStrings.today),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: AppStrings.previous,
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: _pickDate,
                        child: Text(_heading, textAlign: TextAlign.center),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.next,
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              if (controller.isSaving) const LinearProgressIndicator(),
              Expanded(child: _content(controller)),
            ],
          ),
        ),
        floatingActionButton: controller.isReady
            ? FloatingActionButton(
                tooltip: AppStrings.addSchedule,
                onPressed: controller.isSaving ? null : () => _edit(),
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _view.index,
          onDestinationSelected: (index) =>
              setState(() => _view = ScheduleView.values[index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.view_day_outlined),
              selectedIcon: Icon(Icons.view_day),
              label: AppStrings.day,
            ),
            NavigationDestination(
              icon: Icon(Icons.view_week_outlined),
              selectedIcon: Icon(Icons.view_week),
              label: AppStrings.week,
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: AppStrings.month,
            ),
          ],
        ),
      );
    },
  );

  Widget _content(ScheduleController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: AppStrings.loading),
      );
    }
    if (!controller.isReady) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 16),
              const Text(AppStrings.loadFailure, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.load,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }
    return switch (_view) {
      ScheduleView.day => DayScheduleView(
        key: ValueKey('day-$_selected'),
        date: _selected,
        now: _now,
        items: controller.onDay(_selected),
        enabled: !controller.isSaving,
        onEdit: (item) => _edit(item: item),
        onToggle: _toggle,
        onAddAtHour: (hour) => _edit(hour: hour),
      ),
      ScheduleView.week => WeekScheduleView(
        key: ValueKey('week-${_selected.startOfWeek}'),
        selected: _selected,
        items: controller.inRange(
          _selected.startOfWeek,
          _selected.startOfWeek.addDays(7),
        ),
        onOpenDay: _openDay,
        onEdit: (item) => _edit(item: item),
        onToggle: _toggle,
        enabled: !controller.isSaving,
      ),
      ScheduleView.month => MonthScheduleView(
        key: ValueKey('month-${_selected.firstOfMonth}'),
        selected: _selected,
        today: CalendarDate.fromLocal(_now),
        items: controller.inRange(
          _selected.firstOfMonth.startOfWeek,
          _selected.firstOfMonth.startOfWeek.addDays(42),
        ),
        onOpenDay: _openDay,
      ),
    };
  }
}
