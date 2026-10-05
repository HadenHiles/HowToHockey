import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/design/theme/app_theme.dart';
import 'package:how_to_hockey/design/tokens/app_colors.dart';
import 'package:how_to_hockey/design/tokens/app_motion.dart';

void main() {
  test('brand colors and theme extensions are defined for both themes', () {
    expect(HockeyTheme.light.colorScheme.primary, const Color(0xFFCC3333));
    expect(HockeyTheme.dark.colorScheme.primary, const Color(0xFFCC3333));
    expect(HockeyTheme.dark.scaffoldBackgroundColor, const Color(0xFF0E0E10));
    expect(HockeyTheme.light.scaffoldBackgroundColor, const Color(0xFFF1F4F8));
    expect(HockeyTheme.light.navigationBarTheme.backgroundColor, const Color(0xFF0E0E10));
    expect(HockeyTheme.light.navigationBarTheme.indicatorColor, const Color(0xFFCC3333));

    expect(HockeyTheme.light.extension<AppColors>()!.textPrimary, const Color(0xFF111114));
    expect(HockeyTheme.dark.extension<AppColors>()!.textPrimary, const Color(0xFFF5F5F7));
    expect(HockeyTheme.dark.extension<PillarColors>()!.endurance, const Color(0xFFBA9BE4));
    expect(HockeyTheme.light.extension<MotionTokens>()!.micro.inMilliseconds, 150);
    expect(HockeyTheme.light.textTheme.bodyLarge!.fontFamily, 'Inter');
  });
}
