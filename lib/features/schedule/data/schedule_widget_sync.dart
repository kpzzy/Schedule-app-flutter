import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/calendar_date.dart';
import '../domain/schedule_item.dart';
import 'schedule_widget_snapshot.dart';

final class ScheduleWidgetSync {
  static const _channel = MethodChannel('schedule_app/home_widget');
  Future<void> _pending = Future<void>.value();
  String? _lastPublished;

  Future<void> publish(List<ScheduleItem> items) {
    final payload = jsonEncode(
      buildScheduleWidgetSnapshot(
        CalendarDate.fromLocal(DateTime.now()),
        items,
      ),
    );
    _pending = _pending.then((_) async {
      if (payload == _lastPublished) return;
      try {
        await _channel.invokeMethod<void>('publish', payload);
        _lastPublished = payload;
      } on PlatformException {
        // The widget is a derived view. Retry independently on the next sync.
      } on MissingPluginException {
        // The widget integration is unavailable on this platform.
      }
    });
    return _pending;
  }
}
