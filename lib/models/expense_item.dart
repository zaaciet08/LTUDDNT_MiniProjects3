import 'expense_category.dart';

class ExpenseItem {
  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final String category;
  final String? imagePath;
  final String? rawOcrText;
  final DateTime createdAt;

  ExpenseItem({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.imagePath,
    this.rawOcrText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ExpenseCategoryType get categoryType => ExpenseCategoryType.fromLabel(category);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'image_path': imagePath,
      'raw_ocr_text': rawOcrText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as int?,
      merchant: (map['merchant'] as String?) ?? 'Hóa đơn chưa đặt tên',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: (map['category'] as String?) ?? ExpenseCategoryType.other.label,
      imagePath: map['image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ExpenseItem copyWith({
    int? id,
    String? merchant,
    double? amount,
    DateTime? date,
    String? category,
    String? imagePath,
    String? rawOcrText,
    DateTime? createdAt,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
