import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.surface,
                  isDark ? const Color(0xFF070A10) : const Color(0xFFEFF2F9),
                ],
              ),
            ),
          ),
        ),
        _Orb(
          alignment: const Alignment(-0.92, -0.92),
          color: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.16),
          size: 210,
        ),
        _Orb(
          alignment: const Alignment(1.02, -0.62),
          color: scheme.secondary.withValues(alpha: isDark ? 0.16 : 0.14),
          size: 180,
        ),
        _Orb(
          alignment: const Alignment(0.86, 0.96),
          color: scheme.primaryContainer.withValues(
            alpha: isDark ? 0.16 : 0.24,
          ),
          size: 240,
        ),
        Positioned.fill(
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: size * 0.45,
                spreadRadius: size * 0.05,
              ),
            ],
          ),
          child: SizedBox(height: size, width: size),
        ),
      ),
    );
  }
}
