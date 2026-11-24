import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schedule_app/app/app_strings.dart';
import 'package:schedule_app/app/schedule_app.dart';
import 'package:schedule_app/app/app_theme.dart';
import 'package:schedule_app/core/calendar_date.dart';
import 'package:schedule_app/features/schedule/domain/schedule_item.dart';
import 'package:schedule_app/features/schedule/domain/schedule_preferences.dart';
import 'package:schedule_app/features/schedule/domain/schedule_recurrence.dart';

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
  testWidgets('일간 시작 시각을 바꾸고 펼쳐서 이전 시간의 일정을 읽을 수 있다', (tester) async {
    final today = CalendarDate.fromLocal(DateTime.now());
    final repository = FakeScheduleRepository()
      ..stored = [
        ScheduleItem(
          id: 'test-early',
          title: '가상 이른 일정',
          kind: ScheduleKind.timed,
          category: ScheduleCategory.personal,
          startsAt: DateTime(today.year, today.month, today.day, 6, 10),
          endsAt: DateTime(today.year, today.month, today.day, 6, 40),
        ),
      ];
    await startApp(tester, repository);
    final earlier = find.text(AppStrings.earlierHours(7));
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('06:00'), findsNothing);
    expect(find.textContaining(AppStrings.count(1)), findsOneWidget);
    await tester.tap(earlier);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('가상 이른 일정'), 150);
    expect(find.text('가상 이른 일정'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${AppStrings.dayStartHour} · 07:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('03:00'));
    await tester.pumpAndSettle();
    expect(find.text('${AppStrings.dayStartHour} · 03:00'), findsOneWidget);
    await tester.tap(find.text(AppStrings.homeWidgetHelp));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.homeWidgetAndroid), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('03:00'), findsOneWidget);
    expect(find.text(AppStrings.earlierHours(3)), findsOneWidget);
  });

  testWidgets('카테고리를 추가·수정·삭제하고 기존 일정은 미분류로 보인다', (tester) async {
    final repository = FakeScheduleRepository();
    const original = '가상 프로젝트';
    const renamed = '가상 계획';
    await startApp(tester, repository);
    await tester.tap(find.byTooltip(AppStrings.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addCategory));
    await tester.pumpAndSettle();
    final name = find.byType(TextFormField);
    await tester.enterText(name, ' 공부 ');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.duplicateCategoryName), findsOneWidget);
    await tester.enterText(name, original);
    final red = find.widgetWithText(ChoiceChip, '빨강');
    await tester.ensureVisible(red);
    await tester.tap(red);
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(AppStrings.addSchedule));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '가상 카테고리 일정');
    final picker = find.byType(
      DropdownButtonFormField<ScheduleCategoryDefinition>,
    );
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text(original));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    final saved = repository.stored.single;
    expect(
      tester.widget<Text>(find.text(original)).style?.color,
      const Color(0xFFAE2730),
    );

    await tester.tap(find.byTooltip(AppStrings.settings));
    await tester.pumpAndSettle();
    final edit = find.byTooltip(
      AppStrings.namedCategoryAction(AppStrings.editCategory, original),
    );
    await tester.scrollUntilVisible(edit, 150);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.enterText(name, renamed);
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(renamed), findsOneWidget);
    expect(repository.stored.single.category, saved.category);

    await tester.tap(find.byTooltip(AppStrings.settings));
    await tester.pumpAndSettle();
    final delete = find.byTooltip(
      AppStrings.namedCategoryAction(AppStrings.deleteCategory, renamed),
    );
    await tester.scrollUntilVisible(delete, 150);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(saved.title), findsOneWidget);
    expect(find.text(SchedulePreferences.uncategorized.name), findsOneWidget);
    expect(repository.stored.single.id, saved.id);
  });

  testWidgets('작은 월간 화면은 달력 아래에 전체 제목을 표시하고 주말 요일을 구분한다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final today = CalendarDate.fromLocal(DateTime.now());
    const title = '작은 화면에서도 두 줄 이상으로 읽을 수 있는 가상의 월간 일정 제목입니다';
    final repository = FakeScheduleRepository()
      ..stored = [
        ScheduleItem(
          id: 'test-month',
          title: title,
          kind: ScheduleKind.unscheduled,
          category: ScheduleCategory.personal,
          date: today,
        ),
      ];
    await startApp(tester, repository);
    await tester.tap(find.text(AppStrings.month));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('토')).style?.color,
      AppTheme.weekendColor(DateTime.saturday),
    );
    expect(
      tester.widget<Text>(find.text('일')).style?.color,
      AppTheme.weekendColor(DateTime.sunday),
    );
    await tester.scrollUntilVisible(
      find.text(title),
      150,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(tester.widget<Text>(find.text(title)).maxLines, isNull);
    expect(find.text(AppStrings.monthAgenda), findsOneWidget);
  });

  testWidgets('기존 단일 일정을 매일 반복으로 바꾸고 회차 편집 범위를 고른다', (tester) async {
    final today = CalendarDate.fromLocal(DateTime.now());
    const title = '가상 반복 전환 일정';
    final repository = FakeScheduleRepository()
      ..stored = [
        ScheduleItem(
          id: 'test-to-repeat',
          title: title,
          kind: ScheduleKind.unscheduled,
          category: ScheduleCategory.study,
          date: today,
        ),
      ];
    await startApp(tester, repository);
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    final field = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(AppStrings.repeatName(RecurrenceFrequency.daily)).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    expect(
      repository.stored.single.recurrence?.frequency,
      RecurrenceFrequency.daily,
    );

    await tester.tap(find.byTooltip(AppStrings.next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.editSeries), findsOneWidget);
    await tester.tap(find.text(AppStrings.editOccurrence));
    await tester.pumpAndSettle();
    expect(field, findsNothing);
    expect(find.text(AppStrings.date(today.addDays(1))), findsOneWidget);
  });

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
    await tester.scrollUntilVisible(
      find.text('가상 독서'),
      150,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
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
