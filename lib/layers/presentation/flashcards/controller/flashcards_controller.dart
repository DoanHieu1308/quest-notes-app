import 'dart:math';
import 'dart:typed_data';

import 'package:mobx/mobx.dart';
import 'package:note_app/layers/domain/entities/flash_card_deck_entity.dart';
import 'package:note_app/layers/domain/entities/flash_card_entity.dart';
import 'package:note_app/layers/domain/repository/quest_repository.dart';
import 'package:note_app/layers/domain/translator/flash_card_import_translator.dart';
import 'package:note_app/layers/presentation/controllers/mobx_controller.dart';
import 'package:note_app/utils/id_utils.dart';

class FlashCardsController extends MobxController {
  FlashCardsController(this._repository, this._importTranslator) {
    decks = ObservableList<FlashCardDeckEntity>();
    cards = ObservableList<FlashCardEntity>();
    selectedDeckId = Observable(null);
    currentIndex = Observable(0);
    showingBack = Observable(false);
    lastImportCount = Observable(null);
    lastRewardAmount = Observable(null);
    coins = Observable(0);
    currentDeck = Computed(() {
      final deckId = selectedDeckId.value;
      if (deckId == null) return null;
      for (final deck in decks) {
        if (deck.id == deckId) return deck;
      }
      return null;
    });
    deckCards = Computed(() {
      final deckId = selectedDeckId.value;
      if (deckId == null) return <FlashCardEntity>[];
      return cards.where((card) => card.deckId == deckId).toList();
    });
    currentCard = Computed(() {
      final items = deckCards.value;
      if (items.isEmpty) return null;
      return items[min(currentIndex.value, items.length - 1)];
    });
    masteredCount = Computed(
      () => deckCards.value.where((card) => card.mastered).length,
    );
    currentDeckComplete = Computed(() {
      final items = deckCards.value;
      return items.isNotEmpty && items.every((card) => card.mastered);
    });
    currentDeckReward = Computed(() => rewardForCards(deckCards.value.length));
    canClaimCurrentDeck = Computed(() {
      final deck = currentDeck.value;
      return deck != null && currentDeckComplete.value && !deck.rewardClaimed;
    });
  }

  final QuestRepository _repository;
  final FlashCardImportTranslator _importTranslator;

  late final ObservableList<FlashCardDeckEntity> decks;
  late final ObservableList<FlashCardEntity> cards;
  late final Observable<String?> selectedDeckId;
  late final Observable<int> currentIndex;
  late final Observable<bool> showingBack;
  late final Observable<int?> lastImportCount;
  late final Observable<int?> lastRewardAmount;
  late final Observable<int> coins;
  late final Computed<FlashCardDeckEntity?> currentDeck;
  late final Computed<List<FlashCardEntity>> deckCards;
  late final Computed<FlashCardEntity?> currentCard;
  late final Computed<int> masteredCount;
  late final Computed<bool> currentDeckComplete;
  late final Computed<int> currentDeckReward;
  late final Computed<bool> canClaimCurrentDeck;

  Future<void> load() async {
    setLoading(true);
    setError(null);
    try {
      final state = await _repository.loadState();
      runInAction(() {
        coins.value = state.coins;
        decks
          ..clear()
          ..addAll(state.flashDecks);
        cards
          ..clear()
          ..addAll(state.flashCards);

        if (selectedDeckId.value != null &&
            !decks.any((deck) => deck.id == selectedDeckId.value)) {
          selectedDeckId.value = null;
          currentIndex.value = 0;
          showingBack.value = false;
        }
        if (currentIndex.value >= deckCards.value.length) {
          currentIndex.value = max(0, deckCards.value.length - 1);
        }
      });
    } catch (error) {
      setError('Không thể tải flashcard.');
    } finally {
      setLoading(false);
    }
  }

  void openDeck(String deckId) {
    runInAction(() {
      selectedDeckId.value = deckId;
      currentIndex.value = 0;
      showingBack.value = false;
    });
  }

  void closeDeck() {
    runInAction(() {
      selectedDeckId.value = null;
      currentIndex.value = 0;
      showingBack.value = false;
    });
  }

