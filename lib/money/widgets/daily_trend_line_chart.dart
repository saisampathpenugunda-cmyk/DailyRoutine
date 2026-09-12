import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/money_theme.dart';
import '../utils/money_formatter.dart';

/// Native CustomPainter line chart displaying daily financial trends across a date range.
class DailyTrendLineChart extends StatelessWidget {
  final String title;
  final Map<DateTime, double> dailyData;
  final Color lineColor;
  final bool allowNegative;
  final String? subtitle;

  const DailyTrendLineChart({
    super.key,
    required this.title,
    required this.dailyData,
    required this.lineColor,
    this.allowNegative = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MoneyTheme.of(context);
    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final total = sortedEntries.fold<double>(0.0, (sum, e) => sum + e.value);
    final isAllZero = sortedEntries.every((e) => e.value == 0.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Header Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  'Total: ${MoneyFormatter.format(total)}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart Painting Area
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendChartPainter(
                entries: sortedEntries,
                lineColor: lineColor,
                textColor: colors.textSecondary,
                gridColor: colors.divider.withValues(alpha: 0.5),
                baselineColor: colors.textSecondary.withValues(alpha: 0.7),
                allowNegative: allowNegative,
                isAllZero: isAllZero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> entries;
  final Color lineColor;
  final Color textColor;
  final Color gridColor;
  final Color baselineColor;
  final bool allowNegative;
  final bool isAllZero;

  _TrendChartPainter({
    required this.entries,
    required this.lineColor,
    required this.textColor,
    required this.gridColor,
    required this.baselineColor,
    required this.allowNegative,
    required this.isAllZero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const leftPadding = 48.0;
    const rightPadding = 12.0;
    const topPadding = 16.0;
    const bottomPadding = 26.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Determine value ranges
    double minVal;
    double maxVal;

    if (!allowNegative) {
      minVal = 0.0;
      final highest = entries.fold<double>(0.0, (m, e) => math.max(m, e.value));
      maxVal = highest > 0 ? highest * 1.15 : 100.0; // Margin at top
    } else {
      final lowest = entries.fold<double>(0.0, (m, e) => math.min(m, e.value));
      final highest = entries.fold<double>(0.0, (m, e) => math.max(m, e.value));
      if (lowest == 0.0 && highest == 0.0) {
        minVal = -50.0;
        maxVal = 50.0;
      } else {
        final extreme = math.max(lowest.abs(), highest.abs()) * 1.15;
        minVal = -extreme;
        maxVal = extreme;
      }
    }

    final valRange = (maxVal - minVal) > 0 ? (maxVal - minVal) : 1.0;

    // Helper to calculate coordinates
    double getY(double val) {
      final normalized = (val - minVal) / valRange;
      return topPadding + chartHeight * (1.0 - normalized.clamp(0.0, 1.0));
    }

    double getX(int index) {
      if (entries.length <= 1) return leftPadding + chartWidth / 2;
      return leftPadding + (index / (entries.length - 1)) * chartWidth;
    }

    // Grid lines & Y-axis labels
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final baselinePaint = Paint()
      ..color = baselineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Draw grid levels (max, zero/mid, min)
    final gridLevels = allowNegative
        ? [maxVal * 0.8, 0.0, minVal * 0.8]
        : [maxVal * 0.85, maxVal * 0.45, 0.0];

    for (final level in gridLevels) {
      final y = getY(level);
      final isZero = level.abs() < 0.001;

      if (isZero) {
        // Subtle dashed or solid baseline
        canvas.drawLine(
          Offset(leftPadding, y),
          Offset(size.width - rightPadding, y),
          baselinePaint,
        );
      } else {
        canvas.drawLine(
          Offset(leftPadding, y),
          Offset(size.width - rightPadding, y),
          gridPaint,
        );
      }

      // Draw label
      final labelText = _formatCompactNumber(level);
      final tp = TextPainter(
        text: TextSpan(text: labelText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 6, y - tp.height / 2));
    }

    // Draw X-axis date labels
    _drawXAxisLabels(canvas, size, leftPadding, chartWidth, topPadding + chartHeight, textStyle);

    // Build data path
    final linePath = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < entries.length; i++) {
      final x = getX(i);
      final y = getY(entries[i].value);
      final pt = Offset(x, y);
      points.add(pt);

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, getY(0.0));
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path down to baseline y=0
    if (points.isNotEmpty) {
      final lastX = points.last.dx;
      fillPath.lineTo(lastX, getY(0.0));
      fillPath.close();
    }

    // Paint gradient area fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Paint line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, linePaint);

    // Paint points/dots
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw dots on data points (if <= 31 days, draw all or non-zero dots)
    final drawAllDots = entries.length <= 31;
    for (int i = 0; i < points.length; i++) {
      final isNonZero = entries[i].value != 0.0;
      if (drawAllDots || isNonZero) {
        final radius = isNonZero ? 3.0 : 1.8;
        canvas.drawCircle(points[i], radius, dotPaint);
        if (isNonZero) {
          canvas.drawCircle(points[i], radius, dotBorderPaint);
        }
      }
    }
  }

  void _drawXAxisLabels(
    Canvas canvas,
    Size size,
    double leftPadding,
    double chartWidth,
    double yPos,
    TextStyle style,
  ) {
    final count = entries.length;
    if (count == 0) return;

    // Select indices to label (up to 5-6 well-spaced labels)
    final indices = <int>[];
    if (count <= 7) {
      for (int i = 0; i < count; i++) {
        indices.add(i);
      }
    } else {
      final step = (count - 1) / 4.0;
      for (int i = 0; i < 5; i++) {
        final idx = (i * step).round().clamp(0, count - 1);
        if (!indices.contains(idx)) {
          indices.add(idx);
        }
      }
      if (!indices.contains(count - 1)) {
        indices.add(count - 1);
      }
    }

    for (final idx in indices) {
      final date = entries[idx].key;
      final x = count <= 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (idx / (count - 1)) * chartWidth;
      final text = '${date.day} ${_monthName(date.month)}';

      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelX = (x - tp.width / 2).clamp(leftPadding, size.width - tp.width);
      tp.paint(canvas, Offset(labelX, yPos + 6));
    }
  }

  String _formatCompactNumber(double val) {
    final isNeg = val < 0;
    final absVal = val.abs();
    final prefix = isNeg ? '-₹' : '₹';

    if (absVal >= 100000) {
      return '$prefix${(absVal / 100000).toStringAsFixed(1)}L';
    } else if (absVal >= 1000) {
      return '$prefix${(absVal / 1000).toStringAsFixed(1)}k';
    } else {
      return '$prefix${absVal.toStringAsFixed(0)}';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.allowNegative != allowNegative;
  }
}
