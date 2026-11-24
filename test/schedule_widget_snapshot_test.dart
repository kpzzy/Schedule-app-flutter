import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/calendar_date.dart';
import 'package:schedule_app/features/schedule/data/schedule_widget_snapshot.dart';
import 'package:schedule_app/features/schedule/data/schedule_widget_sync.dart';
import 'package:schedule_app/features/schedule/domain/schedule_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('자정을 넘는 일정은 두 날짜에 나타나며 주간에는 한 번만 센다', () {
    final overnight = ScheduleItem(
      id: 'test-only-id',
      title: '가상 야간 일정',
      note: '위젯에 내보내지 않는 가상 메모',
      kind: ScheduleKind.timed,
      category: ScheduleCategory.personal,
      startsAt: DateTime(2026, 1, 31, 23, 48),
      endsAt: DateTime(2026, 2, 1, 1),
    );
    final data = buildScheduleWidgetSnapshot(CalendarDate(2026, 2, 1), [
      overnight,
    ]);
    final days = data['days'] as Map<String, Object>;
    expect(days['2026-01-31'], {
      'count': 1,
      'items': [
        {'lead': '23:48', 'title': overnight.title, 'done': false},
      ],
    });
    expect(days['2026-02-01'], {
      'count': 1,
      'items': [
        {'lead': '진행 중', 'title': overnight.title, 'done': false},
      ],
    });
    expect((data['weeks'] as Map<String, Object>)['2026-01-26'], 1);
    expect((data['months'] as Map<String, Object>)['2026-02'], 1);
    expect(jsonEncode(data), isNot(contains(overnight.id)));
    expect(jsonEncode(data), isNot(contains(overnight.note)));
  });

  test('간략 목록이 잘려도 날짜와 월의 일정 수는 정확하다', () {
    final today = CalendarDate(2026, 11, 24);
    final items = List.generate(
      10,
      (index) => ScheduleItem(
        id: 'fake-$index',
        title: '가상 테스트 일정 $index',
        kind: ScheduleKind.unscheduled,
        category: ScheduleCategory.personal,
        date: today,
      ),
    );
    final data = buildScheduleWidgetSnapshot(today, items);
    final days = data['days'] as Map<String, Object>;
    final preview = days[today.toString()] as Map<String, Object>;
    expect(preview['count'], 10);
    expect(preview['items'], hasLength(7));
    expect(days['2027-01-01'], {'count': 0, 'items': <Object>[]});
    expect((data['months'] as Map<String, Object>)['2026-11'], 10);
  });

  test('같은 위젯 요약을 재전송하지 않고 실패한 요약은 재시도한다', () async {
    var calls = 0;
    const channel = MethodChannel('schedule_app/home_widget');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'publish');
      expect(jsonDecode(call.arguments as String), containsPair('version', 1));
      calls++;
      if (calls == 1) throw PlatformException(code: 'temporarily-unavailable');
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final sync = ScheduleWidgetSync();
    await sync.publish([]);
    await Future.wait([sync.publish([]), sync.publish([])]);
    expect(calls, 2);
  });
}