  Future<void> saveDeck({
    FlashCardDeckEntity? deck,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _repository.saveFlashCardDeck(
      FlashCardDeckEntity(
        id: deck?.id ?? newId(),
        name: trimmed,
        createdAt: deck?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        rewardClaimed: deck?.rewardClaimed ?? false,
      ),
    );
    await load();
  }

  Future<void> deleteDeck(FlashCardDeckEntity deck) async {
    if (decks.length <= 1) return;
    await _repository.deleteFlashCardDeck(deck.id);
    await load();
  }

  void flip() {
    runInAction(() => showingBack.value = !showingBack.value);
  }

  void move(int delta) {
    final items = deckCards.value;
    if (items.isEmpty) return;
    runInAction(() {
      currentIndex.value = (currentIndex.value + delta).clamp(
        0,
        items.length - 1,
      );
      showingBack.value = false;
    });
  }

  Future<void> importCards(String rawText) async {
    final deckId = selectedDeckId.value;
    if (deckId == null) return;
    final count = await _repository.importFlashCards(deckId, rawText);
    await load();
    runInAction(() {
      currentIndex.value = max(0, deckCards.value.length - count);
      showingBack.value = false;
      lastImportCount.value = count;
    });
  }

  Future<void> importCardsFromExcel(Uint8List bytes) async {
    final rawText = _importTranslator.excelBytesToRawText(bytes);
    if (rawText.trim().isEmpty) {
      runInAction(() => lastImportCount.value = 0);
      return;
    }
    await importCards(rawText);
  }

  Future<void> toggleMastered(FlashCardEntity card) async {
    await _repository.toggleFlashCardMastered(card.id);
    await load();
  }

  Future<void> saveCard({
    FlashCardEntity? card,
    required String frontText,
    required String frontPhonetic,
    required String backText,
    required String backPhonetic,
    required String meaning,
  }) async {
    final deckId = selectedDeckId.value;
    final trimmedFront = frontText.trim();
    final trimmedBack = backText.trim();
    final trimmedFrontPhonetic = _stripBrackets(frontPhonetic);
    final trimmedBackPhonetic = _stripBrackets(backPhonetic);
    final trimmedMeaning = meaning.trim();
    final hasFront = trimmedFront.isNotEmpty || trimmedFrontPhonetic.isNotEmpty;
    final hasBack =
        trimmedBack.isNotEmpty ||
        trimmedBackPhonetic.isNotEmpty ||
        trimmedMeaning.isNotEmpty;
    if (deckId == null || !hasFront || !hasBack) return;
    await _repository.saveFlashCard(
      FlashCardEntity(
        id: card?.id ?? newId(),
        deckId: card?.deckId ?? deckId,
        front: _sideText(trimmedFront, trimmedFrontPhonetic),
        back: _backText(trimmedBack, trimmedBackPhonetic, trimmedMeaning),
        frontText: trimmedFront,
        frontPhonetic: trimmedFrontPhonetic,
        backText: trimmedBack,
        backPhonetic: trimmedBackPhonetic,
        meaning: trimmedMeaning,
        mastered: card?.mastered ?? false,
      ),
    );
    await load();
  }

  Future<void> deleteCard(FlashCardEntity card) async {
    await _repository.deleteFlashCard(card.id);
    await load();
  }

  Future<void> claimCurrentDeckReward() async {
    final deck = currentDeck.value;
    if (deck == null) return;
    final reward = await _repository.claimFlashCardDeckReward(deck.id);
    await load();
    if (reward > 0) {
      runInAction(() => lastRewardAmount.value = reward);
    }
  }

  List<FlashCardEntity> cardsForDeck(String deckId) {
    return cards.where((card) => card.deckId == deckId).toList();
  }

  int masteredForDeck(String deckId) {
    return cardsForDeck(deckId).where((card) => card.mastered).length;
  }

  bool isDeckComplete(String deckId) {
    final items = cardsForDeck(deckId);
    return items.isNotEmpty && items.every((card) => card.mastered);
  }

  int rewardForCards(int count) => max(20, count * 5);

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

  void clearImportCount() {
    runInAction(() => lastImportCount.value = null);
  }

  void clearRewardAmount() {
    runInAction(() => lastRewardAmount.value = null);
  }
}
