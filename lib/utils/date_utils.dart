import 'package:intl/intl.dart';

String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String weekdayVi(DateTime date) {
  const days = [
    'Thứ hai',
    'Thứ ba',
    'Thứ tư',
    'Thứ năm',
    'Thứ sáu',
    'Thứ bảy',
    'Chủ nhật',
  ];
  return days[date.weekday - 1];
}
