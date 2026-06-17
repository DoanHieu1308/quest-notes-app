import 'package:flutter/services.dart';
import 'package:note_app/layers/domain/entities/task_entity.dart';
import 'package:note_app/utils/date_utils.dart';

class WidgetDataSource {
  static const _channel = MethodChannel('quest_notes/widget');

  Future<void> update({
    required int coins,
    required List<TaskEntity> tasks,
  }) async {
    final today = dateKey(DateTime.now());
    final todayTasks = tasks.where((task) => task.dateKey == today).toList();
    final done = todayTasks.where((task) => task.done).length;
    final next = todayTasks
        .where((task) => !task.done)
        .map((task) => task.title)
        .take(3)
        .join('\n');

    try {
      await _channel.invokeMethod('updateWidget', {
        'coins': coins,
        'done': done,
        'total': todayTasks.length,
        'next': next.isEmpty ? 'Không có task nào hôm nay' : next,
      });
    } on PlatformException {
      // Native widget channel exists only on supported Android builds.
    } on MissingPluginException {
      // Non-Android builds keep app data working without widget updates.
    }
  }
}
