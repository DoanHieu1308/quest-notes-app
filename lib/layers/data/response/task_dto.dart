import 'package:json_annotation/json_annotation.dart';
import 'package:note_app/core/typedef/result.dart';

@JsonSerializable()
class TaskDto {
  const TaskDto({
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

  factory TaskDto.fromJson(JsonMap json) {
    return TaskDto(
      id: json['id'] as String,
      title: json['title'] as String,
      dateKey: json['dateKey'] as String,
      reward: (json['reward'] as num).toInt(),
      done: json['done'] as bool? ?? false,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'dateKey': dateKey,
    'reward': reward,
    'done': done,
  };
}
