import 'dart:math';

import '../../../core/calendar_date.dart';

enum ScheduleKind { timed, allDay, unscheduled }

enum ScheduleCategory { work, study, health, personal }

final class ScheduleItem {
  factory ScheduleItem({
    required String id,
    required String title,
    required ScheduleKind kind,
    required ScheduleCategory category,
    String note = '',
    bool isCompleted = false,
    DateTime? startsAt,
    DateTime? endsAt,
    CalendarDate? date,
    CalendarDate? endDateExclusive,
  }) {
    if (id.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('ID and title must not be empty');
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
  });

  final String id;
  final String title;
  final ScheduleKind kind;
  final ScheduleCategory category;
  final String note;
  final bool isCompleted;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final CalendarDate? date;
  final CalendarDate? endDateExclusive;

  CalendarDate get startDate => date ?? CalendarDate.fromLocal(startsAt!);

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

  ScheduleItem withCompleted(bool value) => ScheduleItem._(
    id: id,
    title: title,
    kind: kind,
    category: category,
    note: note,
    isCompleted: value,
    startsAt: startsAt,
    endsAt: endsAt,
    date: date,
    endDateExclusive: endDateExclusive,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'category': category.name,
    'note': note,
    'isCompleted': isCompleted,
    'startsAt': startsAt?.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
    'date': date?.toString(),
    'endDateExclusive': endDateExclusive?.toString(),
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

    return ScheduleItem(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: ScheduleKind.values.byName(json['kind'] as String),
      category: ScheduleCategory.values.byName(json['category'] as String),
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
