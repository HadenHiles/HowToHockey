import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brandPrimary,
    required this.brandPrimaryOnDark,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.brandCream,
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.border,
  });

  final Color brandPrimary;
  final Color brandPrimaryOnDark;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color brandCream;
  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color border;

  static const light = AppColors(
    brandPrimary: Color(0xFFCC3333),
    brandPrimaryOnDark: Color(0xFFE05555),
    primaryContainer: Color(0xFFFAE6E6),
    onPrimaryContainer: Color(0xFF5C1717),
    brandCream: Color(0xFFF7F4E7),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F7),
    elevatedSurface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111114),
    textSecondary: Color(0xFF6B6B73),
    success: Color(0xFF1E9E5A),
    warning: Color(0xFFD98E04),
    error: Color(0xFFB3261E),
    border: Color(0xFFE5E5EA),
  );

  static const dark = AppColors(
    brandPrimary: Color(0xFFCC3333),
    brandPrimaryOnDark: Color(0xFFE05555),
    primaryContainer: Color(0xFF3A1616),
    onPrimaryContainer: Color(0xFFFFDAD6),
    brandCream: Color(0xFFF7F4E7),
    background: Color(0xFF0E0E10),
    surface: Color(0xFF1A1A1D),
    elevatedSurface: Color(0xFF232327),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF9A9AA3),
    success: Color(0xFF3CCB7F),
    warning: Color(0xFFF2B233),
    error: Color(0xFFFF6B6B),
    border: Color(0xFF39393F),
  );

  @override
  AppColors copyWith({
    Color? brandPrimary,
    Color? brandPrimaryOnDark,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? brandCream,
    Color? background,
    Color? surface,
    Color? elevatedSurface,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? border,
  }) {
    return AppColors(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandPrimaryOnDark: brandPrimaryOnDark ?? this.brandPrimaryOnDark,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      brandCream: brandCream ?? this.brandCream,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      border: border ?? this.border,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;

    return AppColors(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandPrimaryOnDark:
          Color.lerp(brandPrimaryOnDark, other.brandPrimaryOnDark, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      brandCream: Color.lerp(brandCream, other.brandCream, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

@immutable
class PillarColors extends ThemeExtension<PillarColors> {
  const PillarColors({
    required this.shooting,
    required this.stickhandling,
    required this.skating,
    required this.passing,
    required this.iqConditioning,
  });

  final Color shooting;
  final Color stickhandling;
  final Color skating;
  final Color passing;
  final Color iqConditioning;

  static const light = PillarColors(
    shooting: Color(0xFFCC3333),
    stickhandling: Color(0xFF2878B8),
    skating: Color(0xFF148A83),
    passing: Color(0xFFA66A00),
    iqConditioning: Color(0xFF7856A5),
  );

  static const dark = PillarColors(
    shooting: Color(0xFFE05555),
    stickhandling: Color(0xFF6CB8F0),
    skating: Color(0xFF5ACFC4),
    passing: Color(0xFFF2B233),
    iqConditioning: Color(0xFFBA9BE4),
  );

  @override
  PillarColors copyWith({
    Color? shooting,
    Color? stickhandling,
    Color? skating,
    Color? passing,
    Color? iqConditioning,
  }) {
    return PillarColors(
      shooting: shooting ?? this.shooting,
      stickhandling: stickhandling ?? this.stickhandling,
      skating: skating ?? this.skating,
      passing: passing ?? this.passing,
      iqConditioning: iqConditioning ?? this.iqConditioning,
    );
  }

  @override
  PillarColors lerp(ThemeExtension<PillarColors>? other, double t) {
    if (other is! PillarColors) return this;

    return PillarColors(
      shooting: Color.lerp(shooting, other.shooting, t)!,
      stickhandling: Color.lerp(stickhandling, other.stickhandling, t)!,
      skating: Color.lerp(skating, other.skating, t)!,
      passing: Color.lerp(passing, other.passing, t)!,
      iqConditioning: Color.lerp(iqConditioning, other.iqConditioning, t)!,
    );
  }
}
