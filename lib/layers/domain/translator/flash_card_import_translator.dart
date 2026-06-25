import 'dart:typed_data';

import 'package:excel/excel.dart';

class FlashCardImportTranslator {
  String excelBytesToRawText(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final lines = <String>[];

    for (final table in excel.tables.values) {
      for (final row in table.rows) {
        final front = _cellText(row.isNotEmpty ? row[0]?.value : null);
        final frontPhonetic = _cellText(row.length > 1 ? row[1]?.value : null);
        final back = _cellText(row.length > 2 ? row[2]?.value : null);
        final backPhonetic = _cellText(row.length > 3 ? row[3]?.value : null);
        final meaning = _cellText(row.length > 4 ? row[4]?.value : null);
        if (front.isEmpty) continue;
        if (_isHeaderRow(front, frontPhonetic, back, backPhonetic, meaning)) {
          continue;
        }

        if (back.isNotEmpty) {
          lines.add(
            [
              front,
              _stripBrackets(frontPhonetic),
              back,
              _stripBrackets(backPhonetic),
              meaning,
            ].join(' : '),
          );
        } else if (front.contains(':')) {
          lines.add(front);
        }
      }
    }

    return lines.join('\n');
  }

  String _stripBrackets(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('[') &&
        trimmed.endsWith(']') &&
        trimmed.length > 1) {
      return trimmed.substring(1, trimmed.length - 1).trim();
    }
    return trimmed;
  }

  bool _isHeaderRow(
    String front,
    String frontPhonetic,
    String back,
    String backPhonetic,
    String meaning,
  ) {
    final normalized = [
      front,
      frontPhonetic,
      back,
      backPhonetic,
      meaning,
    ].map((value) => value.toLowerCase()).join('|');
    return normalized ==
            'từ vựng mặt trước|phiên âm mặt trước|từ vựng mặt sau|phiên âm mặt sau|nghĩa' ||
        normalized == 'front|front phonetic|back|back phonetic|meaning';
  }

  String _cellText(CellValue? value) {
    if (value == null) return '';
    return switch (value) {
      TextCellValue(:final value) => value.toString().trim(),
      IntCellValue(:final value) => value.toString(),
      DoubleCellValue(:final value) => value.toString(),
      BoolCellValue(:final value) => value ? 'true' : 'false',
      DateCellValue() => value.asDateTimeLocal().toIso8601String(),
      TimeCellValue() => value.toString(),
      DateTimeCellValue() => value.asDateTimeLocal().toIso8601String(),
      FormulaCellValue(:final formula) => formula.trim(),
    };
  }
}
