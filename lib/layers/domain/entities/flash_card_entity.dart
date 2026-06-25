class FlashCardEntity {
  const FlashCardEntity({
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

  FlashCardEntity copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    String? frontText,
    String? frontPhonetic,
    String? backText,
    String? backPhonetic,
    String? meaning,
    bool? mastered,
  }) {
    return FlashCardEntity(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      frontText: frontText ?? this.frontText,
      frontPhonetic: frontPhonetic ?? this.frontPhonetic,
      backText: backText ?? this.backText,
      backPhonetic: backPhonetic ?? this.backPhonetic,
      meaning: meaning ?? this.meaning,
      mastered: mastered ?? this.mastered,
    );
  }
}
