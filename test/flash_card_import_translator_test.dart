import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/layers/domain/translator/flash_card_import_translator.dart';

void main() {
  test('maps Excel columns A/B/C to flashcard front and multiline back', () {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow([
      TextCellValue('vocabulary'),
      TextCellValue('meaning'),
      TextCellValue('phonetic'),
    ]);
    sheet.appendRow([
      TextCellValue('hello'),
      TextCellValue('xin chao'),
      TextCellValue('he-lo'),
    ]);
    sheet.appendRow([
      TextCellValue('apple'),
      TextCellValue('qua tao'),
      TextCellValue('[ap-pul]'),
    ]);

    final bytes = Uint8List.fromList(excel.encode()!);
    final rawText = FlashCardImportTranslator().excelBytesToRawText(bytes);

    expect(rawText, 'hello : xin chao\n[he-lo]\napple : qua tao\n[ap-pul]');
  });
}
