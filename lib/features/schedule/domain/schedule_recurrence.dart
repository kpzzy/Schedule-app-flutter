import '../../../core/calendar_date.dart';

enum RecurrenceFrequency { daily, weekly, alternatingWeeks }

/// Calendar dates and wall-clock minutes in the device's local time zone.
final class ScheduleRecurrence {
  ScheduleRecurrence({
    required this.frequency,
    required this.startsOn,
    required this.daySpan,
    this.until,
    this.startMinute,
    this.endMinute,
    Set<int> firstWeek = const {},
    Set<int> secondWeek = const {},
  }) : firstWeek = Set.unmodifiable(firstWeek),
       secondWeek = Set.unmodifiable(secondWeek) {
    if (until != null && until!.compareTo(startsOn) < 0 || daySpan < 0) {
      throw ArgumentError('Invalid recurrence dates');
    }
    if ([...firstWeek, ...secondWeek].any((day) => day < 1 || day > 7) ||
        frequency == RecurrenceFrequency.weekly && firstWeek.isEmpty ||
        frequency == RecurrenceFrequency.alternatingWeeks &&
            firstWeek.isEmpty &&
            secondWeek.isEmpty) {
      throw ArgumentError('Invalid recurrence weekdays');
    }
    if ((startMinute == null) != (endMinute == null) ||
        startMinute != null &&
            (startMinute! < 0 ||
                startMinute! >= 1440 ||
                endMinute! < 0 ||
                endMinute! >= 1440 ||
                daySpan == 0 && endMinute! <= startMinute!)) {
      throw ArgumentError('Invalid recurring time range');
    }
  }

  final RecurrenceFrequency frequency;
  final CalendarDate startsOn;
  final CalendarDate? until;
  final int daySpan;
  final int? startMinute;
  final int? endMinute;
  final Set<int> firstWeek;
  final Set<int> secondWeek;

  bool includes(CalendarDate day) {
    if (day.compareTo(startsOn) < 0 ||
        until != null && day.compareTo(until!) > 0) {
      return false;
    }
    return switch (frequency) {
      RecurrenceFrequency.daily => true,
      RecurrenceFrequency.weekly => firstWeek.contains(day.weekday),
      RecurrenceFrequency.alternatingWeeks =>
        (startsOn.startOfWeek.daysUntil(day.startOfWeek) ~/ 7).isEven
            ? firstWeek.contains(day.weekday)
            : secondWeek.contains(day.weekday),
    };
  }

  DateTime? localInstant(CalendarDate day, int minute) {
    final instant = DateTime(
      day.year,
      day.month,
      day.day,
      minute ~/ 60,
      minute % 60,
    );
    // A DST gap must not silently reschedule the occurrence to a different time.
    return CalendarDate.fromLocal(instant) == day &&
            instant.hour * 60 + instant.minute == minute
        ? instant
        : null;
  }

  Map<String, Object?> toJson() => {
    'frequency': frequency.name,
    'startsOn': startsOn.toString(),
    'until': until?.toString(),
    'daySpan': daySpan,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'firstWeek': firstWeek.toList()..sort(),
    'secondWeek': secondWeek.toList()..sort(),
  };

  factory ScheduleRecurrence.fromJson(Map<String, Object?> json) {
    final until = json['until'] as String?;
    return ScheduleRecurrence(
      frequency: RecurrenceFrequency.values.byName(json['frequency'] as String),
      startsOn: CalendarDate.parse(json['startsOn'] as String),
      until: until == null ? null : CalendarDate.parse(until),
      daySpan: json['daySpan'] as int,
      startMinute: json['startMinute'] as int?,
      endMinute: json['endMinute'] as int?,
      firstWeek: (json['firstWeek'] as List<Object?>).cast<int>().toSet(),
      secondWeek: (json['secondWeek'] as List<Object?>).cast<int>().toSet(),
    );
  }
}
