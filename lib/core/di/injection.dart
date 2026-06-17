import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:note_app/core/network/app_dio.dart';
import 'package:note_app/core/security/auth_token_provider.dart';
import 'package:note_app/layers/data/repository/quest_repository_impl.dart';
import 'package:note_app/layers/data/source/api/dio_quest_api_client.dart';
import 'package:note_app/layers/data/source/api/quest_api_client.dart';
import 'package:note_app/layers/data/source/local/quest_local_data_source.dart';
import 'package:note_app/layers/data/source/local/widget_data_source.dart';
import 'package:note_app/layers/domain/repository/quest_repository.dart';
import 'package:note_app/layers/domain/translator/flash_card_import_translator.dart';
import 'package:note_app/layers/domain/translator/quest_translator.dart';
import 'package:note_app/layers/presentation/flashcards/controller/flashcards_controller.dart';
import 'package:note_app/layers/presentation/shop/controller/shop_controller.dart';
import 'package:note_app/layers/presentation/tasks/controller/tasks_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  final preferences = await SharedPreferences.getInstance();

  getIt
    ..registerSingleton<SharedPreferences>(preferences)
    ..registerLazySingleton<AuthTokenProvider>(AuthTokenProvider.new)
    ..registerLazySingleton<Dio>(() => buildAppDio(getIt<AuthTokenProvider>()))
    ..registerLazySingleton<QuestTranslator>(QuestTranslator.new)
    ..registerLazySingleton<FlashCardImportTranslator>(
      FlashCardImportTranslator.new,
    )
    ..registerLazySingleton<QuestLocalDataSource>(
      () => QuestLocalDataSource(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<WidgetDataSource>(WidgetDataSource.new)
    ..registerLazySingleton<QuestApiClient>(
      () => DioQuestApiClient(getIt<Dio>()),
    )
    ..registerLazySingleton<QuestRepository>(
      () => QuestRepositoryImpl(
        getIt<QuestApiClient>(),
        getIt<QuestLocalDataSource>(),
        getIt<WidgetDataSource>(),
        getIt<QuestTranslator>(),
      ),
    )
    ..registerFactory<TasksController>(
      () => TasksController(getIt<QuestRepository>()),
    )
    ..registerFactory<ShopController>(
      () => ShopController(getIt<QuestRepository>()),
    )
    ..registerFactory<FlashCardsController>(
      () => FlashCardsController(
        getIt<QuestRepository>(),
        getIt<FlashCardImportTranslator>(),
      ),
    );
}
