import 'dart:convert';

import 'package:note_app/core/exceptions/app_exception.dart';
import 'package:note_app/layers/data/response/quest_state_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestLocalDataSource {
  const QuestLocalDataSource(this._preferences);

  static const _stateKey = 'quest_state_v2';
  static const _pendingSyncKey = 'quest_state_pending_sync_v1';
  static const _lastSyncedAtKey = 'quest_state_last_synced_at_v1';

  final SharedPreferences _preferences;

  Future<QuestStateDto> readState() async {
    try {
      await _preferences.reload();
      final raw = _preferences.getString(_stateKey);
      if (raw == null || raw.isEmpty) return QuestStateDto.empty();
      return QuestStateDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      throw CacheException('Không thể đọc dữ liệu cục bộ.', cause: error);
    }
  }

  Future<void> writeState(QuestStateDto state) async {
    try {
      await _preferences.setString(_stateKey, jsonEncode(state.toJson()));
    } catch (error) {
      throw CacheException('Không thể lưu dữ liệu cục bộ.', cause: error);
    }
  }

  bool get hasPendingSync => _preferences.getBool(_pendingSyncKey) ?? false;

  int get lastSyncedAt => _preferences.getInt(_lastSyncedAtKey) ?? 0;

  Future<void> markPendingSync() async {
    await _preferences.setBool(_pendingSyncKey, true);
  }

  Future<void> markSynced(int syncedAt) async {
    await _preferences.setBool(_pendingSyncKey, false);
    await _preferences.setInt(_lastSyncedAtKey, syncedAt);
  }
}
