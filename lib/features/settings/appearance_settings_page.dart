import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens/app_colors.dart';
import '../../design/tokens/app_spacing.dart';
import 'appearance_settings_controller.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final appearance = ref.watch(appearanceProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: colors.background,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.background,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: colors.border,
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('How To Hockey')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Train with purpose.', style: textTheme.headlineLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Build your game with focused, measurable training.', style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary)),
                    const SizedBox(height: AppSpacing.xxl),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.card),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Appearance', style: textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Choose how How To Hockey looks on this device.', style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                            const SizedBox(height: AppSpacing.md),
                            SegmentedButton<AppAppearance>(
                              segments: AppAppearance.values.map((appearance) => ButtonSegment(value: appearance, label: Text(appearance.label))).toList(growable: false),
                              selected: {appearance},
                              showSelectedIcon: false,
                              onSelectionChanged: (selection) {
                                unawaited(ref.read(appearanceProvider.notifier).setAppearance(selection.single));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('Train. Track. Improve.', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Your next shift starts here.', style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
