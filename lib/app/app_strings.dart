import '../core/calendar_date.dart';
import '../features/schedule/domain/schedule_item.dart';

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
  static const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  static String kindName(ScheduleKind value) => switch (value) {
    ScheduleKind.timed => '시간 지정',
    ScheduleKind.allDay => '종일',
    ScheduleKind.unscheduled => '시간 미정',
  };

  static String categoryName(ScheduleCategory value) => switch (value) {
    ScheduleCategory.work => '업무',
    ScheduleCategory.study => '공부',
    ScheduleCategory.health => '운동',
    ScheduleCategory.personal => '개인',
  };

  static String date(CalendarDate value) =>
      '${value.year}년 ${value.month}월 ${value.day}일 (${weekdays[value.weekday - 1]})';

  static String shortDate(CalendarDate value) =>
      '${value.month}/${value.day} (${weekdays[value.weekday - 1]})';

  static String monthTitle(CalendarDate value) =>
      '${value.year}년 ${value.month}월';
  static String count(int count) => '일정 $count개';
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
