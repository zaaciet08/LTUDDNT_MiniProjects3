import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/currency_format.dart';
import '../../models/expense_category.dart';

class DonutChartData {
  final String label;
  final double amount;
  final Color color;

  DonutChartData({required this.label, required this.amount, required this.color});
}

class CustomDonutChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalAmount;

  const CustomDonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty || totalAmount <= 0) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Chưa có dữ liệu chi tiêu',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final List<DonutChartData> items = [];
    categoryTotals.forEach((cat, amt) {
      if (amt > 0) {
        final categoryType = ExpenseCategoryType.fromLabel(cat);
        items.add(DonutChartData(
          label: cat,
          amount: amt,
          color: categoryType.color,
        ));
      }
    });

    return Column(
      children: [
        SizedBox(
          height: 200,
          width: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 200),
                painter: _DonutChartPainter(
                  items: items,
                  total: totalAmount,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TỔNG CỘNG',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyHelper.format(totalAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Legends
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: items.map((item) {
            final percentage = (item.amount / totalAmount * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.label} ($percentage%)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutChartData> items;
  final double total;

  _DonutChartPainter({required this.items, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 28.0;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -pi / 2;

    for (final item in items) {
      final sweepAngle = (item.amount / total) * 2 * pi;

      // Draw segment arc
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Leave a tiny spacing between slices
      final adjustedSweep = sweepAngle > 0.08 ? sweepAngle - 0.05 : sweepAngle;
      final adjustedStart = sweepAngle > 0.08 ? startAngle + 0.025 : startAngle;

      canvas.drawArc(rect, adjustedStart, adjustedSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.items != items;
  }
}
