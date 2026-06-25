import 'dart:math';

import 'package:note_app/core/exceptions/app_exception.dart';
import 'package:note_app/layers/data/response/flash_card_deck_dto.dart';
import 'package:note_app/layers/data/response/flash_card_dto.dart';
import 'package:note_app/layers/data/response/quest_state_dto.dart';
import 'package:note_app/layers/data/response/shop_item_dto.dart';
import 'package:note_app/layers/data/response/task_dto.dart';
import 'package:note_app/layers/data/source/api/quest_api_client.dart';
import 'package:note_app/layers/data/source/local/quest_local_data_source.dart';
import 'package:note_app/layers/data/source/local/widget_data_source.dart';
import 'package:note_app/layers/domain/entities/flash_card_deck_entity.dart';
import 'package:note_app/layers/domain/entities/flash_card_entity.dart';
import 'package:note_app/layers/domain/entities/quest_state_entity.dart';
import 'package:note_app/layers/domain/entities/shop_item_entity.dart';
import 'package:note_app/layers/domain/entities/task_entity.dart';
import 'package:note_app/layers/domain/repository/quest_repository.dart';
import 'package:note_app/layers/domain/translator/quest_translator.dart';
import 'package:note_app/utils/id_utils.dart';

class QuestRepositoryImpl implements QuestRepository {
  QuestRepositoryImpl(
    this._apiClient,
    this._localDataSource,
    this._widgetDataSource,
    this._translator,
  );

  final QuestApiClient _apiClient;
  final QuestLocalDataSource _localDataSource;
  final WidgetDataSource _widgetDataSource;
  final QuestTranslator _translator;

  @override
  Future<QuestStateEntity> loadState() async {
    try {
      if (_localDataSource.hasPendingSync) {
        await _syncLocalState();
      }
      final response = await _apiClient.getQuestState();
      final dto = response.data ?? await _localDataSource.readState();
      final normalized = _normalizeState(dto);
      await _localDataSource.writeState(normalized);
      await _localDataSource.markSynced(DateTime.now().millisecondsSinceEpoch);
      return _translator.stateFromDto(normalized);
    } on AppException {
      final fallback = _normalizeState(await _localDataSource.readState());
      return _translator.stateFromDto(fallback);
    } catch (error) {
      throw NetworkException('Không thể tải dữ liệu.', cause: error);
    }
  }

  @override
  Future<void> saveTask(TaskEntity task) async {
    final state = await _localDataSource.readState();
    final tasks = [...state.tasks];
    final index = tasks.indexWhere((item) => item.id == task.id);
    final dto = _translator.taskToDto(task);
    if (index == -1) {
      tasks.add(dto);
    } else {
      tasks[index] = dto;
    }
    await _saveAndSyncWidget(state.copyWith(tasks: tasks));
  }

  @override
  Future<int> setTaskDone(String taskId, bool done) async {
    final state = await _localDataSource.readState();
    final tasks = [...state.tasks];
    final index = tasks.indexWhere((item) => item.id == taskId);
    if (index == -1 || tasks[index].done == done) return 0;

    final task = tasks[index];
    tasks[index] = TaskDto(
      id: task.id,
      title: task.title,
      dateKey: task.dateKey,
      reward: task.reward,
      done: done,
    );
    final delta = done ? task.reward : -task.reward;
    await _saveAndSyncWidget(
      state.copyWith(coins: max(0, state.coins + delta), tasks: tasks),
    );
    return delta;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final state = await _localDataSource.readState();
    TaskDto? task;
    for (final item in state.tasks) {
      if (item.id == taskId) {
        task = item;
        break;
      }
    }
    final coinRollback = task != null && task.done ? task.reward : 0;
    final tasks = state.tasks.where((item) => item.id != taskId).toList();
    await _saveAndSyncWidget(
      state.copyWith(coins: max(0, state.coins - coinRollback), tasks: tasks),
    );
  }

  @override
  Future<void> saveShopItem(ShopItemEntity item) async {
    final state = await _localDataSource.readState();
    final items = [...state.shopItems];
    final index = items.indexWhere((entry) => entry.id == item.id);
    final dto = _translator.shopToDto(item);
    if (index == -1) {
      items.add(dto);
    } else {
      items[index] = dto;
    }
    await _saveAndSyncWidget(state.copyWith(shopItems: items));
  }

  @override
  Future<bool> buyShopItem(String itemId) async {
    final state = await _localDataSource.readState();
    final items = [...state.shopItems];
    final index = items.indexWhere((item) => item.id == itemId);
    if (index == -1) return false;
    final item = items[index];
    if (state.coins < item.price) return false;
    items[index] = ShopItemDto(
      id: item.id,
      name: item.name,
      price: item.price,
      note: item.note,
      bought: true,
    );
    await _saveAndSyncWidget(
      state.copyWith(coins: state.coins - item.price, shopItems: items),
    );
    return true;
  }

