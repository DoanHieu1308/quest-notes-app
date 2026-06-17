import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:note_app/layers/domain/entities/flash_card_deck_entity.dart';
import 'package:note_app/layers/domain/entities/flash_card_entity.dart';
import 'package:note_app/layers/presentation/flashcards/controller/flashcards_controller.dart';
import 'package:note_app/layers/presentation/widgets/coin_badge.dart';
import 'package:note_app/layers/presentation/widgets/empty_state.dart';
import 'package:note_app/layers/presentation/widgets/section_header.dart';

class FlashCardsScreen extends StatefulWidget {
  const FlashCardsScreen({super.key, required this.controller});

  final FlashCardsController controller;

  @override
  State<FlashCardsScreen> createState() => _FlashCardsScreenState();
}

class _FlashCardsScreenState extends State<FlashCardsScreen> {
  FlashCardsController get controller => widget.controller;
  int _cardSlideDirection = 1;

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        _showDeferredMessages();
        final deck = controller.currentDeck.value;
        if (deck == null) return _buildDeckList();
        return _buildDeckStudy(deck);
      },
    );
  }

  Widget _buildDeckList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionHeader(
          icon: Icons.style,
          title: 'Bộ flashcard',
          action: CoinBadge(coins: controller.coins.value),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _editDeck(),
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('Thêm bộ flashcard'),
        ),
        const SizedBox(height: 16),
        if (controller.isLoading.value)
          const Center(child: CircularProgressIndicator())
        else if (controller.decks.isEmpty)
          const EmptyState(
            icon: Icons.folder_outlined,
            title: 'Chưa có bộ flashcard',
            body: 'Tạo một bộ học để bắt đầu lưu từ vựng.',
          )
        else
          ...controller.decks.map((deck) {
            final total = controller.cardsForDeck(deck.id).length;
            final mastered = controller.masteredForDeck(deck.id);
            final complete = controller.isDeckComplete(deck.id);
            return _DeckListTile(
              deck: deck,
              total: total,
              mastered: mastered,
              complete: complete,
              reward: controller.rewardForCards(total),
              canDelete: controller.decks.length > 1,
              onOpen: () => controller.openDeck(deck.id),
              onEdit: () => _editDeck(deck),
              onDelete: () => _confirmDeleteDeck(deck),
            );
          }),
      ],
    );
  }

  Widget _buildDeckStudy(FlashCardDeckEntity deck) {
    final card = controller.currentCard.value;
    final deckCards = controller.deckCards.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: controller.closeDeck,
              tooltip: 'Quay lại danh sách bộ',
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                deck.name,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            CoinBadge(coins: controller.coins.value),
          ],
        ),
        const SizedBox(height: 12),
        _ImportPanel(
          deckName: deck.name,
          onImport: _importCards,
          onImportExcel: _importCardsFromExcel,
        ),
        const SizedBox(height: 16),
        if (card == null)
          EmptyState(
            icon: Icons.style_outlined,
            title: 'Bộ "${deck.name}" đang trống',
            body: 'Nhấn nút nhập từ vựng để thêm theo mẫu: hello : xin chào',
          )
        else ...[
          _RewardPanel(
            total: deckCards.length,
            mastered: controller.masteredCount.value,
            reward: controller.currentDeckReward.value,
            complete: controller.currentDeckComplete.value,
            claimed: deck.rewardClaimed,
            canClaim: controller.canClaimCurrentDeck.value,
            onClaim: controller.claimCurrentDeckReward,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: controller.flip,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -250 &&
                  controller.currentIndex.value < deckCards.length - 1) {
                _moveCard(1);
              } else if (velocity > 250 && controller.currentIndex.value > 0) {
                _moveCard(-1);
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 340),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final isIncoming = child.key == ValueKey(card.id);
                final offset = Tween<Offset>(
                  begin: Offset(
                    isIncoming
                        ? _cardSlideDirection.toDouble()
                        : -_cardSlideDirection * 0.35,
                    0,
                  ),
                  end: Offset.zero,
                ).animate(animation);
                final scale = Tween<double>(
                  begin: isIncoming ? 0.86 : 0.92,
                  end: 1,
                ).animate(animation);
                return SlideTransition(
                  position: offset,
                  child: ScaleTransition(
                    scale: scale,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
              child: AnimatedSwitcher(
                key: ValueKey(card.id),
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) {
                  final rotate = Tween(begin: pi, end: 0.0).animate(animation);
                  return AnimatedBuilder(
                    animation: rotate,
                    child: child,
                    builder: (context, child) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(rotate.value),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey('${card.id}-${controller.showingBack.value}'),
                  height: 260,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: controller.showingBack.value
                        ? const Color(0xff12352f)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xffded8cc)),
                  ),
                  child: Text(
                    controller.showingBack.value ? card.back : card.front,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: controller.showingBack.value
                          ? Colors.white
                          : const Color(0xff20211f),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: controller.currentIndex.value == 0
                    ? null
                    : () => _moveCard(-1),
                tooltip: 'Thẻ trước',
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${controller.currentIndex.value + 1}/${deckCards.length}',
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: controller.currentIndex.value == deckCards.length - 1
                    ? null
                    : () => _moveCard(1),
                tooltip: 'Thẻ sau',
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilterChip(
                selected: card.mastered,
                label: const Text('Đã thuộc'),
                avatar: const Icon(Icons.school_outlined),
                onSelected: (_) => controller.toggleMastered(card),
              ),
              OutlinedButton.icon(
                onPressed: () => controller.deleteCard(card),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa thẻ'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FlashCardList(
            cards: deckCards,
            currentIndex: controller.currentIndex.value,
            onOpen: _openCardAt,
            onEdit: _editCard,
            onDelete: controller.deleteCard,
          ),
        ],
      ],
    );
  }

  void _showDeferredMessages() {
    final importCount = controller.lastImportCount.value;
    if (importCount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã nhập $importCount flashcard.')),
        );
        controller.clearImportCount();
      });
    }
    final reward = controller.lastRewardAmount.value;
    if (reward != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã nhận $reward xu cho bộ học này.')),
        );
        controller.clearRewardAmount();
      });
    }
  }

  Future<void> _editDeck([FlashCardDeckEntity? deck]) async {
    final name = TextEditingController(text: deck?.name ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deck == null ? 'Tạo bộ flashcard' : 'Sửa tên bộ'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tên bộ',
            prefixIcon: Icon(Icons.folder_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await controller.saveDeck(deck: deck, name: name.text);
    }
  }

  Future<void> _confirmDeleteDeck(FlashCardDeckEntity deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bộ flashcard'),
        content: Text('Xóa bộ "${deck.name}" và toàn bộ thẻ trong bộ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteDeck(deck);
    }
  }

  Future<void> _editCard(FlashCardEntity card) async {
    final front = TextEditingController(text: card.front);
    final back = TextEditingController(text: card.back);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: front,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Từ vựng',
                prefixIcon: Icon(Icons.style_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: back,
              decoration: const InputDecoration(
                labelText: 'Nghĩa',
                prefixIcon: Icon(Icons.translate_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await controller.saveCard(card: card, front: front.text, back: back.text);
    }
  }

  Future<void> _importCards(String rawText) async {
    await controller.importCards(rawText);
  }

  Future<void> _importCardsFromExcel(Uint8List bytes) async {
    await controller.importCardsFromExcel(bytes);
  }

  void _moveCard(int direction) {
    setState(() => _cardSlideDirection = direction);
    controller.move(direction);
  }

  void _openCardAt(int index) {
    final delta = index - controller.currentIndex.value;
    if (delta == 0) return;
    setState(() => _cardSlideDirection = delta.sign);
    controller.move(delta);
  }
}

class _DeckListTile extends StatelessWidget {
  const _DeckListTile({
    required this.deck,
    required this.total,
    required this.mastered,
    required this.complete,
    required this.reward,
    required this.canDelete,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final FlashCardDeckEntity deck;
  final int total;
  final int mastered;
  final bool complete;
  final int reward;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : mastered / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: complete
                      ? const Color(0xffd7ead7)
                      : const Color(0xffffe4a8),
                  child: Icon(complete ? Icons.check : Icons.folder_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text('$mastered/$total thẻ - thưởng $reward xu'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Sửa tên bộ',
                  icon: const Icon(Icons.edit_outlined),
                ),
                PopupMenuButton<_DeckMenuAction>(
                  tooltip: 'Thao tác',
                  onSelected: (action) {
                    switch (action) {
                      case _DeckMenuAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _DeckMenuAction.delete,
                      enabled: canDelete,
                      child: const ListTile(
                        dense: true,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Xóa bộ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportPanel extends StatefulWidget {
  const _ImportPanel({
    required this.deckName,
    required this.onImport,
    required this.onImportExcel,
  });

  final String deckName;
  final ValueChanged<String> onImport;
  final Future<void> Function(Uint8List bytes) onImportExcel;

  @override
  State<_ImportPanel> createState() => _ImportPanelState();
}

class _ImportPanelState extends State<_ImportPanel> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => _showImportDialog(context),
            icon: const Icon(Icons.playlist_add),
            label: const Text('Nhập từ vựng'),
          ),
          OutlinedButton.icon(
            onPressed: () => _pickExcelFile(context),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Nhập Excel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExcelFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: true,
      );
      final bytes = result?.files.single.bytes;
      if (bytes == null) return;
      await widget.onImportExcel(bytes);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đọc file Excel.')),
      );
    }
  }

  Future<void> _showImportDialog(BuildContext context) async {
    controller.clear();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nhập vào bộ "${widget.deckName}"'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 8,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'hello : xin chào\napple : quả táo',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.add),
            label: const Text('Thêm vào bộ'),
          ),
        ],
      ),
    );
    if (saved == true && controller.text.trim().isNotEmpty) {
      widget.onImport(controller.text);
    }
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel({
    required this.total,
    required this.mastered,
    required this.reward,
    required this.complete,
    required this.claimed,
    required this.canClaim,
    required this.onClaim,
  });

  final int total;
  final int mastered;
  final int reward;
  final bool complete;
  final bool claimed;
  final bool canClaim;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến độ $mastered/$total thẻ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : mastered / total,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    claimed
                        ? 'Đã nhận thưởng bộ này'
                        : 'Hoàn thành bộ để nhận $reward xu',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: canClaim ? onClaim : null,
              icon: Icon(claimed ? Icons.check : Icons.monetization_on),
              label: Text(claimed ? 'Đã nhận' : 'Nhận xu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashCardList extends StatelessWidget {
  const _FlashCardList({
    required this.cards,
    required this.currentIndex,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<FlashCardEntity> cards;
  final int currentIndex;
  final ValueChanged<int> onOpen;
  final ValueChanged<FlashCardEntity> onEdit;
  final ValueChanged<FlashCardEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách từ vựng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...cards.asMap().entries.map((entry) {
          final index = entry.key;
          final card = entry.value;
          final active = index == currentIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onOpen(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active
                        ? const Color(0xff1d7a66)
                        : const Color(0xffded8cc),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 26),
                      height: 24,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xffffcf4a),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        card.mastered ? 'OK' : '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xff3d2a00),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        card.front,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff20211f),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      card.mastered ? 'Đã thuộc' : 'Đang học',
                      style: const TextStyle(
                        color: Color(0xff68645c),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    PopupMenuButton<_CardMenuAction>(
                      tooltip: 'Thao tác thẻ',
                      onSelected: (action) {
                        switch (action) {
                          case _CardMenuAction.edit:
                            onEdit(card);
                          case _CardMenuAction.delete:
                            onDelete(card);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _CardMenuAction.edit,
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Sửa'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _CardMenuAction.delete,
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.delete_outline),
                            title: Text('Xóa'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

enum _DeckMenuAction { delete }

enum _CardMenuAction { edit, delete }
