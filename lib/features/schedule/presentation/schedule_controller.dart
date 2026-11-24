import 'package:flutter/foundation.dart';

import '../../../core/calendar_date.dart';
import '../domain/schedule_item.dart';
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
    final result = _items
        .where((item) => item.occursIn(start, endExclusive))
        .toList();
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

  Future<bool> upsert(ScheduleItem item) =>
      _save([..._items.where((existing) => existing.id != item.id), item]);

  Future<bool> delete(String id) =>
      _save(_items.where((item) => item.id != id).toList());

  Future<bool> toggleCompleted(ScheduleItem item) =>
      upsert(item.withCompleted(!item.isCompleted));

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