  @override
  Future<void> deleteShopItem(String itemId) async {
    final state = await _localDataSource.readState();
    await _saveAndSyncWidget(
      state.copyWith(
        shopItems: state.shopItems.where((item) => item.id != itemId).toList(),
      ),
    );
  }

  @override
  Future<void> saveFlashCardDeck(FlashCardDeckEntity deck) async {
    final state = _normalizeState(await _localDataSource.readState());
    final decks = [...state.flashDecks];
    final index = decks.indexWhere((item) => item.id == deck.id);
    final dto = _translator.deckToDto(deck);
    if (index == -1) {
      decks.add(dto);
    } else {
      decks[index] = dto;
    }
    await _saveAndSyncWidget(state.copyWith(flashDecks: decks));
  }

  @override
  Future<void> deleteFlashCardDeck(String deckId) async {
    final state = _normalizeState(await _localDataSource.readState());
    if (state.flashDecks.length <= 1) return;
    await _saveAndSyncWidget(
      state.copyWith(
        flashDecks: state.flashDecks
            .where((deck) => deck.id != deckId)
            .toList(),
        flashCards: state.flashCards
            .where((card) => card.deckId != deckId)
            .toList(),
      ),
    );
  }

  @override
  Future<void> saveFlashCard(FlashCardEntity card) async {
    final state = _normalizeState(await _localDataSource.readState());
    final cards = [...state.flashCards];
    final index = cards.indexWhere((item) => item.id == card.id);
    final dto = _translator.cardToDto(card);
    if (index == -1) {
      cards.add(dto);
    } else {
      cards[index] = dto;
    }
    await _saveAndSyncWidget(state.copyWith(flashCards: cards));
  }

  @override
  Future<int> importFlashCards(String deckId, String rawText) async {
    final state = _normalizeState(await _localDataSource.readState());
    final cards = [...state.flashCards];
    final knownFronts = cards
        .where((card) => card.deckId == deckId)
        .map(
          (card) => _frontKey(
            card.frontText.isNotEmpty ? card.frontText : card.front,
          ),
        )
        .toSet();
    var count = 0;

    for (final line in rawText.split(RegExp(r'\r?\n'))) {
      final parsed = _parseImportLine(line.trim());
      if (parsed.frontText.isEmpty || parsed.backText.isEmpty) continue;
      final key = _frontKey(parsed.frontText);
      if (knownFronts.contains(key)) continue;
      cards.add(
        FlashCardDto(
          id: newId(),
          deckId: deckId,
          front: _sideText(parsed.frontText, parsed.frontPhonetic),
          back: _backText(parsed.backText, parsed.backPhonetic, parsed.meaning),
          frontText: parsed.frontText,
          frontPhonetic: parsed.frontPhonetic,
          backText: parsed.backText,
          backPhonetic: parsed.backPhonetic,
          meaning: parsed.meaning,
          mastered: false,
        ),
      );
      knownFronts.add(key);
      count++;
    }

    if (count > 0) {
      await _saveAndSyncWidget(state.copyWith(flashCards: cards));
    }
    return count;
  }

  ({
    String frontText,
    String frontPhonetic,
    String backText,
    String backPhonetic,
    String meaning,
  })
  _parseImportLine(String line) {
    if (line.isEmpty || !line.contains(':')) {
      return (
        frontText: '',
        frontPhonetic: '',
        backText: '',
        backPhonetic: '',
        meaning: '',
      );
    }
    final parts = line.split(':');
    return (
      frontText: parts.isNotEmpty ? parts[0].trim() : '',
      frontPhonetic: parts.length > 1 ? _stripBrackets(parts[1].trim()) : '',
      backText: parts.length > 2 ? parts[2].trim() : '',
      backPhonetic: parts.length > 3 ? _stripBrackets(parts[3].trim()) : '',
      meaning: parts.length > 4 ? parts.sublist(4).join(':').trim() : '',
    );
  }

  String _sideText(String text, String phonetic) {
    final parts = <String>[];
    if (text.isNotEmpty) parts.add(text);
    if (phonetic.isNotEmpty) parts.add('[${_stripBrackets(phonetic)}]');
    return parts.join('\n');
  }

  String _backText(String text, String phonetic, String meaning) {
    return [
      _sideText(text, phonetic),
      if (meaning.isNotEmpty) meaning,
    ].where((part) => part.trim().isNotEmpty).join('\n');
  }

