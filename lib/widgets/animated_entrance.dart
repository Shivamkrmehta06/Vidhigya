import 'package:flutter/material.dart';

class AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double yOffset;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 520),
    this.delay = Duration.zero,
    this.yOffset = 18,
  });

  @override
  Widget build(BuildContext context) {
    final totalMs = duration.inMilliseconds + delay.inMilliseconds;
    final totalDuration = Duration(milliseconds: totalMs);
    final delayFraction =
        totalMs == 0 ? 0.0 : delay.inMilliseconds / totalMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: totalDuration,
      curve: Interval(
        delayFraction,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * yOffset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
