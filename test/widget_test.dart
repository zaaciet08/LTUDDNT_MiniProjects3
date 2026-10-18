import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_expense_tracker/presentation/widgets/custom_donut_chart.dart';
import 'package:receipt_expense_tracker/presentation/widgets/custom_bar_chart.dart';

void main() {
  testWidgets('Custom Canvas Donut Chart renders correctly', (WidgetTester tester) async {
    final testData = {
      'Ăn uống & Cà phê': 150000.0,
      'Văn phòng phẩm & In ấn': 250000.0,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomDonutChart(
            categoryTotals: testData,
            totalAmount: 400000.0,
          ),
        ),
      ),
    );

    // Verify labels and custom canvas widget mounted
    expect(find.byType(CustomDonutChart), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('TỔNG CỘNG'), findsOneWidget);
  });

  testWidgets('Custom Canvas Bar Chart renders correctly', (WidgetTester tester) async {
    final now = DateTime.now();
    final testDaily = {
      now.subtract(const Duration(days: 1)): 100000.0,
      now: 200000.0,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomBarChart(
            dailyTotals: testDaily,
          ),
        ),
      ),
    );

    expect(find.byType(CustomBarChart), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
