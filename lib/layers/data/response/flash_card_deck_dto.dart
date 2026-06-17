import 'package:json_annotation/json_annotation.dart';
import 'package:note_app/core/typedef/result.dart';

@JsonSerializable()
class FlashCardDeckDto {
  const FlashCardDeckDto({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.rewardClaimed,
  });

  final String id;
  final String name;
  final int createdAt;
  final bool rewardClaimed;

  factory FlashCardDeckDto.fromJson(JsonMap json) {
    return FlashCardDeckDto(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      rewardClaimed: json['rewardClaimed'] as bool? ?? false,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt,
    'rewardClaimed': rewardClaimed,
  };
}
