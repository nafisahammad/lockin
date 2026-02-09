import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';

ThemeData buildLockInTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
    bodyColor: kLockInText,
    displayColor: kLockInText,
  );

  return base.copyWith(
    scaffoldBackgroundColor: kLockInBg,
    colorScheme: base.colorScheme.copyWith(
      surface: kLockInSurface,
      surfaceContainerHighest: kLockInSurfaceAlt,
      primary: kLockInAccent,
      secondary: kLockInAccentAlt,
      onSurface: kLockInText,
      onSurfaceVariant: kLockInText,
      onPrimary: Colors.white,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: kLockInBg,
      foregroundColor: kLockInText,
      elevation: 0,
    ),
    cardColor: kLockInSurface,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kLockInSurfaceAlt,
      contentTextStyle: TextStyle(color: kLockInText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kLockInAccent,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kLockInSurfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: kLockInMuted),
    ),
    dividerColor: kLockInSurfaceAlt,
  );
}

ThemeData buildLockInLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
    bodyColor: kLockInLightText,
    displayColor: kLockInLightText,
  );

  return base.copyWith(
    scaffoldBackgroundColor: kLockInLightBg,
    colorScheme: base.colorScheme.copyWith(
      surface: kLockInLightSurface,
      surfaceContainerHighest: kLockInLightSurfaceAlt,
      primary: kLockInAccent,
      secondary: kLockInAccentAlt,
      onSurface: kLockInLightText,
      onSurfaceVariant: kLockInLightText,
      onPrimary: Colors.white,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: kLockInLightBg,
      foregroundColor: kLockInLightText,
      elevation: 0,
    ),
    cardColor: kLockInLightSurface,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kLockInLightSurfaceAlt,
      contentTextStyle: TextStyle(color: kLockInLightText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kLockInAccent,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kLockInLightSurfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: kLockInLightMuted),
    ),
    dividerColor: kLockInLightSurfaceAlt,
  );
}
