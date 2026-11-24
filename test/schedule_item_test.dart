import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/calendar_date.dart';
import 'package:schedule_app/features/schedule/domain/day_timeline.dart';
import 'package:schedule_app/features/schedule/domain/schedule_draft.dart';
import 'package:schedule_app/features/schedule/domain/schedule_item.dart';

ScheduleItem timed(String id, DateTime start, DateTime end) => ScheduleItem(
  id: id,
  title: '테스트 일정',
  kind: ScheduleKind.timed,
  category: ScheduleCategory.personal,
  startsAt: start,
  endsAt: end,
);

void main() {
  test('자정을 넘는 일정은 하나의 ID로 두 날짜에서 조회된다', () {
    final item = timed(
      'overnight',
      DateTime(2026, 1, 31, 23, 47),
      DateTime(2026, 2, 1, 1, 13),
    );
    expect(item.occursOn(CalendarDate(2026, 1, 31)), isTrue);
    expect(item.occursOn(CalendarDate(2026, 2, 1)), isTrue);
    expect(item.occursOn(CalendarDate(2026, 2, 2)), isFalse);
    expect(item.startsAt!.isUtc, isTrue);
    expect(item.startsAt!.toLocal().minute, 47);
  });

  test('종료 시각이 정확히 자정이면 다음 날짜에는 나타나지 않는다', () {
    final item = timed(
      'midnight',
      DateTime(2026, 1, 31, 23),
      DateTime(2026, 2, 1),
    );
    expect(item.occursOn(CalendarDate(2026, 1, 31)), isTrue);
    expect(item.occursOn(CalendarDate(2026, 2, 1)), isFalse);
  });

  test('인접한 일정은 겹치지 않고 실제 교집합만 겹친다', () {
    final first = timed(
      'first',
      DateTime(2026, 1, 1, 9),
      DateTime(2026, 1, 1, 10),
    );
    final adjacent = timed(
      'next',
      DateTime(2026, 1, 1, 10),
      DateTime(2026, 1, 1, 11),
    );
    final overlapping = timed(
      'overlap',
      DateTime(2026, 1, 1, 9, 59),
      DateTime(2026, 1, 1, 11),
    );
    expect(first.overlaps(adjacent), isFalse);
    expect(first.overlaps(overlapping), isTrue);
    expect(overlapping.overlaps(first), isTrue);
  });

  test('종료가 시작보다 같거나 빠른 일정은 거부한다', () {
    final start = DateTime(2026, 1, 1, 10);
    expect(() => timed('equal', start, start), throwsArgumentError);
    expect(
      () =>
          timed('backwards', start, start.subtract(const Duration(minutes: 1))),
      throwsArgumentError,
    );
  });

  test('여러 날의 종일 일정은 종료 날짜를 제외하고 시간을 저장하지 않는다', () {
    final item = ScheduleItem(
      id: 'all-day',
      title: '가상 휴가',
      kind: ScheduleKind.allDay,
      category: ScheduleCategory.personal,
      date: CalendarDate(2026, 1, 30),
      endDateExclusive: CalendarDate(2026, 2, 2),
    );
    expect(item.occursOn(CalendarDate(2026, 2, 1)), isTrue);
    expect(item.occursOn(CalendarDate(2026, 2, 2)), isFalse);
    expect(item.startsAt, isNull);
    final restored = ScheduleItem.fromJson(item.toJson());
    expect(restored.date, item.date);
    expect(restored.endDateExclusive, item.endDateExclusive);
  });

  test('시간 미정 할 일은 해당 날짜에만 나타나고 자정 일정이 되지 않는다', () {
    final item = ScheduleItem(
      id: 'task',
      title: '가상 할 일',
      kind: ScheduleKind.unscheduled,
      category: ScheduleCategory.study,
      date: CalendarDate(2026, 2, 1),
    );
    expect(item.occursOn(CalendarDate(2026, 2, 1)), isTrue);
    expect(item.occursOn(CalendarDate(2026, 2, 2)), isFalse);
    expect(item.toJson()['startsAt'], isNull);
    expect(item.withCompleted(true).id, item.id);
  });

  test('시간표는 시작과 진행 중인 시간을 나누고 종료 시각은 비운다', () {
    final item = timed(
      'span',
      DateTime(2026, 1, 1, 9, 17),
      DateTime(2026, 1, 1, 11),
    );
    final hours = buildDayTimeline(CalendarDate(2026, 1, 1), [item]);
    expect(hours[9].starts.single.id, 'span');
    expect(hours[10].continues.single.id, 'span');
    expect(hours[11].isOccupied, isFalse);
  });

  test('전날에 시작된 일정은 다음 날 첫 시간에 상세로 표시한다', () {
    final item = timed(
      'overnight',
      DateTime(2026, 1, 1, 23),
      DateTime(2026, 1, 2, 2),
    );
    final hours = buildDayTimeline(CalendarDate(2026, 1, 2), [item]);
    expect(hours[0].starts.single.id, 'overnight');
    expect(hours[1].continues.single.id, 'overnight');
    expect(hours[2].isOccupied, isFalse);
  });

  test('입력 경계는 분 단위와 다음 날 종료를 보존한다', () {
    final item = ScheduleDraft(
      id: 'draft',
      title: '가상 야간 일정',
      note: '',
      kind: ScheduleKind.timed,
      category: ScheduleCategory.work,
      startDate: CalendarDate(2026, 1, 1),
      endDateInclusive: CalendarDate(2026, 1, 2),
      startHour: 23,
      startMinute: 53,
      endHour: 0,
      endMinute: 7,
      isCompleted: false,
    ).build();
    expect(
      item.endsAt!.difference(item.startsAt!),
      const Duration(minutes: 14),
    );
  });

  test('시각의 JSON 왕복은 같은 순간을 유지하며 시간대 없는 값은 거부한다', () {
    final item = timed(
      'utc',
      DateTime(2026, 1, 1, 9, 37),
      DateTime(2026, 1, 1, 10, 43),
    );
    final restored = ScheduleItem.fromJson(item.toJson());
    expect(restored.startsAt, item.startsAt);
    expect(restored.endsAt, item.endsAt);
    final invalid = item.toJson()..['startsAt'] = '2026-01-01T09:37:00';
    expect(() => ScheduleItem.fromJson(invalid), throwsFormatException);
  });
}
