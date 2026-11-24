import 'package:flutter/material.dart';

import '../../../app/app_strings.dart';
import '../../../core/calendar_date.dart';
import '../domain/schedule_draft.dart';
import '../domain/schedule_item.dart';
import 'schedule_controller.dart';

class ScheduleEditor extends StatefulWidget {
  const ScheduleEditor({
    super.key,
    required this.controller,
    required this.selectedDate,
    this.item,
    this.initialHour,
  });

  final ScheduleController controller;
  final CalendarDate selectedDate;
  final ScheduleItem? item;
  final int? initialHour;

  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final String _id;
  late ScheduleKind _kind;
  late ScheduleCategory _category;
  late CalendarDate _startDate;
  late CalendarDate _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _id = item?.id ?? ScheduleItem.newId();
    _title = TextEditingController(text: item?.title ?? '');
    _note = TextEditingController(text: item?.note ?? '');
    _kind =
        item?.kind ??
        (widget.initialHour == null
            ? ScheduleKind.unscheduled
            : ScheduleKind.timed);
    _category = item?.category ?? ScheduleCategory.personal;
    _startDate = item?.startDate ?? widget.selectedDate;
    final hour = widget.initialHour ?? 9;
    final start = item?.startsAt?.toLocal();
    final end = item?.endsAt?.toLocal();
    _startTime = start == null
        ? TimeOfDay(hour: hour, minute: 0)
        : TimeOfDay.fromDateTime(start);
    _endTime = end == null
        ? TimeOfDay(hour: (hour + 1) % 24, minute: 0)
        : TimeOfDay.fromDateTime(end);
    _endDate = item == null
        ? _startDate.addDays(hour == 23 ? 1 : 0)
        : switch (item.kind) {
            ScheduleKind.timed => CalendarDate.fromLocal(item.endsAt!),
            ScheduleKind.allDay => item.endDateExclusive!.addDays(-1),
            ScheduleKind.unscheduled => _startDate,
          };
  }

  @override
  void dispose() {
    _scroll.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() => _error = message);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  ScheduleItem _buildItem() => ScheduleDraft(
    id: _id,
    title: _title.text,
    note: _note.text,
    kind: _kind,
    category: _category,
    startDate: _startDate,
    endDateInclusive: _endDate,
    startHour: _startTime.hour,
    startMinute: _startTime.minute,
    endHour: _endTime.hour,
    endMinute: _endTime.minute,
    isCompleted: widget.item?.isCompleted ?? false,
  ).build();

  bool get _hasOverlap {
    try {
      final candidate = _buildItem();
      return widget.controller.items.any(
        (item) => item.id != candidate.id && item.overlaps(candidate),
      );
    } on ScheduleInputException {
      return false;
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final value = await showDatePicker(
      context: context,
      initialDate: initial.localMidnight,
      firstDate: DateTime(initial.year < 1900 ? initial.year : 1900),
      lastDate: DateTime(initial.year > 2100 ? initial.year : 2100, 12, 31),
    );
    if (value == null || !mounted) return;
    setState(() {
      final date = CalendarDate.fromLocal(value);
      if (isStart) {
        // Moving the start date preserves the calendar-day span of the draft.
        _endDate = _endDate.addDays(_startDate.daysUntil(date));
        _startDate = date;
      } else {
        _endDate = date;
      }
      _error = null;
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final value = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTime = value;
      } else {
        _endTime = value;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    late final ScheduleItem item;
    try {
      item = _buildItem();
    } on ScheduleInputException catch (error) {
      _showError(switch (error.reason) {
        ScheduleInputError.title => AppStrings.titleRequired,
        ScheduleInputError.dateRange => AppStrings.invalidDateRange,
        ScheduleInputError.timeRange => AppStrings.invalidTimeRange,
        ScheduleInputError.localTime => AppStrings.invalidLocalTime,
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final saved = await widget.controller.upsert(item);
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      _showError(AppStrings.saveFailure);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteTitle),
        content: const Text(AppStrings.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final saved = await widget.controller.delete(_id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      _showError(AppStrings.updateFailure);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? AppStrings.addSchedule
              : AppStrings.editSchedule,
        ),
        leading: IconButton(
          tooltip: AppStrings.cancel,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        actions: [
          if (widget.item != null)
            IconButton(
              tooltip: AppStrings.delete,
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    TextFormField(
                      controller: _title,
                      enabled: !_busy,
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.title,
                        hintText: AppStrings.titleHint,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? AppStrings.titleRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ScheduleKind>(
                      initialValue: _kind,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: AppStrings.kind,
                      ),
                      items: [
                        for (final kind in ScheduleKind.values)
                          DropdownMenuItem(
                            value: kind,
                            child: Text(AppStrings.kindName(kind)),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() {
                              _kind = value!;
                              _error = null;
                            }),
                    ),
                    const SizedBox(height: 12),
                    _pickerTile(
                      label: _kind == ScheduleKind.unscheduled
                          ? AppStrings.singleDate
                          : AppStrings.startDate,
                      value: AppStrings.date(_startDate),
                      icon: Icons.calendar_today_outlined,
                      onTap: () => _pickDate(true),
                    ),
                    if (_kind != ScheduleKind.unscheduled)
                      _pickerTile(
                        label: AppStrings.endDate,
                        value: AppStrings.date(_endDate),
                        icon: Icons.event_outlined,
                        onTap: () => _pickDate(false),
                      ),
                    if (_kind == ScheduleKind.allDay)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(AppStrings.allDayHint),
                      ),
                    if (_kind == ScheduleKind.timed) ...[
                      _pickerTile(
                        label: AppStrings.startTime,
                        value: AppStrings.timeParts(
                          _startTime.hour,
                          _startTime.minute,
                        ),
                        icon: Icons.schedule,
                        onTap: () => _pickTime(true),
                      ),
                      _pickerTile(
                        label: AppStrings.endTime,
                        value: AppStrings.timeParts(
                          _endTime.hour,
                          _endTime.minute,
                        ),
                        icon: Icons.schedule,
                        onTap: () => _pickTime(false),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ScheduleCategory>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: AppStrings.category,
                      ),
                      items: [
                        for (final category in ScheduleCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Text(AppStrings.categoryName(category)),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _category = value!),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _note,
                      enabled: !_busy,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 4000,
                      decoration: const InputDecoration(
                        labelText: AppStrings.note,
                      ),
                    ),
                    if (_hasOverlap)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(AppStrings.overlapHint),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(_busy ? AppStrings.saving : AppStrings.save),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _pickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    title: Text(label),
    subtitle: Text(value),
    trailing: Icon(icon),
    enabled: !_busy,
    onTap: onTap,
  );
}
