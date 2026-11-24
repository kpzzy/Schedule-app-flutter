import 'package:flutter/foundation.dart';

import '../../../core/calendar_date.dart';
import '../domain/schedule_item.dart';
import '../domain/schedule_occurrences.dart';
import '../domain/schedule_repository.dart';

enum ScheduleFailure { load, save }

final class ScheduleController extends ChangeNotifier {
  ScheduleController(this.repository);

  final ScheduleRepository repository;
  List<ScheduleItem> _items = [];
  bool isLoading = false;
  bool isSaving = false;
  bool isReady = false;
  bool _disposed = false;
  ScheduleFailure? failure;

  List<ScheduleItem> get items => List.unmodifiable(_items);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (isLoading || isSaving) return;
    isLoading = true;
    failure = null;
    _notify();
    try {
      _items = await repository.load();
      isReady = true;
    } catch (_) {
      // Keep the original document intact and prevent accidental overwrites.
      isReady = false;
      failure = ScheduleFailure.load;
    } finally {
      isLoading = false;
      _notify();
    }
  }

  List<ScheduleItem> inRange(CalendarDate start, CalendarDate endExclusive) {
    final result = scheduleOccurrences(_items, start, endExclusive).toList();
    result.sort((a, b) {
      final byDate = a.startDate.compareTo(b.startDate);
      if (byDate != 0) return byDate;
      if (a.kind == ScheduleKind.timed && b.kind == ScheduleKind.timed) {
        return a.startsAt!.compareTo(b.startsAt!);
      }
      final byKind = a.kind.index.compareTo(b.kind.index);
      return byKind != 0 ? byKind : a.id.compareTo(b.id);
    });
    return result;
  }

  List<ScheduleItem> onDay(CalendarDate day) => inRange(day, day.addDays(1));

  ScheduleItem? seriesFor(ScheduleItem occurrence) {
    final origin = occurrence.origin;
    return origin == null ? null : _find(origin.seriesId);
  }

  ScheduleItem? _find(String id) =>
      _items.where((item) => item.id == id).firstOrNull;

  Future<bool> upsert(ScheduleItem item) {
    final origin = item.origin;
    if (origin != null) return _saveOverride(origin, item.withOrigin(null));

    final rule = item.recurrence;
    final existing = _find(item.id);
    if (rule == null) {
      return _replace(
        item.withCompleted(
          item.isCompleted ||
              existing?.completedDates.contains(item.startDate) == true,
        ),
      );
    }
    final completed =
        existing?.completedDates.where(rule.includes).toSet() ??
        <CalendarDate>{};
    if (item.isCompleted &&
        existing?.recurrence == null &&
        rule.includes(item.startDate)) {
      completed.add(item.startDate);
    }
    return _replace(
      item
          .withCompleted(false)
          .withSeriesChanges(
            overrides: {
              for (final replacement
                  in (existing?.overrides ?? item.overrides).entries)
                if (rule.includes(replacement.key))
                  replacement.key: replacement.value,
            },
            completedDates: completed,
          ),
    );
  }

  Future<bool> _replace(ScheduleItem item) =>
      _save([..._items.where((existing) => existing.id != item.id), item]);

  Future<bool> _saveOverride(
    OccurrenceOrigin origin,
    ScheduleItem? replacement,
  ) async {
    final series = _find(origin.seriesId);
    if (series == null || series.recurrence?.includes(origin.date) != true) {
      return false;
    }
    return _replace(
      series.withSeriesChanges(
        overrides: {...series.overrides, origin.date: replacement},
        completedDates: {...series.completedDates}..remove(origin.date),
      ),
    );
  }

  Future<bool> delete(String id) =>
      _save(_items.where((item) => item.id != id).toList());

  Future<bool> deleteItem(ScheduleItem item) {
    final origin = item.origin;
    return origin == null ? delete(item.id) : _saveOverride(origin, null);
  }

  Future<bool> toggleCompleted(ScheduleItem item) async {
    final origin = item.origin;
    if (origin == null) return upsert(item.withCompleted(!item.isCompleted));
    final series = _find(origin.seriesId);
    if (series == null || series.recurrence?.includes(origin.date) != true) {
      return false;
    }
    if (series.overrides.containsKey(origin.date)) {
      return upsert(item.withCompleted(!item.isCompleted));
    }
    final completed = {...series.completedDates};
    if (item.isCompleted) {
      completed.remove(origin.date);
    } else {
      completed.add(origin.date);
    }
    return _replace(series.withSeriesChanges(completedDates: completed));
  }

  Future<bool> _save(List<ScheduleItem> next) async {
    if (!isReady || isLoading || isSaving || _disposed) return false;
    isSaving = true;
    failure = null;
    _notify();
    try {
      await repository.saveAll(next);
      _items = next;
      return true;
    } catch (_) {
      failure = ScheduleFailure.save;
      return false;
    } finally {
      isSaving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
