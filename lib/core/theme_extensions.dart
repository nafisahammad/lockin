import 'package:flutter/material.dart';

extension LockInThemeX on BuildContext {
  Color get lockInSurface => Theme.of(this).colorScheme.surface;
  Color get lockInSurfaceAlt => Theme.of(this).colorScheme.surfaceContainerHighest;
  Color get lockInAccent => Theme.of(this).colorScheme.primary;
  Color get lockInAccentAlt => Theme.of(this).colorScheme.secondary;
  Color get lockInMuted {
    final base =
        Theme.of(this).textTheme.bodyMedium?.color ?? Theme.of(this).colorScheme.onSurface;
    return base.withValues(alpha: 0.7);
  }
}
