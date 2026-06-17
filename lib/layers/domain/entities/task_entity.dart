class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.dateKey,
    required this.reward,
    required this.done,
  });

  final String id;
  final String title;
  final String dateKey;
  final int reward;
  final bool done;

  TaskEntity copyWith({
    String? id,
    String? title,
    String? dateKey,
    int? reward,
    bool? done,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      dateKey: dateKey ?? this.dateKey,
      reward: reward ?? this.reward,
      done: done ?? this.done,
    );
  }
}
