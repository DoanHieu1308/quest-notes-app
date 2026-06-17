import 'package:note_app/core/response/api_response.dart';
import 'package:note_app/layers/data/response/quest_state_dto.dart';
import 'package:retrofit/retrofit.dart';

@RestApi()
abstract interface class QuestApiClient {
  @GET('/quest/state')
  Future<ApiResponse<QuestStateDto>> getQuestState();

  @POST('/quest/sync')
  Future<ApiResponse<QuestStateDto>> syncQuestState(
    @Body() Map<String, dynamic> body,
  );
}
