import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schedule_app/app/app_strings.dart';
import 'package:schedule_app/app/schedule_app.dart';
import 'package:schedule_app/core/calendar_date.dart';
import 'package:schedule_app/features/schedule/domain/schedule_item.dart';

import 'support/fake_schedule_repository.dart';

Future<void> startApp(
  WidgetTester tester,
  FakeScheduleRepository repository,
) async {
  await tester.pumpWidget(ScheduleApp(repository: repository));
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

void main() {
  testWidgets('빈 상태에서 추가한 일정은 일간·주간·월간에 함께 나타난다', (tester) async {
    final repository = FakeScheduleRepository();
    await startApp(tester, repository);
    expect(find.text(AppStrings.emptyDay), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.addSchedule));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '가상 독서');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    expect(repository.stored.single.title, '가상 독서');
    expect(find.text('가상 독서'), findsOneWidget);

    await tester.tap(find.text(AppStrings.week));
    await tester.pumpAndSettle();
    // ListView may lazily build the selected date near the end of the week.
    await tester.scrollUntilVisible(find.text('가상 독서'), 200);
    expect(find.text('가상 독서'), findsOneWidget);
    await tester.tap(find.text(AppStrings.month));
    await tester.pumpAndSettle();
    expect(find.text('가상 독서'), findsOneWidget);
  });

  testWidgets('제목 수정과 삭제는 저장소에 반영된다', (tester) async {
    final repository = FakeScheduleRepository()
      ..stored = [
        ScheduleItem(
          id: 'edit-fixture',
          title: '가상 수정 전',
          kind: ScheduleKind.unscheduled,
          category: ScheduleCategory.personal,
          date: CalendarDate.fromLocal(DateTime.now()),
        ),
      ];
    await startApp(tester, repository);
    await tester.tap(find.text('가상 수정 전'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '가상 수정 후');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    expect(repository.stored.single.id, 'edit-fixture');
    expect(repository.stored.single.title, '가상 수정 후');
    await tester.tap(find.text('가상 수정 후'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
    await tester.pumpAndSettle();
    expect(repository.stored, isEmpty);
    expect(find.text(AppStrings.emptyDay), findsOneWidget);
  });

  testWidgets('저장이 실패하면 편집 화면과 입력을 보존하고 재시도한다', (tester) async {
    final repository = FakeScheduleRepository()..failSave = true;
    await startApp(tester, repository);
    await tester.tap(find.byTooltip(AppStrings.addSchedule));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '가상 재시도');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.saveFailure), findsOneWidget);
    expect(find.text('가상 재시도'), findsOneWidget);
    expect(repository.stored, isEmpty);
    repository.failSave = false;
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    expect(repository.stored.single.title, '가상 재시도');
  });

  testWidgets('불러오기 실패는 편집을 막고 다시 불러오기를 제공한다', (tester) async {
    final repository = FakeScheduleRepository()..failLoad = true;
    await startApp(tester, repository);
    expect(find.text(AppStrings.loadFailure), findsOneWidget);
    expect(find.byTooltip(AppStrings.addSchedule), findsNothing);
    repository.failLoad = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.byTooltip(AppStrings.addSchedule), findsOneWidget);
  });

  testWidgets('일정 편집 화면의 날짜와 시간 선택기가 한국어로 열린다', (tester) async {
    await startApp(tester, FakeScheduleRepository());
    await tester.tap(find.byTooltip(AppStrings.addSchedule));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, AppStrings.singleDate));
    await tester.pumpAndSettle();
    final dateDialog = find.byType(DatePickerDialog);
    expect(
      find.descendant(of: dateDialog, matching: find.text('날짜 선택')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: dateDialog, matching: find.text(AppStrings.cancel)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<ScheduleKind>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.kindName(ScheduleKind.timed)).last);
    await tester.pumpAndSettle();
    final startTime = find.widgetWithText(ListTile, AppStrings.startTime);
    await tester.ensureVisible(startTime);
    await tester.tap(startTime);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.text('시간 입력'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('보기 전환은 선택 날짜를 보존하고 월간 날짜는 일간으로 연결된다', (tester) async {
    final today = CalendarDate.fromLocal(DateTime.now());
    final tomorrow = today.addDays(1);
    await startApp(tester, FakeScheduleRepository());
    await tester.tap(find.byTooltip(AppStrings.next));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.date(tomorrow)), findsOneWidget);
    await tester.tap(find.text(AppStrings.week));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.day));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.date(tomorrow)), findsOneWidget);
    await tester.tap(find.text(AppStrings.month));
    await tester.pumpAndSettle();
    final cell = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label?.startsWith(
                '${AppStrings.date(tomorrow)} ·',
              ) ??
              false),
    );
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.date(tomorrow)), findsOneWidget);
  });

  testWidgets('작은 화면과 큰 글자에서도 전환과 저장 버튼을 사용할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await startApp(tester, FakeScheduleRepository());
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(AppStrings.month));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip(AppStrings.addSchedule));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.save).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
