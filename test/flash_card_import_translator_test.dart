import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/layers/domain/translator/flash_card_import_translator.dart';

void main() {
  test('maps Excel columns A/B/C/D/E to flashcard sides and meaning', () {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow([
      TextCellValue('front'),
      TextCellValue('front phonetic'),
      TextCellValue('back'),
      TextCellValue('back phonetic'),
      TextCellValue('meaning'),
    ]);
    sheet.appendRow([
      TextCellValue('hello'),
      TextCellValue('he-lo'),
      TextCellValue('你好'),
      TextCellValue('ni hao'),
      TextCellValue('xin chao'),
    ]);
    sheet.appendRow([
      TextCellValue('apple'),
      TextCellValue('[ap-pul]'),
      TextCellValue('苹果'),
      TextCellValue('[ping guo]'),
      TextCellValue('qua tao'),
    ]);

    final bytes = Uint8List.fromList(excel.encode()!);
    final rawText = FlashCardImportTranslator().excelBytesToRawText(bytes);

    expect(
      rawText,
      'hello : he-lo : 你好 : ni hao : xin chao\n'
      'apple : ap-pul : 苹果 : ping guo : qua tao',
    );
  });
}
