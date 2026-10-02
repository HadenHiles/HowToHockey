import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shapes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

abstract final class HockeyTheme {
  static final ThemeData light = _buildTheme(
    brightness: Brightness.light,
    colors: AppColors.light,
    pillars: PillarColors.light,
  );

  static final ThemeData dark = _buildTheme(
    brightness: Brightness.dark,
    colors: AppColors.dark,
    pillars: PillarColors.dark,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppColors colors,
    required PillarColors pillars,
  }) {
    final dark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.brandPrimary,
      onPrimary: Colors.white,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.textSecondary,
      onSecondary: colors.elevatedSurface,
      secondaryContainer: colors.surface,
      onSecondaryContainer: colors.textPrimary,
      tertiary: pillars.stickhandling,
      onTertiary: Colors.white,
      tertiaryContainer: colors.surface,
      onTertiaryContainer: colors.textPrimary,
      error: colors.error,
      onError: Colors.white,
      errorContainer: dark ? const Color(0xFF601410) : const Color(0xFFF9DEDC),
      onErrorContainer: dark ? const Color(0xFFFFDAD6) : const Color(0xFF410E0B),
      surface: colors.elevatedSurface,
      onSurface: colors.textPrimary,
      surfaceDim: colors.background,
      surfaceBright: colors.elevatedSurface,
      surfaceContainerLowest: colors.background,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.elevatedSurface,
      surfaceContainerHighest: dark
          ? const Color(0xFF2B2B30)
          : const Color(0xFFEDEDF0),
      onSurfaceVariant: colors.textSecondary,
      outline: colors.textSecondary,
      outlineVariant: colors.border,
      shadow: Colors.black,
      scrim: const Color(0x66000000),
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.background,
      inversePrimary: colors.brandPrimaryOnDark,
      surfaceTint: colors.brandPrimary,
    );

    final textTheme = AppTypography.textTheme(colors.textPrimary).apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        pillars,
        const MotionTokens(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.elevatedSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: colors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          side: BorderSide(color: colors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: colors.brandPrimary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
        ),
      ),
    );
  }
}
