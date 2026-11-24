/// A calendar date, independent of time zone. Never serialize it as an instant.
final class CalendarDate implements Comparable<CalendarDate> {
  factory CalendarDate(int year, int month, int day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError('Invalid calendar date');
    }
    return CalendarDate._(year, month, day);
  }

  const CalendarDate._(this.year, this.month, this.day);

  factory CalendarDate.fromLocal(DateTime value) {
    final local = value.toLocal();
    return CalendarDate(local.year, local.month, local.day);
  }

  factory CalendarDate.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Invalid calendar date');
    }
    final parts = value.split('-').map(int.parse).toList();
    return CalendarDate(parts[0], parts[1], parts[2]);
  }

  final int year;
  final int month;
  final int day;

  DateTime get localMidnight => DateTime(year, month, day);
  DateTime get _utcDate => DateTime.utc(year, month, day);
  int get weekday => _utcDate.weekday;
  CalendarDate get firstOfMonth => CalendarDate(year, month, 1);
  CalendarDate get startOfWeek => addDays(1 - weekday);

  CalendarDate addDays(int days) {
    final date = DateTime.utc(year, month, day + days);
    return CalendarDate(date.year, date.month, date.day);
  }

  /// Clamps the day when moving between months of different lengths.
  CalendarDate addMonths(int months) {
    final first = DateTime.utc(year, month + months);
    final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
    return CalendarDate(first.year, first.month, day > lastDay ? lastDay : day);
  }

  int daysUntil(CalendarDate other) =>
      other._utcDate.difference(_utcDate).inDays;

  @override
  int compareTo(CalendarDate other) => _utcDate.compareTo(other._utcDate);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
