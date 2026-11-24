import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'app/schedule_app.dart';
import 'features/schedule/data/json_schedule_preferences_repository.dart';
import 'features/schedule/data/json_schedule_repository.dart';
import 'features/schedule/data/schedule_widget_sync.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ScheduleApp(
      repository: JsonScheduleRepository(getApplicationSupportDirectory),
      preferencesRepository: const JsonSchedulePreferencesRepository(
        getApplicationSupportDirectory,
      ),
      widgetSync: ScheduleWidgetSync(),
    ),
  );
}
