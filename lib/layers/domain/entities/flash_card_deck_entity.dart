class FlashCardDeckEntity {
  const FlashCardDeckEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.rewardClaimed,
  });

  final String id;
  final String name;
  final int createdAt;
  final bool rewardClaimed;

  FlashCardDeckEntity copyWith({
    String? id,
    String? name,
    int? createdAt,
    bool? rewardClaimed,
  }) {
    return FlashCardDeckEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }
}
