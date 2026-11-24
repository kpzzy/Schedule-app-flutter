import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/calendar_date.dart';
import 'package:schedule_app/features/schedule/domain/schedule_item.dart';
import 'package:schedule_app/features/schedule/presentation/schedule_controller.dart';

import 'support/fake_schedule_repository.dart';

void main() {
  late FakeScheduleRepository repository;
  late ScheduleController controller;
  final day = CalendarDate(2026, 11, 24);
  final item = ScheduleItem(
    id: 'test-item',
    title: '가상 일정',
    kind: ScheduleKind.unscheduled,
    category: ScheduleCategory.work,
    date: day,
  );

  setUp(() {
    repository = FakeScheduleRepository();
    controller = ScheduleController(repository);
  });
  tearDown(() => controller.dispose());

  test('생성·수정·완료·삭제가 일간·주간·월간 조회에 함께 반영된다', () async {
    await controller.load();
    expect(await controller.upsert(item), isTrue);
    expect(controller.onDay(day).single.id, item.id);
    expect(
      controller.inRange(day.startOfWeek, day.startOfWeek.addDays(7)).single.id,
      item.id,
    );
    expect(
      controller
          .inRange(day.firstOfMonth, day.firstOfMonth.addMonths(1))
          .single
          .id,
      item.id,
    );
    expect(await controller.toggleCompleted(item), isTrue);
    expect(controller.onDay(day).single.isCompleted, isTrue);
    expect(await controller.delete(item.id), isTrue);
    expect(controller.items, isEmpty);
    expect(repository.stored, isEmpty);
  });

  test('저장 실패는 메모리 상태를 바꾸지 않고 다음 저장으로 복구된다', () async {
    await controller.load();
    await controller.upsert(item);
    repository.failSave = true;
    expect(await controller.delete(item.id), isFalse);
    expect(controller.onDay(day).single.id, item.id);
    expect(controller.failure, ScheduleFailure.save);
    repository.failSave = false;
    expect(await controller.delete(item.id), isTrue);
    expect(controller.failure, isNull);
  });

  test('불러오기 실패 후에는 원본을 덮어쓰지 않으며 다시 불러올 수 있다', () async {
    repository.failLoad = true;
    await controller.load();
    expect(controller.isReady, isFalse);
    expect(await controller.upsert(item), isFalse);
    expect(repository.writeCount, 0);
    repository.failLoad = false;
    await controller.load();
    expect(controller.isReady, isTrue);
  });

  test('저장 중 추가 변경은 거부하고 완료 전에는 성공 상태를 노출하지 않는다', () async {
    await controller.load();
    repository.saveGate = Completer<void>();
    final pending = controller.upsert(item);
    expect(controller.isSaving, isTrue);
    expect(controller.items, isEmpty);
    expect(await controller.delete(item.id), isFalse);
    repository.saveGate!.complete();
    expect(await pending, isTrue);
    expect(controller.items.single.id, item.id);
  });

  test('편집으로 날짜를 옮겨도 ID와 하나의 원본만 유지된다', () async {
    await controller.load();
    await controller.upsert(item);
    final moved = ScheduleItem(
      id: item.id,
      title: '수정한 가상 일정',
      kind: item.kind,
      category: item.category,
      date: day.addDays(1),
    );
    await controller.upsert(moved);
    expect(controller.onDay(day), isEmpty);
    expect(controller.onDay(day.addDays(1)).single.title, moved.title);
    expect(controller.items, hasLength(1));
  });
}
