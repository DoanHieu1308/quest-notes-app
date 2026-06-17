import 'package:json_annotation/json_annotation.dart';
import 'package:note_app/core/typedef/result.dart';
import 'package:note_app/layers/data/response/flash_card_deck_dto.dart';
import 'package:note_app/layers/data/response/flash_card_dto.dart';
import 'package:note_app/layers/data/response/shop_item_dto.dart';
import 'package:note_app/layers/data/response/task_dto.dart';

@JsonSerializable()
class QuestStateDto {
  const QuestStateDto({
    required this.coins,
    required this.tasks,
    required this.shopItems,
    required this.flashDecks,
    required this.flashCards,
  });

  final int coins;
  final List<TaskDto> tasks;
  final List<ShopItemDto> shopItems;
  final List<FlashCardDeckDto> flashDecks;
  final List<FlashCardDto> flashCards;

  factory QuestStateDto.empty() {
    return const QuestStateDto(
      coins: 0,
      tasks: [],
      shopItems: [],
      flashDecks: [],
      flashCards: [],
    );
  }

  factory QuestStateDto.fromJson(JsonMap json) {
    return QuestStateDto(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      tasks: ((json['tasks'] as List<dynamic>?) ?? [])
          .map(
            (item) => TaskDto.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      shopItems: ((json['shopItems'] as List<dynamic>?) ?? [])
          .map(
            (item) =>
                ShopItemDto.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      flashDecks: ((json['flashDecks'] as List<dynamic>?) ?? [])
          .map(
            (item) => FlashCardDeckDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      flashCards: ((json['flashCards'] as List<dynamic>?) ?? [])
          .map(
            (item) =>
                FlashCardDto.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  JsonMap toJson() => {
    'coins': coins,
    'tasks': tasks.map((item) => item.toJson()).toList(),
    'shopItems': shopItems.map((item) => item.toJson()).toList(),
    'flashDecks': flashDecks.map((item) => item.toJson()).toList(),
    'flashCards': flashCards.map((item) => item.toJson()).toList(),
  };

  QuestStateDto copyWith({
    int? coins,
    List<TaskDto>? tasks,
    List<ShopItemDto>? shopItems,
    List<FlashCardDeckDto>? flashDecks,
    List<FlashCardDto>? flashCards,
  }) {
    return QuestStateDto(
      coins: coins ?? this.coins,
      tasks: tasks ?? this.tasks,
      shopItems: shopItems ?? this.shopItems,
      flashDecks: flashDecks ?? this.flashDecks,
      flashCards: flashCards ?? this.flashCards,
    );
  }
}
