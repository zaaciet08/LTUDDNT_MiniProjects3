import 'package:intl/intl.dart';

class DateHelper {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MM/yyyy');
  static final DateFormat _shortDayFormat = DateFormat('dd/MM');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatShortDay(DateTime date) => _shortDayFormat.format(date);
}
