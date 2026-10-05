import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static TextTheme textTheme(Color color) {
    return TextTheme(
      displayLarge: _style(size: 64, weight: 800, color: color, letterSpacing: -2.2, height: 1),
      displayMedium: _style(size: 48, weight: 800, color: color, letterSpacing: -1.6, height: 1.05),
      displaySmall: _style(size: 36, weight: 700, color: color, letterSpacing: -1, height: 1.1),
      headlineLarge: _style(size: 32, weight: 700, color: color, letterSpacing: -0.8, height: 1.15),
      headlineMedium: _style(size: 28, weight: 700, color: color, letterSpacing: -0.5, height: 1.2),
      headlineSmall: _style(size: 24, weight: 600, color: color, letterSpacing: -0.3, height: 1.25),
      titleLarge: _style(size: 20, weight: 600, color: color, height: 1.3),
      titleMedium: _style(size: 16, weight: 600, color: color, height: 1.4),
      titleSmall: _style(size: 14, weight: 600, color: color, height: 1.4),
      bodyLarge: _style(size: 16, weight: 400, color: color, height: 1.5),
      bodyMedium: _style(size: 14, weight: 400, color: color, height: 1.45),
      bodySmall: _style(size: 12, weight: 400, color: color, height: 1.4),
      labelLarge: _style(size: 14, weight: 600, color: color, height: 1.35),
      labelMedium: _style(size: 12, weight: 500, color: color, height: 1.35),
      labelSmall: _style(size: 11, weight: 500, color: color, letterSpacing: 0.2, height: 1.3),
    );
  }

  static TextStyle _style({required double size, required int weight, required Color color, double? letterSpacing, double? height}) {
    return TextStyle(fontFamily: fontFamily, fontSize: size, fontWeight: FontWeight.values[weight ~/ 100 - 1], fontFeatures: const [FontFeature.tabularFigures()], fontVariations: [FontVariation('wght', weight.toDouble()), FontVariation.opticalSize(size.clamp(14, 32).toDouble())], color: color, letterSpacing: letterSpacing, height: height);
  }
}
