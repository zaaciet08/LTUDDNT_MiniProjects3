import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/date_format.dart';

class CustomBarChart extends StatelessWidget {
  final Map<DateTime, double> dailyTotals;

  const CustomBarChart({
    super.key,
    required this.dailyTotals,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyTotals.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Text('Không có dữ liệu 7 ngày qua'),
      );
    }

    final maxVal = dailyTotals.values.fold<double>(0.0, (prev, elem) => max(prev, elem));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarChartPainter(
              dailyTotals: dailyTotals,
              maxAmount: maxVal > 0 ? maxVal : 100000,
            ),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<DateTime, double> dailyTotals;
  final double maxAmount;

  _BarChartPainter({required this.dailyTotals, required this.maxAmount});

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPadding = 26.0;
    const topPadding = 24.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final entries = dailyTotals.entries.toList();
    final barCount = entries.length;
    if (barCount == 0) return;

    final totalSpacing = size.width / barCount;
    final barWidth = min(totalSpacing * 0.55, 26.0);

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i < barCount; i++) {
      final entry = entries[i];
      final date = entry.key;
      final amount = entry.value;

      final centerX = totalSpacing * i + (totalSpacing / 2);
      final barHeight = (amount / maxAmount) * chartHeight;
      final barTop = topPadding + (chartHeight - barHeight);
      final barBottom = topPadding + chartHeight;

      // Draw Bar Background slot
      final bgPaint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.fill;
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(centerX - barWidth / 2, topPadding, centerX + barWidth / 2, barBottom),
        const Radius.circular(6),
      );
      canvas.drawRRect(bgRect, bgPaint);

      // Draw Active Bar with Gradient
      if (amount > 0) {
        final isHighest = amount == maxAmount;
        final rect = Rect.fromLTRB(centerX - barWidth / 2, barTop, centerX + barWidth / 2, barBottom);
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: isHighest
                ? [const Color(0xFF6366F1), const Color(0xFF818CF8)]
                : [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
          ).createShader(rect);

        final rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        );
        canvas.drawRRect(rrect, barPaint);

        // Draw text amount above bar
        final textSpan = TextSpan(
          text: _formatCompactAmount(amount),
          style: TextStyle(
            color: isHighest ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
            fontSize: 9,
            fontWeight: isHighest ? FontWeight.bold : FontWeight.w500,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(centerX - (tp.width / 2), barTop - tp.height - 3));
      }

      // Draw Date label on X-axis
      final dateSpan = TextSpan(
        text: DateHelper.formatShortDay(date),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      final datePainter = TextPainter(
        text: dateSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      datePainter.paint(
        canvas,
        Offset(centerX - (datePainter.width / 2), size.height - bottomPadding + 6),
      );
    }
  }

  String _formatCompactAmount(double amt) {
    if (amt >= 1000000) {
      return '${(amt / 1000000).toStringAsFixed(1)}M';
    } else if (amt >= 1000) {
      return '${(amt / 1000).round()}k';
    }
    return amt.round().toString();
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.dailyTotals != dailyTotals || oldDelegate.maxAmount != maxAmount;
  }
}
