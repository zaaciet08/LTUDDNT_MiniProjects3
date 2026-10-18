import 'package:intl/intl.dart';

class CurrencyHelper {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatVND(double amount) {
    final formatNumber = NumberFormat('#,###', 'vi_VN');
    return '${formatNumber.format(amount)} VND';
  }
}
