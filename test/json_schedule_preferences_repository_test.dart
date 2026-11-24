import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/calendar_date.dart';
import 'package:schedule_app/features/schedule/data/json_schedule_preferences_repository.dart';
import 'package:schedule_app/features/schedule/data/json_schedule_repository.dart';
import 'package:schedule_app/features/schedule/domain/schedule_item.dart';
import 'package:schedule_app/features/schedule/domain/schedule_preferences.dart';
import 'package:schedule_app/features/schedule/presentation/schedule_preferences_controller.dart';

void main() {
  late Directory directory;
  late JsonSchedulePreferencesRepository preferences;
  late JsonScheduleRepository schedules;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'schedule-preferences-test-',
    );
    preferences = JsonSchedulePreferencesRepository(() async => directory);
    schedules = JsonScheduleRepository(() async => directory);
  });

  tearDown(() async => directory.delete(recursive: true));

  test('시작 시각과 이름·색상 변경을 복원하고 삭제한 카테고리의 일정은 보존한다', () async {
    final initial = await preferences.load();
    expect(initial.startHour, 7);
    expect(initial.categoryFor(ScheduleCategory.study).name, '공부');
    const category = ScheduleCategoryDefinition(
      'test-category',
      '가상 분류',
      0xFFAE2730,
    );
    final item = ScheduleItem(
      id: 'test-item',
      title: '가상 일정',
      kind: ScheduleKind.unscheduled,
      category: category.id,
      date: CalendarDate(2026, 2, 1),
    );
    await schedules.saveAll([item]);
    await preferences.save(
      initial.copyWith(startHour: 5, categories: [category]),
    );
    final reopened = JsonSchedulePreferencesRepository(() async => directory);
    final loaded = await reopened.load();
    expect(loaded.startHour, 5);
    final id = (await schedules.load()).single.category;
    expect(loaded.categoryFor(id).toJson(), category.toJson());

    await reopened.save(loaded.copyWith(categories: []));
    final afterDeletion = await reopened.load();
    expect(afterDeletion.categories, isEmpty);
    expect(afterDeletion.categoryFor(id), SchedulePreferences.uncategorized);
    expect((await schedules.load()).single.toJson(), item.toJson());
  });

  test('설정을 읽지 못하면 기존 파일의 저장을 막고 읽기에 성공한 뒤 재시도할 수 있다', () async {
    final file = File('${directory.path}/schedule_preferences.json');
    await file.writeAsString('{broken');
    final controller = SchedulePreferencesController(preferences);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.loadFailed, isTrue);
    expect(
      await controller.save(controller.value.copyWith(startHour: 5)),
      isFalse,
    );
    expect(await file.readAsString(), '{broken');

    await file.writeAsString(
      '{"schemaVersion":1,"startHour":6,"categories":[]}',
    );
    await controller.load();
    expect(controller.loadFailed, isFalse);
    final blocker = Directory('${file.path}.tmp');
    await blocker.create();
    final updated = controller.value.copyWith(startHour: 5);
    expect(await controller.save(updated), isFalse);
    expect(controller.value.startHour, 6);
    expect((await preferences.load()).startHour, 6);
    await blocker.delete();
    expect(await controller.save(updated), isTrue);
    expect((await preferences.load()).startHour, 5);
  });
}
