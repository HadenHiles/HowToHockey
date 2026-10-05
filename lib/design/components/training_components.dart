import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_shapes.dart';
import '../tokens/app_spacing.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'How To Hockey',
    image: true,
    child: ExcludeSemantics(
      child: Image.asset(
        'assets/brand/HTH_TEXT_ONLY.png',
        width: 180,
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).extension<AppColors>()!.brandCream
            : Theme.of(context).extension<AppColors>()!.textPrimary,
        colorBlendMode: BlendMode.srcIn,
      ),
    ),
  );
}

class TrainingCard extends StatelessWidget {
  const TrainingCard({required this.child, super.key, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: child,
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.title,
    super.key,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.sm,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (action != null)
        TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.value,
    required this.label,
    super.key,
    this.detail,
  });

  final String value;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return TrainingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: theme.textTheme.labelLarge),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PillarTag extends StatelessWidget {
  const PillarTag({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    ),
  );
}

/// Deliberately illustrated so sample media cannot be mistaken for a drill demo.
class DrillMediaPlaceholder extends StatelessWidget {
  const DrillMediaPlaceholder({
    required this.title,
    super.key,
    this.compact = false,
  });

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      label: 'Illustrated placeholder for $title. No video is available.',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: AspectRatio(
          aspectRatio: compact ? 2.8 : 16 / 9,
          child: CustomPaint(
            painter: _RinkPainter(colors),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_hockey_outlined, size: 40, color: colors.textPrimary),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'DEMO MEDIA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RinkPainter extends CustomPainter {
  const _RinkPainter(this.colors);

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.surface);
    final lines = Paint()
      ..color = colors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.width * .08, size.height * .13, size.width * 1.16, size.height * .74),
        Radius.circular(size.height * .32),
      ),
      lines,
    );
    for (final x in [size.width * .18, size.width * .82]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lines);
      canvas.drawCircle(Offset(x, size.height / 2), size.height * .18, lines);
    }
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()..color = colors.brandPrimary.withValues(alpha: .18)..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * .32,
      lines,
    );
  }

  @override
  bool shouldRepaint(_RinkPainter oldDelegate) => colors != oldDelegate.colors;
}

class TrainingProgressRing extends StatelessWidget {
  const TrainingProgressRing({
    required this.progress,
    required this.value,
    required this.label,
    super.key,
  });

  final double progress;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Semantics(
      label: '$value $label',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 160 + 80 * (MediaQuery.textScalerOf(context).scale(1).clamp(1, 2) - 1),
          child: CustomPaint(
            painter: _ProgressPainter(progress, colors),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.4,
                      child: Text(value, style: theme.textTheme.headlineLarge),
                    ),
                    Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
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

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter(this.progress, this.colors);

  final double progress;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(6);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, paint..color = colors.border);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, paint..color = colors.brandPrimary);
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      progress != oldDelegate.progress || colors != oldDelegate.colors;
}
