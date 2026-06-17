import 'package:go_router/go_router.dart';
import 'package:note_app/core/di/injection.dart';
import 'package:note_app/layers/presentation/flashcards/controller/flashcards_controller.dart';
import 'package:note_app/layers/presentation/flashcards/flashcards_screen.dart';
import 'package:note_app/layers/presentation/shell/main_shell.dart';
import 'package:note_app/layers/presentation/shop/controller/shop_controller.dart';
import 'package:note_app/layers/presentation/shop/shop_screen.dart';
import 'package:note_app/layers/presentation/tasks/controller/tasks_controller.dart';
import 'package:note_app/layers/presentation/tasks/tasks_screen.dart';

enum AppRoute {
  tasks('/tasks'),
  shop('/shop'),
  flashcards('/flashcards');

  const AppRoute(this.path);
  final String path;
}

final appRouter = GoRouter(
  initialLocation: AppRoute.tasks.path,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          MainShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: AppRoute.tasks.path,
          name: AppRoute.tasks.name,
          pageBuilder: (context, state) => NoTransitionPage(
            child: TasksScreen(controller: getIt<TasksController>()),
          ),
        ),
        GoRoute(
          path: AppRoute.shop.path,
          name: AppRoute.shop.name,
          pageBuilder: (context, state) => NoTransitionPage(
            child: ShopScreen(controller: getIt<ShopController>()),
          ),
        ),
        GoRoute(
          path: AppRoute.flashcards.path,
          name: AppRoute.flashcards.name,
          pageBuilder: (context, state) => NoTransitionPage(
            child: FlashCardsScreen(controller: getIt<FlashCardsController>()),
          ),
        ),
      ],
    ),
  ],
);
