import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../features/schedule/data/schedule_widget_sync.dart';
import '../features/schedule/domain/schedule_preferences.dart';
import '../features/schedule/domain/schedule_repository.dart';
import '../features/schedule/presentation/schedule_controller.dart';
import '../features/schedule/presentation/schedule_home.dart';
import '../features/schedule/presentation/schedule_preferences_controller.dart';
import 'app_strings.dart';
import 'app_theme.dart';

class ScheduleApp extends StatefulWidget {
  const ScheduleApp({
    super.key,
    required this.repository,
    this.preferencesRepository,
    this.widgetSync,
  });

  final ScheduleRepository repository;
  final SchedulePreferencesRepository? preferencesRepository;
  final ScheduleWidgetSync? widgetSync;

  @override
  State<ScheduleApp> createState() => _ScheduleAppState();
}

class _ScheduleAppState extends State<ScheduleApp> with WidgetsBindingObserver {
  late final ScheduleController _controller;
  late final SchedulePreferencesController _preferences;

  @override
  void initState() {
    super.initState();
    _controller = ScheduleController(widget.repository);
    _preferences = SchedulePreferencesController(widget.preferencesRepository);
    if (widget.widgetSync != null) {
      WidgetsBinding.instance.addObserver(this);
      _controller.addListener(_publishWidget);
    }
    unawaited(_controller.load());
    unawaited(_preferences.load());
  }

  void _publishWidget() {
    if (_controller.isReady &&
        !_controller.isLoading &&
        !_controller.isSaving) {
      unawaited(widget.widgetSync?.publish(_controller.items));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _publishWidget();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _preferences.dispose();
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
    home: ScheduleHome(controller: _controller, preferences: _preferences),
  );
}
