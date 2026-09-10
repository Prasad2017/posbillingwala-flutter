import 'package:flutter/material.dart';

class ThreeDotsLoader extends StatefulWidget {
  const ThreeDotsLoader({
    super.key,
    this.color = Colors.white,
    this.dotSize = 7,
    this.spacing = 5,
  });

  final Color color;
  final double dotSize;
  final double spacing;

  @override
  State<ThreeDotsLoader> createState() => _ThreeDotsLoaderState();
}

class _ThreeDotsLoaderState extends State<ThreeDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _bounceOffset(double t) {
    // Smooth up-down bounce per dot cycle.
    return -5 * (t < 0.5 ? t * 2 : (1 - t) * 2);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final phase = (_controller.value - index * 0.18) % 1.0;
              final offsetY = _bounceOffset(phase < 0 ? phase + 1 : phase);
              return Transform.translate(
                offset: Offset(0, offsetY),
                child: child,
              );
            },
            child: Container(
              width: widget.dotSize,
              height: widget.dotSize,
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}
