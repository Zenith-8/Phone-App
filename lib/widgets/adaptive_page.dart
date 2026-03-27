import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A page that uses a Cupertino-style route on iOS/macOS to enable the interactive back swipe.
class AdaptivePage<T> extends Page<T> {
  const AdaptivePage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isCupertino = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    if (isCupertino) {
      return CupertinoPageRoute<T>(
        settings: this,
        builder: (context) => child,
      );
    }
    return MaterialPageRoute<T>(
      settings: this,
      builder: (context) => child,
    );
  }
}

