import 'package:flutter/material.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF070B12),
                        Color(0xFF111A2D),
                        Color(0xFF09101C),
                      ]
                    : const [
                        Color(0xFFF7FBFF),
                        Color(0xFFEEF4FF),
                        Color(0xFFF8FCFF),
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -120,
          child: _GlowOrb(
            color: primary.withValues(alpha: isDark ? 0.25 : 0.17),
            size: 280,
          ),
        ),
        Positioned(
          top: 210,
          left: -90,
          child: _GlowOrb(
            color: secondary.withValues(alpha: isDark ? 0.15 : 0.1),
            size: 210,
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 56, spreadRadius: 10)],
      ),
    );
  }
}
