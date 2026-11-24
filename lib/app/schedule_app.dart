import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../features/schedule/domain/schedule_repository.dart';
import '../features/schedule/presentation/schedule_controller.dart';
import '../features/schedule/presentation/schedule_home.dart';
import 'app_strings.dart';
import 'app_theme.dart';

class ScheduleApp extends StatefulWidget {
  const ScheduleApp({super.key, required this.repository});

  final ScheduleRepository repository;

  @override
  State<ScheduleApp> createState() => _ScheduleAppState();
}

class _ScheduleAppState extends State<ScheduleApp> {
  late final ScheduleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScheduleController(widget.repository);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppStrings.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ScheduleHome(controller: _controller),
  );
}
