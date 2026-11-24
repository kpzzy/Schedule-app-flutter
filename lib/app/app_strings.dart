import '../core/calendar_date.dart';
import '../features/schedule/domain/schedule_item.dart';
import '../features/schedule/domain/schedule_recurrence.dart';

/// Keep app-owned Korean copy here; Flutter localizes its built-in pickers.
abstract final class AppStrings {
  static const appName = '하루 계획';
  static const subtitle = '나의 시간을 차근차근';
  static const day = '일간';
  static const week = '주간';
  static const month = '월간';
  static const today = '오늘';
  static const previous = '이전 기간';
  static const next = '다음 기간';
  static const chooseDate = '날짜 선택';
  static const addSchedule = '일정 추가';
  static const editSchedule = '일정 수정';
  static const title = '제목';
  static const titleHint = '어떤 일을 계획하고 있나요?';
  static const titleRequired = '제목을 입력해 주세요.';
  static const note = '메모';
  static const category = '카테고리';
  static const settings = '환경설정';
  static const dayStartHour = '일간 화면 시작 시각';
  static const earlierHoursHint = '시작 시각 이전의 일정은 일간 화면에서 펼쳐 볼 수 있어요.';
  static const settingsLoadFailure = '환경설정을 불러오지 못했습니다.';
  static const manageCategories = '카테고리 관리';
  static const addCategory = '카테고리 추가';
  static const editCategory = '카테고리 수정';
  static const deleteCategory = '카테고리 삭제';
  static const categoryName = '이름';
  static const categoryNameRequired = '카테고리 이름을 입력해 주세요.';
  static const duplicateCategoryName = '이미 사용 중인 이름입니다.';
  static const categoryColor = '색상';
  static const categoryColorNames = [
    '파랑',
    '보라',
    '초록',
    '주황',
    '빨강',
    '청록',
    '분홍',
    '회색',
  ];
  static const deletedCategoryHint = '이 카테고리의 일정은 미분류로 표시됩니다.';
  static const homeWidgetHelp = '휴대폰 홈 화면 위젯';
  static const homeWidgetAndroid =
      '홈 화면의 빈 곳을 길게 눌러 위젯에서 하루 계획을 추가하세요. 위젯의 점 세 개 버튼으로 일간·주간·월간을 바꾸고, 위젯을 길게 눌러 크기를 조절할 수 있어요.';
  static const homeWidgetIos =
      'iOS 17 이상에서 홈 화면의 위젯 갤러리를 열고 하루 계획을 추가하세요. 위젯을 길게 누른 뒤 위젯 편집의 보기 방식에서 일간·주간·월간을 선택할 수 있어요.';
  static const kind = '일정 유형';
  static const startDate = '시작 날짜';
  static const endDate = '종료 날짜';
  static const singleDate = '날짜';
  static const startTime = '시작 시각';
  static const endTime = '종료 시각';
  static const save = '저장';
  static const saving = '저장 중…';
  static const cancel = '취소';
  static const delete = '삭제';
  static const deleteTitle = '일정을 삭제할까요?';
  static const deleteMessage = '삭제하면 일간·주간·월간 화면에서 함께 사라집니다.';
  static const invalidTimeRange = '종료 날짜와 시각은 시작보다 뒤여야 합니다.';
  static const invalidDateRange = '종료 날짜는 시작 날짜와 같거나 뒤여야 합니다.';
  static const invalidLocalTime = '이 시간은 기기의 시간대에서 존재하지 않습니다. 다른 시간을 선택해 주세요.';
  static const emptyDay = '아직 일정이 없어요';
  static const emptyHint = '일정을 추가하거나 빈 시간대를 눌러 보세요.';
  static const emptyWeekDay = '여유 있는 하루';
  static const freeTime = '빈 시간';
  static const skippedTime = '시간대 변경으로 건너뛴 시간';
  static const ongoing = '진행 중';
  static const dateOnly = '종일 · 시간 미정';
  static const timeline = '시간별 계획';
  static const completed = '완료';
  static const complete = '완료 처리';
  static const undoComplete = '완료 취소';
  static const loading = '일정을 불러오는 중';
  static const loadFailure = '일정을 불러오지 못했습니다. 기존 데이터를 보호하기 위해 편집을 잠시 멈췄습니다.';
  static const saveFailure = '저장하지 못했습니다. 입력 내용은 그대로입니다. 다시 시도해 주세요.';
  static const updateFailure = '변경을 저장하지 못했습니다. 다시 시도해 주세요.';
  static const retry = '다시 불러오기';
  static const monthHint = '날짜를 누르면 일간 계획을 볼 수 있어요.';
  static const weekHint = '시간 막대에서 일정이 있는 구간을 확인하세요.';
  static const overlapHint = '다른 일정과 시간이 겹칩니다. 그대로 저장할 수 있어요.';
  static const allDayHint = '종료 날짜까지 포함합니다.';
  static const monthAgenda = '이번 달 일정';
  static const emptyMonth = '이 달에 등록된 일정이 없어요.';
  static const repeat = '반복';
  static const noRepeat = '반복 안 함';
  static const repeatDays = '반복 요일';
  static const firstWeek = '1주차';
  static const secondWeek = '2주차';
  static const repeatWeeksHint = '시작일이 속한 월요일부터 1주차로 계산하며 시작일 이전은 제외합니다.';
  static const repeatEnd = '반복 종료일';
  static const noRepeatEnd = '종료일 없음';
  static const invalidRepeatDays = '반복할 요일을 하나 이상 골라 주세요.';
  static const invalidRepeatEnd = '반복 종료일은 시작일과 같거나 뒤여야 합니다.';
  static const invalidRepeatWindow = '선택한 요일에 해당하는 날짜가 없습니다. 종료일이나 요일을 바꿔 주세요.';
  static const chooseRepeatScope = '어느 일정을 편집할까요?';
  static const editOccurrence = '이 날짜의 일정만';
  static const editSeries = '반복 일정 전체';
  static const deleteOccurrence = '이 날짜의 일정만 삭제할까요?';
  static const deleteSeries = '반복 일정 전체를 삭제할까요?';
  static const occurrenceDeleteMessage = '다른 날짜의 반복 일정은 그대로 유지됩니다.';
  static const seriesDeleteMessage = '개별 수정하거나 완료한 날짜의 일정도 함께 삭제됩니다.';
  static const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  static String repeatName(RecurrenceFrequency? frequency) =>
      switch (frequency) {
        null => noRepeat,
        RecurrenceFrequency.daily => '매일',
        RecurrenceFrequency.weekly => '매주',
        RecurrenceFrequency.alternatingWeeks => '격주 (1·2주차)',
      };

