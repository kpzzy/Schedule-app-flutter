import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/calendar_date.dart';

void main() {
  test('달력 날짜로 월말, 윤년, 연말을 이동한다', () {
    expect(CalendarDate(2024, 2, 28).addDays(1), CalendarDate(2024, 2, 29));
    expect(CalendarDate(2024, 2, 29).addDays(1), CalendarDate(2024, 3, 1));
    expect(CalendarDate(2025, 12, 31).addDays(1), CalendarDate(2026, 1, 1));
    expect(CalendarDate(2025, 3, 1).addDays(-1), CalendarDate(2025, 2, 28));
  });

  test('월 이동 시 없는 말일은 해당 월의 마지막 날로 맞춘다', () {
    expect(CalendarDate(2024, 1, 31).addMonths(1), CalendarDate(2024, 2, 29));
    expect(CalendarDate(2025, 1, 31).addMonths(1), CalendarDate(2025, 2, 28));
  });

  test('일요일을 포함해 모든 주의 시작은 월요일이다', () {
    expect(CalendarDate(2026, 11, 29).startOfWeek, CalendarDate(2026, 11, 23));
    expect(CalendarDate(2026, 11, 23).startOfWeek, CalendarDate(2026, 11, 23));
  });

  test('날짜 직렬화는 시간대가 없는 값이며 잘못된 날짜를 거부한다', () {
    final date = CalendarDate(2024, 2, 29);
    expect(date.toString(), '2024-02-29');
    expect(CalendarDate.parse(date.toString()), date);
    expect(() => CalendarDate.parse('2025-02-29'), throwsArgumentError);
    expect(() => CalendarDate.parse('2025-2-1'), throwsFormatException);
  });

  test('서머타임 경계의 달력 이동도 다음 날짜를 유지한다', () {
    final spring = CalendarDate(2026, 3, 8);
    final autumn = CalendarDate(2026, 11, 1);
    expect(spring.addDays(1), CalendarDate(2026, 3, 9));
    expect(autumn.addDays(1), CalendarDate(2026, 11, 2));
    expect(spring.daysUntil(spring.addDays(1)), 1);
  });
}
