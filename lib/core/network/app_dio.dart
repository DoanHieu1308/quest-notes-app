import 'package:dio/dio.dart';
import 'package:note_app/core/security/auth_token_provider.dart';

const questApiBaseUrl = String.fromEnvironment(
  'QUEST_API_BASE_URL',
  defaultValue: 'https://quest-notes-be.vercel.app/api',
);

Dio buildAppDio(AuthTokenProvider tokenProvider) {
  final dio = Dio(
    BaseOptions(
      baseUrl: questApiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept-Language'] = 'vi-VN';
        options.headers['X-App-Name'] = 'QuestNotes';
        handler.next(options);
      },
    ),
  );

  return dio;
}