  String _stripBrackets(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('[') &&
        trimmed.endsWith(']') &&
        trimmed.length > 1) {
      return trimmed.substring(1, trimmed.length - 1).trim();
    }
    return trimmed;
  }

  String _frontKey(String front) {
    return front.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  @override
  Future<void> toggleFlashCardMastered(String cardId) async {
    final state = await _localDataSource.readState();
    final cards = [...state.flashCards];
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index == -1) return;
    final card = cards[index];
    cards[index] = FlashCardDto(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      frontText: card.frontText,
      frontPhonetic: card.frontPhonetic,
      backText: card.backText,
      backPhonetic: card.backPhonetic,
      meaning: card.meaning,
      mastered: !card.mastered,
    );
    await _saveAndSyncWidget(state.copyWith(flashCards: cards));
  }

  @override
  Future<void> deleteFlashCard(String cardId) async {
    final state = await _localDataSource.readState();
    await _saveAndSyncWidget(
      state.copyWith(
        flashCards: state.flashCards
            .where((card) => card.id != cardId)
            .toList(),
      ),
    );
  }

  @override
  Future<int> claimFlashCardDeckReward(String deckId) async {
    final state = _normalizeState(await _localDataSource.readState());
    final deckIndex = state.flashDecks.indexWhere((deck) => deck.id == deckId);
    if (deckIndex == -1) return 0;

    final deck = state.flashDecks[deckIndex];
    final deckCards = state.flashCards
        .where((card) => card.deckId == deckId)
        .toList();
    final completed =
        deckCards.isNotEmpty && deckCards.every((card) => card.mastered);
    if (!completed || deck.rewardClaimed) return 0;

    final reward = max(20, deckCards.length * 5);
    final decks = [...state.flashDecks];
    decks[deckIndex] = FlashCardDeckDto(
      id: deck.id,
      name: deck.name,
      createdAt: deck.createdAt,
      rewardClaimed: true,
    );
    await _saveAndSyncWidget(
      state.copyWith(coins: state.coins + reward, flashDecks: decks),
    );
    return reward;
  }

  Future<void> _saveAndSyncWidget(QuestStateDto state) async {
    final normalized = _normalizeState(state);
    await _localDataSource.writeState(normalized);
    await _localDataSource.markPendingSync();
    await _trySyncState(normalized);
    await _widgetDataSource.update(
      coins: normalized.coins,
      tasks: normalized.tasks.map(_translator.taskFromDto).toList(),
    );
  }

  Future<void> _syncLocalState() async {
    final state = _normalizeState(await _localDataSource.readState());
    await _trySyncState(state);
  }

  Future<void> _trySyncState(QuestStateDto state) async {
    try {
      final response = await _apiClient.syncQuestState({
        'state': state.toJson(),
        'lastSyncedAt': _localDataSource.lastSyncedAt,
      });
      final syncedState = _normalizeState(response.data ?? state);
      await _localDataSource.writeState(syncedState);
      await _localDataSource.markSynced(DateTime.now().millisecondsSinceEpoch);
    } on AppException {
      await _localDataSource.markPendingSync();
    }
  }

  QuestStateDto _normalizeState(QuestStateDto state) {
    final shopItems = state.shopItems.isNotEmpty
        ? state.shopItems
        : [
            ShopItemDto(
              id: newId(),
              name: '30 phút chơi game',
              price: 80,
              note: 'Đổi sau khi hoàn thành việc quan trọng.',
              bought: false,
            ),
            ShopItemDto(
              id: newId(),
              name: 'Trà sữa',
              price: 120,
              note: 'Phần thưởng cuối tuần.',
              bought: false,
            ),
          ];

    final flashDecks = state.flashDecks.isNotEmpty
        ? state.flashDecks
        : [
            const FlashCardDeckDto(
              id: defaultFlashCardDeckId,
              name: 'Từ vựng chung',
              createdAt: 0,
              rewardClaimed: false,
            ),
          ];

    final knownDeckIds = flashDecks.map((deck) => deck.id).toSet();
    final flashCards = state.flashCards.map((card) {
      if (knownDeckIds.contains(card.deckId)) return card;
      return FlashCardDto(
        id: card.id,
        deckId: defaultFlashCardDeckId,
        front: card.front,
        back: card.back,
        frontText: card.frontText,
        frontPhonetic: card.frontPhonetic,
        backText: card.backText,
        backPhonetic: card.backPhonetic,
        meaning: card.meaning,
        mastered: card.mastered,
      );
    }).toList();

    return state.copyWith(
      shopItems: shopItems,
      flashDecks: flashDecks,
      flashCards: flashCards,
    );
  }
}
