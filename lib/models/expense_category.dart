import 'package:flutter/material.dart';

enum ExpenseCategoryType {
  foodAndBeverage('Ăn uống & Cà phê', Icons.restaurant, Color(0xFFEF4444)),
  clubEvent('Sự kiện CLB', Icons.celebration, Color(0xFF8B5CF6)),
  stationery('Văn phòng phẩm & In ấn', Icons.menu_book, Color(0xFF3B82F6)),
  transportation('Di chuyển & Đi lại', Icons.directions_bus, Color(0xFF10B981)),
  equipment('Thiết bị & Dụng cụ', Icons.build_circle, Color(0xFFF59E0B)),
  other('Chi phí khác', Icons.category, Color(0xFF6B7280));

  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategoryType(this.label, this.icon, this.color);

  static ExpenseCategoryType fromLabel(String? label) {
    if (label == null) return ExpenseCategoryType.other;
    return ExpenseCategoryType.values.firstWhere(
      (element) => element.label.toLowerCase() == label.toLowerCase(),
      orElse: () => ExpenseCategoryType.other,
    );
  }
}
