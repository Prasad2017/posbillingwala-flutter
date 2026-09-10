import 'package:flutter/material.dart';

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    this.color,
    this.height = 84,
  });

  final List<double> values;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<double>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: value / max),
                  builder: (context, animatedValue, child) => Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: height * animatedValue,
                      decoration: BoxDecoration(
                        color: color ?? Theme.of(context).colorScheme.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
