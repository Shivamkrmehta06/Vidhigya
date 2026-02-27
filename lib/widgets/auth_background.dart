import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthBackground extends StatefulWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.cloud,
                  AppTheme.mist,
                  Color(0xFFEAF2FF),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: _AnimatedOrb(
            animation: _orbController,
            start: const Alignment(-1.22, -0.86),
            end: const Alignment(-0.9, -0.58),
            size: 220,
            colors: const [Color(0x334CB7D8), Color(0x4434D399)],
          ),
        ),
        Positioned.fill(
          child: _AnimatedOrb(
            animation: _orbController,
            start: const Alignment(1.16, -0.2),
            end: const Alignment(0.9, 0.08),
            size: 290,
            colors: const [Color(0x33F2B95B), Color(0x224CB7D8)],
            phaseShift: 0.16,
          ),
        ),
        Positioned.fill(
          child: _AnimatedOrb(
            animation: _orbController,
            start: const Alignment(-0.12, 1.3),
            end: const Alignment(0.2, 1.02),
            size: 250,
            colors: const [Color(0x2214B8A6), Color(0x334CB7D8)],
            phaseShift: 0.28,
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _AnimatedOrb extends StatelessWidget {
  final Animation<double> animation;
  final Alignment start;
  final Alignment end;
  final double size;
  final List<Color> colors;
  final double phaseShift;

  const _AnimatedOrb({
    required this.animation,
    required this.start,
    required this.end,
    required this.size,
    required this.colors,
    this.phaseShift = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final raw = (animation.value + phaseShift) % 1;
        final t = Curves.easeInOut.transform(raw);
        return Align(
          alignment: Alignment.lerp(start, end, t)!,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
        );
      },
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppTheme.surface(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: surface.withOpacity(isDark ? 0.9 : 0.82),
            border: Border.all(color: AppTheme.border(context)),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
