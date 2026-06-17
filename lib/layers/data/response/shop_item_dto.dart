import 'package:json_annotation/json_annotation.dart';
import 'package:note_app/core/typedef/result.dart';

@JsonSerializable()
class ShopItemDto {
  const ShopItemDto({
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

  factory ShopItemDto.fromJson(JsonMap json) {
    return ShopItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
      note: json['note'] as String? ?? '',
      bought: json['bought'] as bool? ?? false,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'note': note,
    'bought': bought,
  };
}
