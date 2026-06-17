import 'package:note_app/core/response/api_response.dart';
import 'package:note_app/layers/data/response/quest_state_dto.dart';
import 'package:note_app/layers/data/source/api/quest_api_client.dart';
import 'package:note_app/layers/data/source/local/quest_local_data_source.dart';

class LocalQuestApiClient implements QuestApiClient {
  const LocalQuestApiClient(this._localDataSource);

  final QuestLocalDataSource _localDataSource;

  @override
  Future<ApiResponse<QuestStateDto>> getQuestState() async {
    final state = await _localDataSource.readState();
    return ApiResponse.success(state);
  }

  @override
  Future<ApiResponse<QuestStateDto>> syncQuestState(
    Map<String, dynamic> body,
  ) async {
    final state = QuestStateDto.fromJson(
      Map<String, dynamic>.from(body['state'] as Map),
    );
    await _localDataSource.writeState(state);
    return ApiResponse.success(state);
  }
}
