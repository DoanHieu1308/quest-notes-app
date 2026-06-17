import 'package:dio/dio.dart';
import 'package:note_app/core/exceptions/app_exception.dart';
import 'package:note_app/core/response/api_response.dart';
import 'package:note_app/layers/data/response/quest_state_dto.dart';
import 'package:note_app/layers/data/source/api/quest_api_client.dart';

class DioQuestApiClient implements QuestApiClient {
  const DioQuestApiClient(this._dio);

  final Dio _dio;

  @override
  Future<ApiResponse<QuestStateDto>> getQuestState() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/quest/state');
      return _parseStateResponse(response);
    } catch (error) {
      throw NetworkException('Khong the tai du lieu tu server.', cause: error);
    }
  }

  @override
  Future<ApiResponse<QuestStateDto>> syncQuestState(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/quest/sync',
        data: body,
      );
      return _parseStateResponse(response);
    } catch (error) {
      throw NetworkException(
        'Khong the dong bo du lieu voi server.',
        cause: error,
      );
    }
  }

  ApiResponse<QuestStateDto> _parseStateResponse(
    Response<Map<String, dynamic>> response,
  ) {
    final payload = response.data ?? const <String, dynamic>{};
    final rawState = payload['data'] ?? payload['state'];
    if (rawState is! Map) {
      return ApiResponse.failure(
        payload['message'] as String? ?? 'Server khong tra ve du lieu hop le.',
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(
      QuestStateDto.fromJson(Map<String, dynamic>.from(rawState)),
      statusCode: response.statusCode,
    );
  }
}
