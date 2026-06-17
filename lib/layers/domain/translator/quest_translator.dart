import 'package:note_app/layers/data/response/flash_card_deck_dto.dart';
import 'package:note_app/layers/data/response/flash_card_dto.dart';
import 'package:note_app/layers/data/response/quest_state_dto.dart';
import 'package:note_app/layers/data/response/shop_item_dto.dart';
import 'package:note_app/layers/data/response/task_dto.dart';
import 'package:note_app/layers/domain/entities/flash_card_deck_entity.dart';
import 'package:note_app/layers/domain/entities/flash_card_entity.dart';
import 'package:note_app/layers/domain/entities/quest_state_entity.dart';
import 'package:note_app/layers/domain/entities/shop_item_entity.dart';
import 'package:note_app/layers/domain/entities/task_entity.dart';

class QuestTranslator {
  TaskEntity taskFromDto(TaskDto dto) {
    return TaskEntity(
      id: dto.id,
      title: dto.title,
      dateKey: dto.dateKey,
      reward: dto.reward,
      done: dto.done,
    );
  }

  TaskDto taskToDto(TaskEntity entity) {
    return TaskDto(
      id: entity.id,
      title: entity.title,
      dateKey: entity.dateKey,
      reward: entity.reward,
      done: entity.done,
    );
  }

  ShopItemEntity shopFromDto(ShopItemDto dto) {
    return ShopItemEntity(
      id: dto.id,
      name: dto.name,
      price: dto.price,
      note: dto.note,
      bought: dto.bought,
    );
  }

  ShopItemDto shopToDto(ShopItemEntity entity) {
    return ShopItemDto(
      id: entity.id,
      name: entity.name,
      price: entity.price,
      note: entity.note,
      bought: entity.bought,
    );
  }

  FlashCardEntity cardFromDto(FlashCardDto dto) {
    return FlashCardEntity(
      id: dto.id,
      deckId: dto.deckId,
      front: dto.front,
      back: dto.back,
      mastered: dto.mastered,
    );
  }

  FlashCardDto cardToDto(FlashCardEntity entity) {
    return FlashCardDto(
      id: entity.id,
      deckId: entity.deckId,
      front: entity.front,
      back: entity.back,
      mastered: entity.mastered,
    );
  }

  FlashCardDeckEntity deckFromDto(FlashCardDeckDto dto) {
    return FlashCardDeckEntity(
      id: dto.id,
      name: dto.name,
      createdAt: dto.createdAt,
      rewardClaimed: dto.rewardClaimed,
    );
  }

  FlashCardDeckDto deckToDto(FlashCardDeckEntity entity) {
    return FlashCardDeckDto(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
      rewardClaimed: entity.rewardClaimed,
    );
  }

  QuestStateEntity stateFromDto(QuestStateDto dto) {
    return QuestStateEntity(
      coins: dto.coins,
      tasks: dto.tasks.map(taskFromDto).toList(),
      shopItems: dto.shopItems.map(shopFromDto).toList(),
      flashDecks: dto.flashDecks.map(deckFromDto).toList(),
      flashCards: dto.flashCards.map(cardFromDto).toList(),
    );
  }

  QuestStateDto stateToDto(QuestStateEntity entity) {
    return QuestStateDto(
      coins: entity.coins,
      tasks: entity.tasks.map(taskToDto).toList(),
      shopItems: entity.shopItems.map(shopToDto).toList(),
      flashDecks: entity.flashDecks.map(deckToDto).toList(),
      flashCards: entity.flashCards.map(cardToDto).toList(),
    );
  }
}
