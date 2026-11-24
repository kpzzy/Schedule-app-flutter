import 'dart:convert';
import 'dart:io';

import '../domain/schedule_preferences.dart';

final class JsonSchedulePreferencesRepository
    implements SchedulePreferencesRepository {
  const JsonSchedulePreferencesRepository(this.directoryProvider);

  final Future<Directory> Function() directoryProvider;

  Future<File> _file() async =>
      File('${(await directoryProvider()).path}/schedule_preferences.json');

  @override
  Future<SchedulePreferences> load() async {
    final file = await _file();
    if (!await file.exists()) return SchedulePreferences.defaults;

    final Object? decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported preferences document');
    }
    final hour = decoded['startHour'];
    final records = decoded['categories'];
    if (hour is! int || hour < 0 || hour > 23 || records is! List<Object?>) {
      throw const FormatException('Invalid preferences');
    }
    final ids = {SchedulePreferences.uncategorized.id};
    final names = {SchedulePreferences.uncategorized.name};
    final categories = <ScheduleCategoryDefinition>[];
    for (final record in records) {
      if (record is! Map<String, Object?>) {
        throw const FormatException('Invalid category record');
      }
      final category = ScheduleCategoryDefinition.fromJson(record);
      if (!ids.add(category.id) ||
          !names.add(category.name.trim().toLowerCase())) {
        throw const FormatException('Duplicate category');
      }
      categories.add(category);
    }
    return SchedulePreferences(startHour: hour, categories: categories);
  }

  @override
  Future<void> save(SchedulePreferences preferences) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'startHour': preferences.startHour,
        'categories': preferences.categories
            .map((category) => category.toJson())
            .toList(),
      }),
      flush: true,
    );
    await temporary.rename(file.path);
  }
}
