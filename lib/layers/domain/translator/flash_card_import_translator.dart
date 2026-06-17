import 'dart:typed_data';

import 'package:excel/excel.dart';

class FlashCardImportTranslator {
  String excelBytesToRawText(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final lines = <String>[];

    for (final table in excel.tables.values) {
      for (final row in table.rows) {
        final values = row.map((cell) => _cellText(cell?.value)).toList();
        final front = _firstNonEmpty(values);
        if (front == null) continue;

        final frontIndex = values.indexOf(front);
        final back = values
            .skip(frontIndex + 1)
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');

        if (back.isNotEmpty) {
          lines.add('$front : $back');
        } else if (front.contains(':')) {
          lines.add(front);
        }
      }
    }

    return lines.join('\n');
  }

  String? _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.isNotEmpty) return value;
    }
    return null;
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
