import 'dart:typed_data';

import 'package:excel/excel.dart';

class FlashCardImportTranslator {
  String excelBytesToRawText(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final lines = <String>[];

    for (final table in excel.tables.values) {
      for (final row in table.rows) {
        final front = _cellText(row.isNotEmpty ? row[0]?.value : null);
        final meaning = _cellText(row.length > 1 ? row[1]?.value : null);
        final phonetic = _cellText(row.length > 2 ? row[2]?.value : null);
        if (front.isEmpty) continue;
        if (_isHeaderRow(front, meaning, phonetic)) continue;

        final back = _backText(meaning, phonetic);
        if (back.isNotEmpty) {
          lines.add('$front : $back');
        } else if (front.contains(':')) {
          lines.add(front);
        }
      }
    }

    return lines.join('\n');
  }

  String _backText(String meaning, String phonetic) {
    final parts = <String>[];
    if (meaning.isNotEmpty) parts.add(meaning);
    if (phonetic.isNotEmpty) parts.add('[${_stripBrackets(phonetic)}]');
    return parts.join('\n');
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

  bool _isHeaderRow(String front, String meaning, String phonetic) {
    final normalized = [
      front,
      meaning,
      phonetic,
    ].map((value) => value.toLowerCase()).join('|');
    return normalized == 'từ vựng|nghĩa|phiên âm' ||
        normalized == 'tu vung|nghia|phien am' ||
        normalized == 'vocabulary|meaning|phonetic';
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
