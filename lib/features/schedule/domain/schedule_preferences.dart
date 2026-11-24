import 'schedule_item.dart';

final class ScheduleCategoryDefinition {
  const ScheduleCategoryDefinition(this.id, this.name, this.color);

  final String id;
  final String name;
  final int color;

  factory ScheduleCategoryDefinition.fromJson(Map<String, Object?> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    final color = json['color'] as int;
    if (id.isEmpty ||
        name.trim().isEmpty ||
        color < 0xFF000000 ||
        color > 0xFFFFFFFF) {
      throw const FormatException('Invalid category');
    }
    return ScheduleCategoryDefinition(id, name, color);
  }

  Map<String, Object> toJson() => {'id': id, 'name': name, 'color': color};
}

final class SchedulePreferences {
  SchedulePreferences({
    required this.startHour,
    required Iterable<ScheduleCategoryDefinition> categories,
  }) : categories = List.unmodifiable(categories);

  static final defaults = SchedulePreferences(
    startHour: 7,
    categories: const [
      ScheduleCategoryDefinition(ScheduleCategory.work, '업무', 0xFF315CA8),
      ScheduleCategoryDefinition(ScheduleCategory.study, '공부', 0xFF7854A0),
      ScheduleCategoryDefinition(ScheduleCategory.health, '운동', 0xFF287453),
      ScheduleCategoryDefinition(ScheduleCategory.personal, '개인', 0xFFAA5B2C),
    ],
  );

  static const uncategorized = ScheduleCategoryDefinition(
    ScheduleCategory.uncategorized,
    '미분류',
    0xFF555E65,
  );

  final int startHour;
  final List<ScheduleCategoryDefinition> categories;

  ScheduleCategoryDefinition categoryFor(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return uncategorized;
  }

  bool hasCategoryName(String name, {String? exceptId}) {
    final normalized = name.trim().toLowerCase();
    return normalized == uncategorized.name ||
        categories.any(
          (category) =>
              category.id != exceptId &&
              category.name.trim().toLowerCase() == normalized,
        );
  }

  SchedulePreferences copyWith({
    int? startHour,
    Iterable<ScheduleCategoryDefinition>? categories,
  }) => SchedulePreferences(
    startHour: startHour ?? this.startHour,
    categories: categories ?? this.categories,
  );
}

abstract interface class SchedulePreferencesRepository {
  Future<SchedulePreferences> load();
  Future<void> save(SchedulePreferences preferences);
}
