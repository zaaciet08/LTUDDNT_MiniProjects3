import '../models/expense_category.dart';

class ParsedReceiptData {
  final String merchant;
  final double totalAmount;
  final DateTime date;
  final String suggestedCategory;
  final String rawText;
  final double confidenceScore;

  ParsedReceiptData({
    required this.merchant,
    required this.totalAmount,
    required this.date,
    required this.suggestedCategory,
    required this.rawText,
    this.confidenceScore = 1.0,
  });
}

class ReceiptParserEngine {
  /// Main parser method taking raw OCR text and returning structured receipt data
  static ParsedReceiptData parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ParsedReceiptData(
        merchant: 'Hóa đơn chưa xác định',
        totalAmount: 0.0,
        date: DateTime.now(),
        suggestedCategory: ExpenseCategoryType.other.label,
        rawText: rawText,
        confidenceScore: 0.0,
      );
    }

    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final merchant = _extractMerchant(lines);
    final totalAmount = _extractTotal(lines, rawText);
    final date = _extractDate(lines, rawText);
    final suggestedCategory = _detectCategory(merchant, rawText);

    return ParsedReceiptData(
      merchant: merchant,
      totalAmount: totalAmount,
      date: date,
      suggestedCategory: suggestedCategory,
      rawText: rawText,
      confidenceScore: (totalAmount > 0 && merchant.isNotEmpty) ? 0.95 : 0.6,
    );
  }

  /// 1. Extract Total Amount using Regex & Heuristics
  static double _extractTotal(List<String> lines, String fullText) {
    // Keywords signifying total amount in Vietnamese and English receipts
    final totalKeywords = [
      'tổng cộng',
      'tổng tiền',
      'thành tiền',
      'thanh toan',
      'thanh toán',
      'cộng tiền hàng',
      'tong cong',
      'tong tien',
      'thanh tien',
      'tien mat',
      'tiền mặt',
      'total amount',
      'grand total',
      'total',
      'amount due',
      'amount',
      'sum',
    ];

    // Priority 1: Find lines with Total keywords
    for (int i = 0; i < lines.length; i++) {
      final lineLower = lines[i].toLowerCase();

      for (final kw in totalKeywords) {
        if (lineLower.contains(kw)) {
          // Look for amount on this line
          final amount = _findAmountInString(lines[i]);
          if (amount != null && amount > 0) {
            return amount;
          }

          // Sometimes amount is on the next line
          if (i + 1 < lines.length) {
            final nextAmount = _findAmountInString(lines[i + 1]);
            if (nextAmount != null && nextAmount > 0) {
              return nextAmount;
            }
          }
        }
      }
    }

    // Priority 2: Fallback - Extract all valid monetary numbers in the bottom half
    final allAmounts = <double>[];
    final startIndex = (lines.length / 2).floor();
    for (int i = startIndex; i < lines.length; i++) {
      final amt = _findAmountInString(lines[i]);
      if (amt != null && amt > 0) {
        allAmounts.add(amt);
      }
    }

    if (allAmounts.isNotEmpty) {
      // Typically, total is the maximum value near bottom
      allAmounts.sort();
      return allAmounts.last;
    }

    // Priority 3: Scan anywhere in entire text for highest number matching money format
    for (final line in lines) {
      final amt = _findAmountInString(line);
      if (amt != null && amt > 0) {
        allAmounts.add(amt);
      }
    }

    if (allAmounts.isNotEmpty) {
      allAmounts.sort();
      return allAmounts.last;
    }

    return 0.0;
  }

  /// Helper to extract clean numerical amount from a string
  static double? _findAmountInString(String text) {
    // Matches formats like: 150.000, 150,000, 150000, 45.50, $25.00, 50.000đ, 100k
    final regex = RegExp(
      r'(?:[\$đ₫\s]|^)(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?|\d{1,3}k)(?:[\$đ₫\s]|$)',
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);
    for (final match in matches) {
      var numStr = match.group(1)?.trim() ?? '';
      if (numStr.isEmpty) continue;

      // Handle 'k' (e.g. 50k = 50000)
      if (numStr.toLowerCase().endsWith('k')) {
        final val = double.tryParse(numStr.substring(0, numStr.length - 1));
        if (val != null) return val * 1000;
      }

      // Handle thousand separators in Vietnam (dots like 150.000 or commas like 150,000)
      if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(numStr)) {
        // Vietnamese standard: 150.000 -> 150000
        numStr = numStr.replaceAll('.', '');
      } else if (RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(numStr)) {
        // Standard comma thousand separator: 150,000 -> 150000
        numStr = numStr.replaceAll(',', '');
      } else if (numStr.contains('.') && numStr.contains(',')) {
        // e.g. 1.250,50 or 1,250.50
        if (numStr.lastIndexOf(',') > numStr.lastIndexOf('.')) {
          numStr = numStr.replaceAll('.', '').replaceAll(',', '.');
        } else {
          numStr = numStr.replaceAll(',', '');
        }
      }

      final parsed = double.tryParse(numStr);
      if (parsed != null && parsed >= 1000) {
        // Typical receipt total in VND is usually >= 1,000
        return parsed;
      } else if (parsed != null && parsed > 0 && parsed < 1000 && text.contains('\$')) {
        // Foreign currency (USD)
        return parsed;
      } else if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return null;
  }

  /// 2. Extract Date using Regex
  static DateTime _extractDate(List<String> lines, String fullText) {
    // Regex for: dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy, yyyy-MM-dd, dd/MM/yy
    final datePatterns = [
      RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})'), // 25/12/2026
      RegExp(r'(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})'), // 2026-12-25
      RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2})'),   // 25/12/26
    ];

    // First scan lines with date indicators
    final dateKeywords = ['ngày', 'ngay', 'date', 'time', 'ngày lập', 'ngày bán', 'gio', 'giờ'];
    for (final line in lines) {
      final lineLower = line.toLowerCase();
      if (dateKeywords.any((kw) => lineLower.contains(kw))) {
        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final parsed = _buildDateFromMatch(match);
            if (parsed != null) return parsed;
          }
        }
      }
    }

    // Fallback: scan whole text for any valid date match
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        final parsed = _buildDateFromMatch(match);
        if (parsed != null) return parsed;
      }
    }

    return DateTime.now();
  }

  static DateTime? _buildDateFromMatch(Match match) {
    try {
      int d, m, y;
      final g1 = int.parse(match.group(1)!);
      final g2 = int.parse(match.group(2)!);
      final g3 = int.parse(match.group(3)!);

      if (g1 > 1000) {
        // yyyy-MM-dd
        y = g1;
        m = g2;
        d = g3;
      } else {
        // dd-MM-yyyy or dd-MM-yy
        d = g1;
        m = g2;
        y = (g3 < 100) ? 2000 + g3 : g3;
      }

      if (m >= 1 && m <= 12 && d >= 1 && d <= 31 && y >= 2020 && y <= 2035) {
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }

  /// 3. Extract Merchant / Store Name
  static String _extractMerchant(List<String> lines) {
    final ignoredHeaders = [
      'hóa đơn',
      'hoa don',
      'phiếu thanh toán',
      'phieu thanh toan',
      'hóa đơn bán lẻ',
      'phiếu tính tiền',
      'receipt',
      'invoice',
      'tax invoice',
      'vat',
      'welcome',
      'kính chào quý khách',
      'địa chỉ',
      'dia chi',
      'đc:',
      'tel:',
      'sđt:',
      'hotline:',
      'wifi',
      'bàn:',
      'thu ngân:',
    ];

    final merchantIndicators = [
      'cửa hàng',
      'siêu thị',
      'nhà sách',
      'cà phê',
      'cafe',
      'coffee',
      'quán',
      'tiệm',
      'store',
      'shop',
      'mart',
      'highlands',
      'phúc long',
      'mixue',
      'circle k',
      'winmart',
      'ministop',
      'fahasa',
      'vku',
      'canteen',
      'in ấn',
    ];

    // Priority 1: Check lines 0..5 for explicit merchant keywords
    final checkLimit = lines.length < 6 ? lines.length : 6;
    for (int i = 0; i < checkLimit; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      if (merchantIndicators.any((ind) => lineLower.contains(ind))) {
        return _cleanMerchantName(line);
      }
    }

    // Priority 2: Take the first non-generic header line
    for (int i = 0; i < checkLimit; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      final isIgnored = ignoredHeaders.any((h) => lineLower.contains(h));
      final hasLetters = RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(line);
      final isTooShort = line.trim().length < 3;

      if (!isIgnored && hasLetters && !isTooShort) {
        return _cleanMerchantName(line);
      }
    }

    return 'Hóa đơn mua hàng VKU';
  }

  static String _cleanMerchantName(String name) {
    // Strip leading punctuation or extra symbols
    var cleaned = name.replaceAll(RegExp(r'^[^\wÀ-ỹ]+|[^\wÀ-ỹ]+$'), '').trim();
    if (cleaned.length > 40) {
      cleaned = cleaned.substring(0, 40).trim();
    }
    return cleaned;
  }

  /// 4. Auto-detect category based on merchant and items in text
  static String _detectCategory(String merchant, String fullText) {
    final combined = '$merchant $fullText'.toLowerCase();

    if (combined.contains('cà phê') ||
        combined.contains('cafe') ||
        combined.contains('coffee') ||
        combined.contains('trà sữa') ||
        combined.contains('ăn uống') ||
        combined.contains('quán ăn') ||
        combined.contains('cơm') ||
        combined.contains('phở') ||
        combined.contains('bún') ||
        combined.contains('bánh') ||
        combined.contains('highlands') ||
        combined.contains('mixue') ||
        combined.contains('canteen')) {
      return ExpenseCategoryType.foodAndBeverage.label;
    }

    if (combined.contains('nhà sách') ||
        combined.contains('fahasa') ||
        combined.contains('in ấn') ||
        combined.contains('photo') ||
        combined.contains('văn phòng phẩm') ||
        combined.contains('giấy a4') ||
        combined.contains('bút') ||
        combined.contains('tập vở')) {
      return ExpenseCategoryType.stationery.label;
    }

    if (combined.contains('sự kiện') ||
        combined.contains('clb') ||
        combined.contains('hội nghị') ||
        combined.contains('backdrop') ||
        combined.contains('sân khấu') ||
        combined.contains('hoa tươi') ||
        combined.contains('băng rôn') ||
        combined.contains('huy hiệu')) {
      return ExpenseCategoryType.clubEvent.label;
    }

    if (combined.contains('grab') ||
        combined.contains('be ') ||
        combined.contains('xăng') ||
        combined.contains('xe buýt') ||
        combined.contains('taxi') ||
        combined.contains('vé xe') ||
        combined.contains('bến xe')) {
      return ExpenseCategoryType.transportation.label;
    }

    if (combined.contains('thiết bị') ||
        combined.contains('điện máy') ||
        combined.contains('dây cáp') ||
        combined.contains('hdmi') ||
        combined.contains('ổ cắm') ||
        combined.contains('loa') ||
        combined.contains('mic') ||
        combined.contains('micro')) {
      return ExpenseCategoryType.equipment.label;
    }

    return ExpenseCategoryType.other.label;
  }
}
