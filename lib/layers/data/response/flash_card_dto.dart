import 'package:json_annotation/json_annotation.dart';
import 'package:note_app/core/typedef/result.dart';

@JsonSerializable()
class FlashCardDto {
  const FlashCardDto({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.mastered,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final bool mastered;

  factory FlashCardDto.fromJson(JsonMap json) {
    return FlashCardDto(
      id: json['id'] as String,
      deckId: json['deckId'] as String? ?? defaultFlashCardDeckId,
      front: json['front'] as String,
      back: json['back'] as String,
      mastered: json['mastered'] as bool? ?? false,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'deckId': deckId,
    'front': front,
    'back': back,
    'mastered': mastered,
  };
}

const defaultFlashCardDeckId = 'default-flashcard-deck';
