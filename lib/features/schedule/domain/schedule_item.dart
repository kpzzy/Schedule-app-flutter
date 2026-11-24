import 'dart:math';

import '../../../core/calendar_date.dart';
import 'schedule_recurrence.dart';

enum ScheduleKind { timed, allDay, unscheduled }

abstract final class ScheduleCategory {
  static const work = 'work';
  static const study = 'study';
  static const health = 'health';
  static const personal = 'personal';
  static const uncategorized = 'uncategorized';
}

typedef OccurrenceOrigin = ({String seriesId, CalendarDate date});

final class ScheduleItem {
  factory ScheduleItem({
    required String id,
    required String title,
    required ScheduleKind kind,
    required String category,
    String note = '',
    bool isCompleted = false,
    DateTime? startsAt,
    DateTime? endsAt,
    CalendarDate? date,
    CalendarDate? endDateExclusive,
    ScheduleRecurrence? recurrence,
    Map<CalendarDate, ScheduleItem?> overrides = const {},
    Set<CalendarDate> completedDates = const {},
    OccurrenceOrigin? origin,
  }) {
    if (id.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('ID and title must not be empty');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError('Category ID must not be empty');
    }
    if (kind == ScheduleKind.timed) {
      if (startsAt == null ||
          endsAt == null ||
          !endsAt.isAfter(startsAt) ||
          date != null ||
          endDateExclusive != null) {
        throw ArgumentError('A timed item requires a valid instant range');
      }
    } else {
      if (date == null || startsAt != null || endsAt != null) {
        throw ArgumentError('A date-only item must not contain instants');
      }
      if (kind == ScheduleKind.allDay &&
          (endDateExclusive == null || endDateExclusive.compareTo(date) <= 0)) {
        throw ArgumentError('An all-day item requires a valid date range');
      }
      if (kind == ScheduleKind.unscheduled && endDateExclusive != null) {
        throw ArgumentError('An unscheduled item has a single calendar date');
      }
    }
    if (recurrence == null &&
            (overrides.isNotEmpty || completedDates.isNotEmpty) ||
        recurrence != null &&
            (origin != null ||
                (kind == ScheduleKind.timed) !=
                    (recurrence.startMinute != null))) {
      throw ArgumentError('Invalid recurrence item');
    }
    for (final entry in overrides.entries) {
      final replacement = entry.value;
      if (replacement != null &&
          (replacement.recurrence != null ||
              replacement.origin != null ||
              replacement.id != occurrenceId(id, entry.key))) {
        throw ArgumentError('Invalid recurrence replacement');
      }
    }
    return ScheduleItem._(
      id: id,
      title: title.trim(),
      kind: kind,
      category: category,
      note: note.trim(),
      isCompleted: isCompleted,
      startsAt: startsAt?.toUtc(),
      endsAt: endsAt?.toUtc(),
      date: date,
      endDateExclusive: endDateExclusive,
      recurrence: recurrence,
      overrides: Map.unmodifiable(overrides),
      completedDates: Set.unmodifiable(completedDates),
      origin: origin,
    );
  }

  const ScheduleItem._({
    required this.id,
    required this.title,
    required this.kind,
    required this.category,
    required this.note,
    required this.isCompleted,
    this.startsAt,
    this.endsAt,
    this.date,
    this.endDateExclusive,
    this.recurrence,
    this.overrides = const {},
    this.completedDates = const {},
    this.origin,
  });

  final String id;
  final String title;
  final ScheduleKind kind;
  final String category;
  final String note;
  final bool isCompleted;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final CalendarDate? date;
  final CalendarDate? endDateExclusive;
  final ScheduleRecurrence? recurrence;
  final Map<CalendarDate, ScheduleItem?> overrides;
  final Set<CalendarDate> completedDates;
  final OccurrenceOrigin? origin;

  CalendarDate get startDate =>
      recurrence?.startsOn ?? date ?? CalendarDate.fromLocal(startsAt!);

  static String occurrenceId(String seriesId, CalendarDate date) =>
      '$seriesId@$date';

