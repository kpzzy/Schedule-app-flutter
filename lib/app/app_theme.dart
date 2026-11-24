import 'package:material_ui/material_ui.dart';

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

  static Color? weekendColor(int weekday) => switch (weekday) {
    DateTime.saturday => const Color(0xFF2356AA),
    DateTime.sunday => const Color(0xFFAE2730),
    _ => null,
  };
}
