import 'package:flutter/material.dart';
import 'package:note_app/routes/app_router.dart';
import 'package:note_app/utils/app_theme.dart';

class QuestNoteApp extends StatelessWidget {
  const QuestNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Quest Notes',
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
