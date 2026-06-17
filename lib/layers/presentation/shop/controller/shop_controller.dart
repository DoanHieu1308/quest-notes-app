import 'dart:math';

import 'package:mobx/mobx.dart';
import 'package:note_app/layers/domain/entities/shop_item_entity.dart';
import 'package:note_app/layers/domain/repository/quest_repository.dart';
import 'package:note_app/layers/presentation/controllers/mobx_controller.dart';
import 'package:note_app/utils/id_utils.dart';

class ShopController extends MobxController {
  ShopController(this._repository) {
    coins = Observable(0);
    items = ObservableList<ShopItemEntity>();
    lastMessage = Observable(null);
  }

  final QuestRepository _repository;

  late final Observable<int> coins;
  late final ObservableList<ShopItemEntity> items;
  late final Observable<String?> lastMessage;

  Future<void> load() async {
    setLoading(true);
    setError(null);
    try {
      final state = await _repository.loadState();
      runInAction(() {
        coins.value = state.coins;
        items
          ..clear()
          ..addAll(state.shopItems);
      });
    } catch (error) {
      setError('Không thể tải cửa hàng.');
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveItem({
    String? id,
    required String name,
    required int price,
    required String note,
    bool bought = false,
  }) async {
    if (name.trim().isEmpty) return;
    await _repository.saveShopItem(
      ShopItemEntity(
        id: id ?? newId(),
        name: name.trim(),
        price: max(1, price),
        note: note.trim(),
        bought: bought,
      ),
    );
    await load();
  }

  Future<void> buyItem(ShopItemEntity item) async {
    final bought = await _repository.buyShopItem(item.id);
    await load();
    runInAction(() {
      lastMessage.value = bought
          ? 'Đã đổi ${item.name} với ${item.price} xu.'
          : 'Chưa đủ xu để đổi vật phẩm này.';
    });
  }

  Future<void> deleteItem(ShopItemEntity item) async {
    await _repository.deleteShopItem(item.id);
    await load();
  }

  void clearMessage() {
    runInAction(() => lastMessage.value = null);
  }
}