  bool occursOn(CalendarDate day) => occursIn(day, day.addDays(1));

  /// Both query and item ranges include the start and exclude the end.
  bool occursIn(CalendarDate start, CalendarDate endExclusive) {
    if (endExclusive.compareTo(start) <= 0) {
      return false;
    }
    if (kind == ScheduleKind.timed) {
      return startsAt!.isBefore(endExclusive.localMidnight) &&
          endsAt!.isAfter(start.localMidnight);
    }
    final end = endDateExclusive ?? date!.addDays(1);
    return date!.compareTo(endExclusive) < 0 && end.compareTo(start) > 0;
  }

  bool overlaps(ScheduleItem other) =>
      kind == ScheduleKind.timed &&
      other.kind == ScheduleKind.timed &&
      startsAt!.isBefore(other.endsAt!) &&
      endsAt!.isAfter(other.startsAt!);

  ScheduleItem withCompleted(bool value) =>
      _copy(completed: value, occurrence: origin);

  ScheduleItem withOrigin(OccurrenceOrigin? value) => _copy(occurrence: value);

  ScheduleItem withSeriesChanges({
    Map<CalendarDate, ScheduleItem?>? overrides,
    Set<CalendarDate>? completedDates,
  }) => _copy(
    replacements: overrides == null ? null : Map.unmodifiable(overrides),
    completedDays: completedDates == null
        ? null
        : Set.unmodifiable(completedDates),
  );

  ScheduleItem _copy({
    bool? completed,
    OccurrenceOrigin? occurrence,
    Map<CalendarDate, ScheduleItem?>? replacements,
    Set<CalendarDate>? completedDays,
  }) => ScheduleItem._(
    id: id,
    title: title,
    kind: kind,
    category: category,
    note: note,
    isCompleted: completed ?? isCompleted,
    startsAt: startsAt,
    endsAt: endsAt,
    date: date,
    endDateExclusive: endDateExclusive,
    recurrence: recurrence,
    overrides: replacements ?? overrides,
    completedDates: completedDays ?? completedDates,
    origin: occurrence,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'category': category,
    'note': note,
    'isCompleted': isCompleted,
    'startsAt': startsAt?.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
    'date': date?.toString(),
    'endDateExclusive': endDateExclusive?.toString(),
    if (recurrence case final rule?) 'recurrence': rule.toJson(),
    if (overrides.isNotEmpty)
      'overrides': {
        for (final entry in overrides.entries)
          entry.key.toString(): entry.value?.toJson(),
      },
    if (completedDates.isNotEmpty)
      'completedDates': completedDates.map((day) => day.toString()).toList()
        ..sort(),
  };

  factory ScheduleItem.fromJson(Map<String, Object?> json) {
    DateTime? instant(String key) {
      final value = json[key] as String?;
      if (value == null) return null;
      final parsed = DateTime.parse(value);
      if (!parsed.isUtc) {
        throw const FormatException('Stored instants require a UTC offset');
      }
      return parsed;
    }

    final rule = json['recurrence'] as Map<String, Object?>?;
    final replacements = json['overrides'] as Map<String, Object?>? ?? {};
    return ScheduleItem(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: ScheduleKind.values.byName(json['kind'] as String),
      category: json['category'] as String,
      note: json['note'] as String,
      isCompleted: json['isCompleted'] as bool,
      startsAt: instant('startsAt'),
      endsAt: instant('endsAt'),
      date: json['date'] == null
          ? null
          : CalendarDate.parse(json['date'] as String),
      endDateExclusive: json['endDateExclusive'] == null
          ? null
          : CalendarDate.parse(json['endDateExclusive'] as String),
      recurrence: rule == null ? null : ScheduleRecurrence.fromJson(rule),
      overrides: {
        for (final entry in replacements.entries)
          CalendarDate.parse(entry.key): entry.value == null
              ? null
              : ScheduleItem.fromJson(entry.value as Map<String, Object?>),
      },
      completedDates: (json['completedDates'] as List<Object?>? ?? const [])
          .cast<String>()
          .map(CalendarDate.parse)
          .toSet(),
    );
  }

  static String newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
