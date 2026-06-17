import 'dart:math';

import 'package:mobx/mobx.dart';
import 'package:note_app/layers/domain/entities/task_entity.dart';
import 'package:note_app/layers/domain/repository/quest_repository.dart';
import 'package:note_app/layers/presentation/controllers/mobx_controller.dart';
import 'package:note_app/utils/date_utils.dart';
import 'package:note_app/utils/id_utils.dart';

class TasksController extends MobxController {
  TasksController(this._repository) {
    selectedDate = Observable(DateTime.now());
    coins = Observable(0);
    tasks = ObservableList<TaskEntity>();
    rewardBurst = Observable(null);
    selectedTasks = Computed(_buildSelectedTasks);
    completedCount = Computed(
      () => selectedTasks.value.where((task) => task.done).length,
    );
    progress = Computed(() {
      final total = selectedTasks.value.length;
      if (total == 0) return 0.0;
      return completedCount.value / total;
    });
  }

  final QuestRepository _repository;

  late final Observable<DateTime> selectedDate;
  late final Observable<int> coins;
  late final ObservableList<TaskEntity> tasks;
  late final Observable<int?> rewardBurst;
  late final Computed<List<TaskEntity>> selectedTasks;
  late final Computed<int> completedCount;
  late final Computed<double> progress;

  Future<void> load() async {
    setLoading(true);
    setError(null);
    try {
      final state = await _repository.loadState();
      runInAction(() {
        coins.value = state.coins;
        tasks
          ..clear()
          ..addAll(state.tasks);
      });
    } catch (error) {
      setError('Không thể tải danh sách công việc.');
    } finally {
      setLoading(false);
    }
  }

  void shiftDate(int days) {
    runInAction(() {
      selectedDate.value = selectedDate.value.add(Duration(days: days));
    });
  }

  void setDate(DateTime date) {
    runInAction(() => selectedDate.value = date);
  }

  Future<void> addTask(String title, int reward) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final task = TaskEntity(
      id: newId(),
      title: trimmed,
      dateKey: dateKey(selectedDate.value),
      reward: max(1, reward),
      done: false,
    );
    await _repository.saveTask(task);
    await load();
  }

  Future<void> updateTask(TaskEntity task, String title, int reward) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await _repository.saveTask(
      task.copyWith(title: trimmed, reward: max(1, reward)),
    );
    await load();
  }

  Future<void> copyTaskToDate(TaskEntity task, DateTime targetDate) async {
    await _repository.saveTask(
      TaskEntity(
        id: newId(),
        title: task.title,
        dateKey: dateKey(targetDate),
        reward: max(1, task.reward),
        done: false,
      ),
    );
    await load();
  }

  Future<void> setTaskDone(TaskEntity task, bool done) async {
    final delta = await _repository.setTaskDone(task.id, done);
    await load();
    if (delta > 0) {
      runInAction(() => rewardBurst.value = delta);
    }
  }

  Future<void> deleteTask(TaskEntity task) async {
    await _repository.deleteTask(task.id);
    await load();
  }

  void clearRewardBurst() {
    runInAction(() => rewardBurst.value = null);
  }

  List<TaskEntity> _buildSelectedTasks() {
    final key = dateKey(selectedDate.value);
    final result = tasks.where((task) => task.dateKey == key).toList()
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        return a.title.compareTo(b.title);
      });
    return result;
  }
}
