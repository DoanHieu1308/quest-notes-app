import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:note_app/layers/domain/entities/shop_item_entity.dart';
import 'package:note_app/layers/presentation/shop/controller/shop_controller.dart';
import 'package:note_app/layers/presentation/widgets/coin_badge.dart';
import 'package:note_app/layers/presentation/widgets/empty_state.dart';
import 'package:note_app/layers/presentation/widgets/section_header.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.controller});

  final ShopController controller;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with WidgetsBindingObserver {
  ShopController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final message = controller.lastMessage.value;
        if (message != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
            controller.clearMessage();
          });
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            SectionHeader(
              icon: Icons.storefront,
              title: 'Cửa hàng phần thưởng',
              action: CoinBadge(coins: controller.coins.value),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _editItem(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm vật phẩm'),
            ),
            const SizedBox(height: 12),
            if (controller.isLoading.value)
              const Center(child: CircularProgressIndicator())
            else if (controller.items.isEmpty)
              const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Shop đang trống',
                body: 'Thêm vật phẩm, đặt giá xu, rồi dùng xu đã kiếm để đổi.',
              )
            else
              ...controller.items.map(
                (item) => _ShopTile(
                  item: item,
                  onBuy: () => controller.buyItem(item),
                  onEdit: () => _editItem(item),
                  onDelete: () => controller.deleteItem(item),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _editItem([ShopItemEntity? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final price = TextEditingController(text: '${item?.price ?? 50}');
    final note = TextEditingController(text: item?.note ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Thêm vật phẩm' : 'Sửa vật phẩm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tên vật phẩm'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá xu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
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
      await controller.saveItem(
        id: item?.id,
        name: name.text,
        price: int.tryParse(price.text) ?? 50,
        note: note.text,
        bought: item?.bought ?? false,
      );
    }
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.item,
    required this.onBuy,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopItemEntity item;
  final VoidCallback onBuy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: item.bought
                    ? const Color(0xffd7ead7)
                    : const Color(0xffffe4a8),
                child: Icon(item.bought ? Icons.check : Icons.redeem),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.note.isEmpty
                          ? '${item.price} xu'
                          : '${item.price} xu - ${item.note}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 42,
                child: FilledButton(
                  onPressed: item.bought ? null : onBuy,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: const Color(0xff1d7a66),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xffd7ead7),
                    disabledForegroundColor: const Color(0xff326b55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Icon(item.bought ? Icons.check : Icons.shopping_bag),
                ),
              ),
              SizedBox(
                width: 40,
                child: PopupMenuButton<_ShopMenuAction>(
                  padding: EdgeInsets.zero,
                  tooltip: 'Thao tác',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    switch (action) {
                      case _ShopMenuAction.edit:
                        onEdit();
                      case _ShopMenuAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _ShopMenuAction.edit,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Sửa'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ShopMenuAction.delete,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ShopMenuAction { edit, delete }
