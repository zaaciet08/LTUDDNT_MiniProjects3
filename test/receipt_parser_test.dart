import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_expense_tracker/services/receipt_parser.dart';
import 'package:receipt_expense_tracker/models/expense_category.dart';

void main() {
  group('Dart Regex Parser Engine Tests', () {
    test('Extracts merchant, date, and total from Vietnamese bookstore receipt', () {
      const sampleText = '''
NHÀ SÁCH FAHASA ĐÀ NẴNG
Đ/c: 300 Lê Duẩn, Đà Nẵng
Ngày lập: 12/10/2026 14:30
Thu ngân: NV01

1. Tập Giấy A4 Double A      95.000đ
2. Bút bi Thiên Long 10 cây   50.000đ

TỔNG CỘNG: 145.000 VND
Tiền mặt: 200.000 VND
''';

      final result = ReceiptParserEngine.parse(sampleText);

      expect(result.merchant, contains('FAHASA'));
      expect(result.totalAmount, equals(145000.0));
      expect(result.date.day, equals(12));
      expect(result.date.month, equals(10));
      expect(result.date.year, equals(2026));
      expect(result.suggestedCategory, equals(ExpenseCategoryType.stationery.label));
    });

    test('Extracts total and merchant from Highlands Coffee receipt', () {
      const sampleCoffeeReceipt = '''
HIGHLANDS COFFEE HÒA QUÝ
Date: 10/10/2026
1 Freeze Tra Xanh L    65,000
1 Phin Sua Da M        29,000
TONG TIEN: 94,000 VND
''';

      final result = ReceiptParserEngine.parse(sampleCoffeeReceipt);

      expect(result.merchant, contains('HIGHLANDS COFFEE'));
      expect(result.totalAmount, equals(94000.0));
      expect(result.suggestedCategory, equals(ExpenseCategoryType.foodAndBeverage.label));
    });

    test('Extracts event equipment receipt', () {
      const sampleEventReceipt = '''
CỬA HÀNG THIẾT BỊ SỰ KIỆN ÂM THANH
Ngày: 05-10-2026
Dây cáp HDMI 10m        180.000
Micro không dây Shure   450.000
THÀNH TIỀN: 630.000 đ
''';

      final result = ReceiptParserEngine.parse(sampleEventReceipt);

      expect(result.merchant, contains('THIẾT BỊ SỰ KIỆN'));
      expect(result.totalAmount, equals(630000.0));
      expect(result.date.day, equals(5));
      expect(result.date.month, equals(10));
    });
  });
}
