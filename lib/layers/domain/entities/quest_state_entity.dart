import 'package:note_app/layers/domain/entities/flash_card_deck_entity.dart';
import 'package:note_app/layers/domain/entities/flash_card_entity.dart';
import 'package:note_app/layers/domain/entities/shop_item_entity.dart';
import 'package:note_app/layers/domain/entities/task_entity.dart';

class QuestStateEntity {
  const QuestStateEntity({
    required this.coins,
    required this.tasks,
    required this.shopItems,
    required this.flashDecks,
    required this.flashCards,
  });

  final int coins;
  final List<TaskEntity> tasks;
  final List<ShopItemEntity> shopItems;
  final List<FlashCardDeckEntity> flashDecks;
  final List<FlashCardEntity> flashCards;

  factory QuestStateEntity.empty() {
    return const QuestStateEntity(
      coins: 0,
      tasks: [],
      shopItems: [],
      flashDecks: [],
      flashCards: [],
    );
  }
}
