import 'package:json_annotation/json_annotation.dart';
import 'package:note_app/core/typedef/result.dart';

@JsonSerializable()
class UpsertTaskRequest {
  const UpsertTaskRequest({
    required this.title,
    required this.dateKey,
    required this.reward,
  });

  final String title;
  final String dateKey;
  final int reward;

  JsonMap toJson() => {'title': title, 'dateKey': dateKey, 'reward': reward};
}
