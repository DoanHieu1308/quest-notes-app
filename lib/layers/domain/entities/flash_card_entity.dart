class FlashCardEntity {
  const FlashCardEntity({
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

  FlashCardEntity copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    bool? mastered,
  }) {
    return FlashCardEntity(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      mastered: mastered ?? this.mastered,
    );
  }
}
