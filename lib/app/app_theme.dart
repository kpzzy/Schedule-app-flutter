import 'package:material_ui/material_ui.dart';

import '../features/schedule/domain/schedule_item.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF47664C)),
    scaffoldBackgroundColor: const Color(0xFFF8F9F5),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xFFF8F9F5),
    ),
  );

  static Color categoryColor(ScheduleCategory value) => switch (value) {
    ScheduleCategory.work => const Color(0xFF315CA8),
    ScheduleCategory.study => const Color(0xFF7854A0),
    ScheduleCategory.health => const Color(0xFF287453),
    ScheduleCategory.personal => const Color(0xFFAA5B2C),
  };

  static Color? weekendColor(int weekday) => switch (weekday) {
    DateTime.saturday => const Color(0xFF2356AA),
    DateTime.sunday => const Color(0xFFAE2730),
    _ => null,
  };
}
