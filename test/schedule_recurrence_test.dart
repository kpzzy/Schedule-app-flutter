import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/calendar_date.dart';
import 'package:schedule_app/features/schedule/data/json_schedule_repository.dart';
import 'package:schedule_app/features/schedule/data/schedule_widget_snapshot.dart';
import 'package:schedule_app/features/schedule/domain/schedule_draft.dart';
import 'package:schedule_app/features/schedule/domain/schedule_item.dart';
import 'package:schedule_app/features/schedule/domain/schedule_occurrences.dart';
import 'package:schedule_app/features/schedule/domain/schedule_recurrence.dart';
import 'package:schedule_app/features/schedule/presentation/schedule_controller.dart';

ScheduleItem series(
  RecurrenceFrequency frequency, {
  required CalendarDate start,
  CalendarDate? until,
  Set<int> firstWeek = const {},
  Set<int> secondWeek = const {},
  int startHour = 7,
  int endHour = 8,
  bool crossesMidnight = false,
}) => ScheduleDraft(
  id: 'fixture-series',
  title: '가상 반복 일정',
  note: '',
  kind: ScheduleKind.timed,
  category: ScheduleCategory.personal,
  startDate: start,
  endDateInclusive: crossesMidnight ? start.addDays(1) : start,
  startHour: startHour,
  startMinute: 15,
  endHour: endHour,
  endMinute: 0,
  isCompleted: false,
  frequency: frequency,
  firstWeek: firstWeek,
  secondWeek: secondWeek,
  repeatUntil: until,
).build();

void main() {
  test('매일 지정한 현지 시각에 발생하고 종료일도 포함한다', () {
    final day = CalendarDate(2026, 3, 7);
    final item = series(
      RecurrenceFrequency.daily,
      start: day,
      until: day.addDays(2),
    );
    final instances = scheduleOccurrences(
      [item],
      day.addDays(-1),
      day.addDays(5),
    ).toList();
    expect(instances.map((item) => item.startDate), [
      day,
      day.addDays(1),
      day.addDays(2),
    ]);
    expect(
      instances.map((item) => item.startsAt!.toLocal().hour),
      everyElement(7),
    );
    expect(
      instances.map((item) => item.startsAt!.toLocal().minute),
      everyElement(15),
    );
    expect(instances.map((item) => item.id).toSet(), hasLength(3));
  });

  test('주간 반복은 선택 요일에만 시작하고 시작일 이전을 제외한다', () {
    final day = CalendarDate(2026, 1, 7); // Wednesday.
    final item = series(
      RecurrenceFrequency.weekly,
      start: day,
      firstWeek: {1, 5},
    );
    final instances = scheduleOccurrences(
      [item],
      day.addDays(-7),
      day.addDays(10),
    );
    expect(instances.map((item) => item.startDate), [
      day.addDays(2),
      day.addDays(5),
      day.addDays(9),
    ]);
  });

  test('격주 패턴은 연도가 넘어가도 시작일의 월요일 기준을 유지한다', () {
    final day = CalendarDate(2026, 12, 28); // Monday.
    final item = series(
      RecurrenceFrequency.alternatingWeeks,
      start: day,
      firstWeek: {1, 2, 3},
      secondWeek: {4, 5},
    );
    final instances = scheduleOccurrences([item], day, day.addDays(21));
    expect(
      instances.map((item) => item.startDate),
      [0, 1, 2, 10, 11, 14, 15, 16].map(day.addDays),
    );
  });

  test('선택 요일이 종료일까지 한 번도 없으면 저장하지 않는다', () {
    final start = CalendarDate(2026, 1, 7);
    expect(
      () => series(
        RecurrenceFrequency.weekly,
        start: start,
        until: start,
        firstWeek: {5},
      ),
      throwsA(
        isA<ScheduleInputException>().having(
          (error) => error.reason,
          'reason',
          ScheduleInputError.recurrenceEmpty,
        ),
      ),
    );
  });

  test('종료일에 시작한 야간 반복 일정은 다음 날에도 같은 회차로 조회된다', () {
    final day = CalendarDate(2026, 2, 28);
    final item = series(
      RecurrenceFrequency.daily,
      start: day,
      until: day,
      startHour: 23,
      endHour: 1,
      crossesMidnight: true,
    );
    final first = scheduleOccurrences([item], day, day.addDays(1)).single;
    final second = scheduleOccurrences(
      [item],
      day.addDays(1),
      day.addDays(2),
    ).single;
    expect(second.id, first.id);
    expect(second.origin?.date, day);
    expect(
      scheduleOccurrences([item], day.addDays(2), day.addDays(3)),
      isEmpty,
    );
  });

  test('현지에 존재하지 않는 시각의 반복은 다른 시각으로 밀리지 않는다', () {
    final day = CalendarDate(2026, 3, 7);
    final item = series(
      RecurrenceFrequency.daily,
      start: day,
      startHour: 2,
      endHour: 4,
    );
    final instances = scheduleOccurrences([item], day, day.addDays(3)).toList();
    final isGap = DateTime(2026, 3, 8, 2, 15).hour != 2;
    expect(instances, hasLength(isGap ? 2 : 3));
    expect(
      instances.map((item) => item.startsAt!.toLocal().hour),
      everyElement(2),
    );
  });

  test('회차 완료·이동·삭제는 저장과 재시작 뒤에도 다른 회차와 분리된다', () async {
    final directory = await Directory.systemTemp.createTemp('repeat-test-');
    addTearDown(() => directory.delete(recursive: true));
    final repository = JsonScheduleRepository(() async => directory);
    final controller = ScheduleController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    final day = CalendarDate(2026, 1, 1);
    final root = series(
      RecurrenceFrequency.daily,
      start: day,
      until: day.addDays(3),
    );
    await controller.upsert(root);
    final first = controller.onDay(day).single;
    final second = controller.onDay(day.addDays(1)).single;
    final third = controller.onDay(day.addDays(2)).single;
    expect(await controller.toggleCompleted(first), isTrue);
    final movedDate = day.addDays(40);
    final replacement = ScheduleItem(
      id: second.id,
      title: '가상 회차 수정',
      kind: ScheduleKind.unscheduled,
      category: ScheduleCategory.personal,
      date: movedDate,
      origin: second.origin,
    );
    expect(await controller.upsert(replacement), isTrue);
    expect(await controller.deleteItem(third), isTrue);

    final reopened = ScheduleController(repository);
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.items.single.id, root.id);
    expect(reopened.onDay(day).single.isCompleted, isTrue);
    expect(reopened.onDay(day.addDays(1)), isEmpty);
    expect(reopened.onDay(day.addDays(2)), isEmpty);
    expect(reopened.onDay(day.addDays(3)).single.isCompleted, isFalse);
    expect(reopened.onDay(movedDate).single.id, second.id);
    expect(reopened.onDay(movedDate).single.title, replacement.title);

    final snapshot = buildScheduleWidgetSnapshot(day, reopened.items);
    final weeks = snapshot['weeks'] as Map<String, Object>;
    final months = snapshot['months'] as Map<String, Object>;
    expect(weeks[day.startOfWeek.toString()], 2);
    expect(months['2026-01'], 2);
    expect(months['2026-02'], 1);
  });
}
