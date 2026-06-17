import 'package:flutter/material.dart';
import 'package:note_app/app/app.dart';
import 'package:note_app/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const QuestNoteApp());
}
