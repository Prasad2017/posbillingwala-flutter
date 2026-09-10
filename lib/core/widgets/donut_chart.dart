import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.values,
    required this.colors,
    this.centerTitle,
    this.centerValue,
    this.size = 156,
    this.strokeWidth = 18,
  });

  final List<double> values;
  final List<Color> colors;
  final String? centerTitle;
  final String? centerValue;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(
              values: values,
              colors: colors,
              total: total == 0 ? 1 : total,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerValue != null)
                Text(centerValue!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        )),
              if (centerTitle != null)
                Text(centerTitle!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.black54,
                        )),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.total,
    required this.strokeWidth,
  });

  final List<double> values;
  final List<Color> colors;
  final double total;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * (math.pi * 2);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = colors[i % colors.length];
      canvas.drawArc(rect, start, math.max(0, sweep - .035), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values != values || old.colors != colors;
}
