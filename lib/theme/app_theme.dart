import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  static const Color _brand = Color(0xFF0A84FF);
  static const Color _mint = Color(0xFF30D5C8);
  static const Color _surfaceLight = Color(0xFFF2F2F7);
  static const Color _surfaceDark = Color(0xFF000000);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _brand,
      onPrimary: Colors.white,
      secondary: _mint,
      onSecondary: Color(0xFF002521),
      error: Color(0xFFFF3B30),
      onError: Colors.white,
      surface: _surfaceLight,
      onSurface: Color(0xFF121318),
      primaryContainer: Color(0xFFE7F1FF),
      onPrimaryContainer: Color(0xFF002C5F),
      secondaryContainer: Color(0xFFD8F7F3),
      onSecondaryContainer: Color(0xFF003B34),
      tertiary: Color(0xFF4A5568),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE9EDF2),
      onTertiaryContainer: Color(0xFF1F2937),
      outline: Color(0xFFC9CED8),
      outlineVariant: Color(0xFFDCE0E8),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF1A1B21),
      onInverseSurface: Color(0xFFF4F5F8),
      inversePrimary: Color(0xFF9BC7FF),
      surfaceTint: _brand,
    );
    return _build(scheme);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8ABEFF),
      onPrimary: Color(0xFF022B60),
      secondary: Color(0xFF7EE7DC),
      onSecondary: Color(0xFF003831),
      error: Color(0xFFFF897D),
      onError: Color(0xFF630D08),
      surface: _surfaceDark,
      onSurface: Color(0xFFF4F5F8),
      primaryContainer: Color(0xFF163A6A),
      onPrimaryContainer: Color(0xFFDCEBFF),
      secondaryContainer: Color(0xFF104943),
      onSecondaryContainer: Color(0xFFC5F7F0),
      tertiary: Color(0xFFA4AFBF),
      onTertiary: Color(0xFF1D2837),
      tertiaryContainer: Color(0xFF2A3341),
      onTertiaryContainer: Color(0xFFDDE3EA),
      outline: Color(0xFF495060),
      outlineVariant: Color(0xFF252A33),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFF4F5F8),
      onInverseSurface: Color(0xFF13141A),
      inversePrimary: _brand,
      surfaceTint: Color(0xFF8ABEFF),
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: '.SF Pro Text',
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: scheme.brightness,
        primaryColor: scheme.primary,
        scaffoldBackgroundColor: scheme.surface,
      ),
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.35),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: isDark
            ? const Color(0x99191C23)
            : Colors.white.withValues(alpha: 0.78),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.8 : 0.9),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xCC141820)
            : Colors.white.withValues(alpha: 0.92),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.7),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: isDark
            ? const Color(0xCC111419)
            : const Color(0xCCEDEFF5),
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer.withValues(
          alpha: isDark ? 0.7 : 1,
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.65,
      ),
      searchBarTheme: SearchBarThemeData(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        backgroundColor: WidgetStatePropertyAll(
          isDark
              ? const Color(0xCC141820)
              : Colors.white.withValues(alpha: 0.9),
        ),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(
          TextStyle(color: scheme.onSurface, fontSize: 16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1D212A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? const Color(0xFF151821)
            : Colors.white.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? const Color(0xFF151821)
            : Colors.white.withValues(alpha: 0.97),
        showDragHandle: true,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
