import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/app/app.dart';
import 'package:note_app/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Quest Notes starts with local data store', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();

    await tester.pumpWidget(const QuestNoteApp());
    await tester.pumpAndSettle();

    expect(find.text('Quest Notes'), findsOneWidget);
    expect(find.textContaining('cong viec'), findsNothing);
    expect(find.byType(QuestNoteApp), findsOneWidget);
  });
}
