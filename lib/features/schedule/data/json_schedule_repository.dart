import 'dart:convert';
import 'dart:io';

import '../domain/schedule_item.dart';
import '../domain/schedule_repository.dart';

/// One application-owned JSON document. Platform paths are injected at startup.
final class JsonScheduleRepository implements ScheduleRepository {
  JsonScheduleRepository(this.directoryProvider);

  final Future<Directory> Function() directoryProvider;
  Future<void> _pendingWrite = Future<void>.value();

  Future<File> _file() async {
    final directory = await directoryProvider();
    return File('${directory.path}/schedules.json');
  }

  @override
  Future<List<ScheduleItem>> load() async {
    await _pendingWrite;
    final file = await _file();
    if (!await file.exists()) return [];

    final Object? decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?> ||
        (decoded['schemaVersion'] != 1 && decoded['schemaVersion'] != 2)) {
      throw const FormatException('Unsupported schedule document');
    }
    final records = decoded['items'];
    if (records is! List<Object?>) {
      throw const FormatException('Invalid schedule records');
    }
    final items = records.map((record) {
      if (record is! Map<String, Object?>) {
        throw const FormatException('Invalid schedule record');
      }
      return ScheduleItem.fromJson(record);
    }).toList();
    if (items.map((item) => item.id).toSet().length != items.length) {
      throw const FormatException('Duplicate schedule IDs');
    }
    return items;
  }

  @override
  Future<void> saveAll(List<ScheduleItem> items) {
    // Encode before queueing so callers cannot mutate the pending snapshot.
    final content = jsonEncode({
      'schemaVersion': 2,
      'items': items.map((item) => item.toJson()).toList(),
    });
    final operation = _pendingWrite.then((_) async {
      final file = await _file();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(content, flush: true);
      // Same-directory rename replaces the file atomically on Android/iOS.
      await temporary.rename(file.path);
    });
    // A failed write must not poison subsequent retry attempts.
    _pendingWrite = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
