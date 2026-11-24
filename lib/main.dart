import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'app/schedule_app.dart';
import 'features/schedule/data/json_schedule_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ScheduleApp(
      repository: JsonScheduleRepository(getApplicationSupportDirectory),
    ),
  );
}
