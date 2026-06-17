class ShopItemEntity {
  const ShopItemEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.note,
    required this.bought,
  });

  final String id;
  final String name;
  final int price;
  final String note;
  final bool bought;

  ShopItemEntity copyWith({
    String? id,
    String? name,
    int? price,
    String? note,
    bool? bought,
  }) {
    return ShopItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      note: note ?? this.note,
      bought: bought ?? this.bought,
    );
  }
}