  static String kindName(ScheduleKind value) => switch (value) {
    ScheduleKind.timed => '시간 지정',
    ScheduleKind.allDay => '종일',
    ScheduleKind.unscheduled => '시간 미정',
  };

  static String namedCategoryAction(String action, String name) =>
      '$action ($name)';

  static String earlierHours(int startHour) =>
      '이전 시간대 (00:00–${timeParts(startHour - 1, 59)})';

  static String date(CalendarDate value) =>
      '${value.year}년 ${value.month}월 ${value.day}일 (${weekdays[value.weekday - 1]})';

  static String shortDate(CalendarDate value) =>
      '${value.month}/${value.day} (${weekdays[value.weekday - 1]})';

  static String monthTitle(CalendarDate value) =>
      '${value.year}년 ${value.month}월';
  static String count(int count) => '일정 $count개';
  static String compactCount(int count) => '$count개';
  static String completedCount(int done, int total) => '$total개 중 $done개 완료';
  static String more(int count) => '+$count개';
  static String now(DateTime value) => '현재 ${time(value)}';
  static String hour(int hour) => '${hour.toString().padLeft(2, '0')}:00';
  static String addAtHour(int value) => '${hour(value)} $addSchedule';
  static String timeParts(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  static String time(DateTime value) => timeParts(value.hour, value.minute);

  static String itemTime(ScheduleItem item) {
    if (item.kind != ScheduleKind.timed) {
      if (item.kind == ScheduleKind.allDay &&
          item.date!.daysUntil(item.endDateExclusive!) > 1) {
        return '${kindName(item.kind)} · ${shortDate(item.date!)} – '
            '${shortDate(item.endDateExclusive!.addDays(-1))}';
      }
      return kindName(item.kind);
    }
    final start = item.startsAt!.toLocal();
    final end = item.endsAt!.toLocal();
    if (CalendarDate.fromLocal(start) == CalendarDate.fromLocal(end)) {
      return '${time(start)} – ${time(end)}';
    }
    return '${shortDate(CalendarDate.fromLocal(start))} ${time(start)} – '
        '${shortDate(CalendarDate.fromLocal(end))} ${time(end)}';
  }
}
