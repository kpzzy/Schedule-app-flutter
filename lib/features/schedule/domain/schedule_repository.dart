import 'schedule_item.dart';

abstract interface class ScheduleRepository {
  Future<List<ScheduleItem>> load();
  Future<void> saveAll(List<ScheduleItem> items);
}
