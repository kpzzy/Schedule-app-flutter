import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/core/calendar_date.dart';
import 'package:schedule_app/features/schedule/data/json_schedule_repository.dart';
import 'package:schedule_app/features/schedule/domain/schedule_item.dart';

void main() {
  late Directory directory;
  late JsonScheduleRepository repository;
  final item = ScheduleItem(
    id: 'fixture-only',
    title: '가상 테스트 일정',
    note: '실제 일정이 아닙니다.',
    kind: ScheduleKind.unscheduled,
    category: ScheduleCategory.study,
    date: CalendarDate(2026, 2, 1),
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('schedule-test-');
    repository = JsonScheduleRepository(() async => directory);
  });

  tearDown(() async => directory.delete(recursive: true));

  test('최초 실행은 빈 목록이며 저장한 일정은 새 저장소에서도 복원된다', () async {
    expect(await repository.load(), isEmpty);
    await repository.saveAll([item]);
    final reopened = JsonScheduleRepository(() async => directory);
    expect((await reopened.load()).single.toJson(), item.toJson());
    expect(
      await File('${directory.path}/schedules.json.tmp').exists(),
      isFalse,
    );
  });

  test('완료와 수정은 같은 ID를 유지하고 삭제 후 재조회는 빈 목록이다', () async {
    await repository.saveAll([item]);
    await repository.saveAll([item.withCompleted(true)]);
    expect((await repository.load()).single.isCompleted, isTrue);
    await repository.saveAll([]);
    expect(await repository.load(), isEmpty);
  });

  test('깨진 JSON을 자동으로 덮어쓰지 않는다', () async {
    final file = File('${directory.path}/schedules.json');
    await file.writeAsString('{broken');
    await expectLater(repository.load(), throwsFormatException);
    expect(await file.readAsString(), '{broken');
  });

  test('미래 스키마 버전과 중복 ID를 거부한다', () async {
    final file = File('${directory.path}/schedules.json');
    await file.writeAsString(
      jsonEncode({'schemaVersion': 3, 'items': <Object?>[]}),
    );
    await expectLater(repository.load(), throwsFormatException);
    await file.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'items': [item.toJson(), item.toJson()],
      }),
    );
    await expectLater(repository.load(), throwsFormatException);
  });

  test('버전 1 일정은 내용 그대로 읽고 첫 저장에서 버전 2로 전환한다', () async {
    final file = File('${directory.path}/schedules.json');
    await file.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'items': [item.toJson()],
      }),
    );
    final loaded = await repository.load();
    expect(loaded.single.toJson(), item.toJson());
    await repository.saveAll(loaded);
    final saved = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    expect(saved['schemaVersion'], 2);
    expect((await repository.load()).single.toJson(), item.toJson());
  });

  test('원본 교체 전 쓰기 실패 시 기존 데이터가 남고 재시도할 수 있다', () async {
    await repository.saveAll([item]);
    final blocker = Directory('${directory.path}/schedules.json.tmp');
    await blocker.create();
    await expectLater(
      repository.saveAll([]),
      throwsA(isA<FileSystemException>()),
    );
    expect((await repository.load()).single.id, item.id);
    await blocker.delete();
    await repository.saveAll([]);
    expect(await repository.load(), isEmpty);
  });

  test('겹치는 저장 요청은 순서대로 처리하며 마지막 상태를 보존한다', () async {
    final first = repository.saveAll([item]);
    final second = repository.saveAll([item.withCompleted(true)]);
    await Future.wait([first, second]);
    expect((await repository.load()).single.isCompleted, isTrue);
  });
}
