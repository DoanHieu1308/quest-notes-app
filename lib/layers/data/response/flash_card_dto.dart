import 'package:json_annotation/json_annotation.dart';
import 'package:note_app/core/typedef/result.dart';

@JsonSerializable()
class FlashCardDto {
  const FlashCardDto({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.frontText,
    required this.frontPhonetic,
    required this.backText,
    required this.backPhonetic,
    required this.meaning,
    required this.mastered,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final String frontText;
  final String frontPhonetic;
  final String backText;
  final String backPhonetic;
  final String meaning;
  final bool mastered;

  factory FlashCardDto.fromJson(JsonMap json) {
    final front = json['front'] as String? ?? '';
    final back = json['back'] as String? ?? '';
    final frontParts = _sideParts(front);
    final backParts = _backParts(back);
    return FlashCardDto(
      id: json['id'] as String,
      deckId: json['deckId'] as String? ?? defaultFlashCardDeckId,
      front: front,
      back: back,
      frontText: json['frontText'] as String? ?? frontParts.text,
      frontPhonetic: json['frontPhonetic'] as String? ?? frontParts.phonetic,
      backText: json['backText'] as String? ?? backParts.text,
      backPhonetic: json['backPhonetic'] as String? ?? backParts.phonetic,
      meaning: json['meaning'] as String? ?? backParts.meaning,
      mastered: json['mastered'] as bool? ?? false,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'deckId': deckId,
    'front': front,
    'back': back,
    'frontText': frontText,
    'frontPhonetic': frontPhonetic,
    'backText': backText,
    'backPhonetic': backPhonetic,
    'meaning': meaning,
    'mastered': mastered,
  };
}

const defaultFlashCardDeckId = 'default-flashcard-deck';

({String text, String phonetic}) _sideParts(String value) {
  final lines = value
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return (text: '', phonetic: '');
  final last = lines.last;
  final hasPhonetic =
      last.startsWith('[') && last.endsWith(']') && last.length > 1;
  return (
    text: hasPhonetic ? lines.take(lines.length - 1).join('\n') : lines.first,
    phonetic: hasPhonetic ? last.substring(1, last.length - 1).trim() : '',
  );
}

({String text, String phonetic, String meaning}) _backParts(String value) {
  final lines = value
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return (text: '', phonetic: '', meaning: '');
  final side = _sideParts(lines.take(2).join('\n'));
  final meaning = lines.length > 2 ? lines.skip(2).join('\n') : '';
  return (text: side.text, phonetic: side.phonetic, meaning: meaning);
}
