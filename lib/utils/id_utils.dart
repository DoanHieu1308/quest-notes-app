import 'dart:math';

String newId() {
  return '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';
}
