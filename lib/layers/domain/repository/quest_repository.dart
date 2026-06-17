import 'package:note_app/layers/domain/entities/flash_card_deck_entity.dart';
import 'package:note_app/layers/domain/entities/flash_card_entity.dart';
import 'package:note_app/layers/domain/entities/quest_state_entity.dart';
import 'package:note_app/layers/domain/entities/shop_item_entity.dart';
import 'package:note_app/layers/domain/entities/task_entity.dart';

abstract interface class QuestRepository {
  Future<QuestStateEntity> loadState();
  Future<void> saveTask(TaskEntity task);
  Future<int> setTaskDone(String taskId, bool done);
  Future<void> deleteTask(String taskId);
  Future<void> saveShopItem(ShopItemEntity item);
  Future<bool> buyShopItem(String itemId);
  Future<void> deleteShopItem(String itemId);
  Future<void> saveFlashCardDeck(FlashCardDeckEntity deck);
  Future<void> deleteFlashCardDeck(String deckId);
  Future<void> saveFlashCard(FlashCardEntity card);
  Future<int> importFlashCards(String deckId, String rawText);
  Future<void> toggleFlashCardMastered(String cardId);
  Future<void> deleteFlashCard(String cardId);
  Future<int> claimFlashCardDeckReward(String deckId);
}
