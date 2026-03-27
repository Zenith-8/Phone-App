import 'package:flutter/material.dart';

class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 44, this.heroTag = 'app-mark'});

  final double size;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = size * 0.54;
    final isDark = scheme.brightness == Brightness.dark;
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.36),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: isDark ? 0.94 : 0.92),
                Color.lerp(
                  scheme.primary,
                  scheme.secondary,
                  0.42,
                )!.withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: isDark ? 0.35 : 0.28),
                blurRadius: size * 0.22,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: SizedBox(
            height: size,
            width: size,
            child: Center(
              child: Icon(
                Icons.fitness_center_rounded,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
