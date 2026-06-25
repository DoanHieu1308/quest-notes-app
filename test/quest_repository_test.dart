import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/layers/data/response/flash_card_dto.dart';
import 'package:note_app/layers/data/repository/quest_repository_impl.dart';
import 'package:note_app/layers/data/source/api/local_quest_api_client.dart';
import 'package:note_app/layers/data/source/local/quest_local_data_source.dart';
import 'package:note_app/layers/data/source/local/widget_data_source.dart';
import 'package:note_app/layers/domain/entities/flash_card_entity.dart';
import 'package:note_app/layers/domain/entities/flash_card_deck_entity.dart';
import 'package:note_app/layers/domain/entities/shop_item_entity.dart';
import 'package:note_app/layers/domain/entities/task_entity.dart';
import 'package:note_app/layers/domain/translator/quest_translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy flashcard back is migrated to hidden meaning', () {
    final card = FlashCardDto.fromJson({
      'id': 'legacy',
      'deckId': 'english-a1',
      'front': 'hello',
      'back': 'xin chao\n[sin-chow]',
      'meaning': 'xin chao',
      'mastered': false,
    });

    expect(card.backText, '');
    expect(card.backPhonetic, '');
    expect(card.meaning, 'xin chao');
  });

  test(
    'repository persists local data and maps DTOs to domain entities',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final local = QuestLocalDataSource(preferences);
      final repository = QuestRepositoryImpl(
        LocalQuestApiClient(local),
        local,
        WidgetDataSource(),
        QuestTranslator(),
      );

      var state = await repository.loadState();
      expect(state.coins, 0);
      expect(state.shopItems, isNotEmpty);
      expect(state.flashDecks, isNotEmpty);

      await repository.saveTask(
        const TaskEntity(
          id: 'task-1',
          title: 'Read book',
          dateKey: '2026-06-13',
          reward: 30,
          done: false,
        ),
      );
      final reward = await repository.setTaskDone('task-1', true);
      expect(reward, 30);

      await repository.saveShopItem(
        const ShopItemEntity(
          id: 'tea',
          name: 'Tea',
          price: 20,
          note: '',
          bought: false,
        ),
      );
      final bought = await repository.buyShopItem('tea');
      expect(bought, isTrue);

      await repository.saveFlashCardDeck(
        const FlashCardDeckEntity(
          id: 'english-a1',
          name: 'English A1',
          createdAt: 1,
          rewardClaimed: false,
        ),
      );
      final imported = await repository.importFlashCards(
        'english-a1',
        'hello : he-lo : xin chao : sin-chow : chao ban\nwork : wurk : cong viec : kong-viec : viec lam',
      );
      expect(imported, 2);

      state = await repository.loadState();
      expect(state.coins, 10);
      expect(state.tasks.single.done, isTrue);
      expect(
        state.shopItems.where((item) => item.id == 'tea').single.bought,
        isTrue,
      );
      expect(state.flashCards.length, 2);
      expect(
        state.flashCards.every((card) => card.deckId == 'english-a1'),
        isTrue,
      );
      expect(state.flashCards[0].front, 'hello\n[he-lo]');
      expect(state.flashCards[0].back, 'xin chao\n[sin-chow]\nchao ban');
      expect(state.flashCards[1].back, 'cong viec\n[kong-viec]\nviec lam');
      expect(state.flashDecks.any((deck) => deck.id == 'english-a1'), isTrue);

      final duplicateImport = await repository.importFlashCards(
        'english-a1',
        'hello : duplicate : duplicate meaning : duplicate : duplicate',
      );
      expect(duplicateImport, 0);

      state = await repository.loadState();
      expect(state.flashCards.length, 2);

      final firstCard = state.flashCards[0];
      await repository.saveFlashCard(
        FlashCardEntity(
          id: firstCard.id,
          deckId: firstCard.deckId,
          front: 'hello updated\n[updated]',
          back: 'xin chao updated\n[sin-chow]\nupdated meaning',
          frontText: 'hello updated',
          frontPhonetic: 'updated',
          backText: 'xin chao updated',
          backPhonetic: 'sin-chow',
          meaning: 'updated meaning',
          mastered: firstCard.mastered,
        ),
      );

      state = await repository.loadState();
      expect(state.flashCards[0].front, 'hello updated\n[updated]');
      expect(
        state.flashCards[0].back,
        'xin chao updated\n[sin-chow]\nupdated meaning',
      );

      await repository.toggleFlashCardMastered(state.flashCards[0].id);
      await repository.toggleFlashCardMastered(state.flashCards[1].id);
      final deckReward = await repository.claimFlashCardDeckReward(
        'english-a1',
      );
      expect(deckReward, 20);

      state = await repository.loadState();
      expect(state.coins, 30);
      expect(
        state.flashDecks
            .where((deck) => deck.id == 'english-a1')
            .single
            .rewardClaimed,
        isTrue,
      );
    },
  );
}
