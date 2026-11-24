import 'dart:async';

import 'package:schedule_app/features/schedule/domain/schedule_item.dart';
import 'package:schedule_app/features/schedule/domain/schedule_repository.dart';

class FakeScheduleRepository implements ScheduleRepository {
  List<ScheduleItem> stored = [];
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? saveGate;
  int writeCount = 0;

  @override
  Future<List<ScheduleItem>> load() async {
    if (failLoad) throw StateError('Simulated read failure');
    return List.of(stored);
  }

  @override
  Future<void> saveAll(List<ScheduleItem> items) async {
    writeCount++;
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw StateError('Simulated write failure');
    stored = List.of(items);
  }
}
