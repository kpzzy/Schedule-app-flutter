import 'package:flutter/foundation.dart';

import '../domain/schedule_preferences.dart';

final class SchedulePreferencesController extends ChangeNotifier {
  SchedulePreferencesController(this._repository);

  final SchedulePreferencesRepository? _repository;
  SchedulePreferences _value = SchedulePreferences.defaults;
  bool _loading = false;
  bool _loadFailed = false;
  bool _saving = false;
  bool _disposed = false;

  SchedulePreferences get value => _value;
  bool get isLoading => _loading;
  bool get loadFailed => _loadFailed;
  bool get isSaving => _saving;

  Future<void> load() async {
    final repository = _repository;
    if (repository == null || _loading || _saving) return;
    _loading = true;
    notifyListeners();
    try {
      _value = await repository.load();
      _loadFailed = false;
    } catch (_) {
      _loadFailed = true;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> save(SchedulePreferences preferences) async {
    if (_loading || _loadFailed || _saving) return false;
    _saving = true;
    notifyListeners();
    try {
      await _repository?.save(preferences);
      _value = preferences;
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
