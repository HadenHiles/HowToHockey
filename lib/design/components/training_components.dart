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
      child: Image.asset('assets/brand/HTH_TEXT_ONLY.png', width: 180, color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).extension<AppColors>()!.brandCream : Theme.of(context).extension<AppColors>()!.textPrimary, colorBlendMode: BlendMode.srcIn),
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
      child: Padding(padding: const EdgeInsets.all(AppSpacing.card), child: child),
    ),
  );
}

class TrainingHeroCard extends StatelessWidget {
  const TrainingHeroCard({required this.eyebrow, required this.title, required this.detail, required this.actionLabel, required this.onTap, super.key, this.metrics = const []});

  final String eyebrow;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onTap;
  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final pillars = theme.extension<PillarColors>()!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: CustomPaint(
        painter: _ArenaPainter(colors: AppColors.dark, blue: pillars.hands),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: colors.brandPrimaryOnDark, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(eyebrow.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: colors.brandCream, letterSpacing: 1.2)),
                  ),
                  Icon(Icons.sports_hockey, color: colors.brandCream.withValues(alpha: .72)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.displaySmall?.copyWith(color: colors.brandCream, fontWeight: FontWeight.w800, height: 1.02),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(detail, style: theme.textTheme.bodyMedium?.copyWith(color: colors.brandCream.withValues(alpha: .75))),
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.md,
                  children: [for (var index = 0; index < metrics.length; index++) _HeroMetric(value: metrics[index].$1, label: metrics[index].$2, color: index.isEven ? colors.brandCream : pillars.hands)],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  actionLabel,
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, letterSpacing: .6, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: colors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
      Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.dark.textSecondary, letterSpacing: .8)),
    ],
  );
}

class _ArenaPainter extends CustomPainter {
  const _ArenaPainter({required this.colors, required this.blue});

  final AppColors colors;
  final Color blue;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors.elevatedSurface, colors.background]).createShader(Offset.zero & size));

    final line = Paint()
      ..color = colors.brandCream.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rinkRect = Rect.fromLTWH(size.width * .45, size.height * .12, size.width * .82, size.height * .76);
    canvas.drawRRect(RRect.fromRectAndRadius(rinkRect, Radius.circular(size.height * .28)), line);
    canvas.drawLine(
      Offset(size.width * .67, rinkRect.top),
      Offset(size.width * .67, rinkRect.bottom),
      Paint()
        ..color = colors.brandPrimary.withValues(alpha: .6)
        ..strokeWidth = 2.2,
    );
    canvas.drawLine(
      Offset(size.width * .83, rinkRect.top),
      Offset(size.width * .83, rinkRect.bottom),
      Paint()
        ..color = blue.withValues(alpha: .48)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(size.width * .83, size.height * .5), size.height * .16, line);
    canvas.drawCircle(Offset(size.width * .83, size.height * .5), size.height * .045, Paint()..color = colors.brandPrimaryOnDark.withValues(alpha: .85));
  }

  @override
  bool shouldRepaint(_ArenaPainter oldDelegate) => colors != oldDelegate.colors || blue != oldDelegate.blue;
}

class ArenaPanel extends StatelessWidget {
  const ArenaPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = AppColors.dark.brandCream;
    final darkTextTheme = theme.textTheme.apply(bodyColor: foreground, displayColor: foreground);
    return Theme(
      data: theme.copyWith(
        textTheme: darkTextTheme,
        colorScheme: theme.colorScheme.copyWith(onSurface: foreground, onSurfaceVariant: AppColors.dark.textSecondary),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.dark.background, borderRadius: BorderRadius.circular(AppRadii.card)),
        child: Padding(padding: const EdgeInsets.all(AppSpacing.card), child: child),
      ),
    );
  }
}

class WeeklyTrainingChart extends StatelessWidget {
  const WeeklyTrainingChart({super.key});

  static const _values = [0.42, 0.72, 0.54, 0.9, 0.62, 0.3, 0.76];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Weekly training chart. Monday 42 percent, Tuesday 72 percent, Wednesday 54 percent, Thursday 90 percent, Friday 62 percent, Saturday 30 percent, Sunday 76 percent.',
    child: ExcludeSemantics(
      child: SizedBox(
        height: 98,
        child: CustomPaint(
          painter: _WeeklyTrainingPainter(values: _values, days: _days, active: Theme.of(context).extension<PillarColors>()!.hands, inactive: AppColors.dark.textSecondary, labelStyle: Theme.of(context).textTheme.labelSmall!),
        ),
      ),
    ),
  );
}

class _WeeklyTrainingPainter extends CustomPainter {
  const _WeeklyTrainingPainter({required this.values, required this.days, required this.active, required this.inactive, required this.labelStyle});

  final List<double> values;
  final List<String> days;
  final Color active;
  final Color inactive;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 20.0;
    const gap = 10.0;
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;
    final chartHeight = size.height - labelHeight;
    for (var index = 0; index < values.length; index++) {
      final left = index * (barWidth + gap);
      final barHeight = chartHeight * values[index];
      final rect = Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), Paint()..color = index == values.length - 1 ? active : inactive.withValues(alpha: .3));
      final text = TextPainter(
        text: TextSpan(
          text: days[index],
          style: labelStyle.copyWith(color: index == values.length - 1 ? active : inactive),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(left + (barWidth - text.width) / 2, chartHeight + 5));
    }
  }

  @override
  bool shouldRepaint(_WeeklyTrainingPainter oldDelegate) => values != oldDelegate.values || days != oldDelegate.days || active != oldDelegate.active || inactive != oldDelegate.inactive || labelStyle != oldDelegate.labelStyle;
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({required this.title, super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.sm,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        ],
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({required this.value, required this.label, super.key, this.detail, this.accent});

  final String value;
  final String label;
  final String? detail;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return TrainingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(color: accent ?? colors.brandPrimary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: theme.textTheme.displaySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: colors.textSecondary)),
          if (detail != null) ...[const SizedBox(height: AppSpacing.xs), Text(detail!, style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary))],
        ],
      ),
    );
  }
}

class SkillRadar extends StatelessWidget {
  const SkillRadar({required this.scores, super.key});

  final List<int> scores;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillars = theme.extension<PillarColors>()!;
    final colors = theme.extension<AppColors>()!;
    const labels = ['ACCURACY', 'HANDS', 'POWER', 'PASS', 'SPEED', 'ENDURANCE'];
    final pillarColors = [pillars.shotAccuracy, pillars.hands, pillars.shotPower, pillars.passing, pillars.speedStrength, pillars.endurance];

    return Semantics(
      label: 'Skill profile: ${List.generate(scores.length, (index) => '${labels[index]} ${scores[index]}').join(', ')}',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 264,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, 264);
              return CustomPaint(
                size: size,
                painter: _SkillRadarPainter(scores, pillarColors, colors),
                child: Stack(
                  children: [
                    for (var index = 0; index < labels.length; index++)
                      _RadarLabel(
                        label: labels[index],
                        score: scores[index],
                        color: pillarColors[index],
                        alignment: switch (index) {
                          0 => Alignment.topCenter,
                          1 => Alignment.centerRight,
                          2 => Alignment.bottomRight,
                          3 => Alignment.bottomCenter,
                          4 => Alignment.bottomLeft,
                          _ => Alignment.centerLeft,
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RadarLabel extends StatelessWidget {
  const _RadarLabel({required this.label, required this.score, required this.color, required this.alignment});

  final String label;
  final int score;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$score',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _SkillRadarPainter extends CustomPainter {
  const _SkillRadarPainter(this.scores, this.pillarColors, this.colors);

  final List<int> scores;
  final List<Color> pillarColors;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width * .29, size.height * .31);
    final points = List<Offset>.generate(scores.length, (index) {
      final angle = -math.pi / 2 + index * math.pi * 2 / scores.length;
      return Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
    });

    final grid = Paint()
      ..color = colors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final scale in [.33, .66, 1.0]) {
      final ring = Path();
      for (var index = 0; index < points.length; index++) {
        final point = Offset(center.dx + (points[index].dx - center.dx) * scale, center.dy + (points[index].dy - center.dy) * scale);
        if (index == 0) {
          ring.moveTo(point.dx, point.dy);
        } else {
          ring.lineTo(point.dx, point.dy);
        }
      }
      ring.close();
      canvas.drawPath(ring, grid);
    }

    for (final point in points) {
      canvas.drawLine(center, point, grid);
    }

    final profile = Path();
    final profilePoints = List<Offset>.generate(scores.length, (index) {
      final angle = -math.pi / 2 + index * math.pi * 2 / scores.length;
      final distance = radius * scores[index].clamp(0, 100) / 100;
      return Offset(center.dx + math.cos(angle) * distance, center.dy + math.sin(angle) * distance);
    });
    for (var index = 0; index < profilePoints.length; index++) {
      final point = profilePoints[index];
      if (index == 0) {
        profile.moveTo(point.dx, point.dy);
      } else {
        profile.lineTo(point.dx, point.dy);
      }
    }
    profile.close();
    canvas.drawPath(
      profile,
      Paint()
        ..color = colors.brandPrimary.withValues(alpha: .2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      profile,
      Paint()
        ..color = colors.brandPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (var index = 0; index < profilePoints.length; index++) {
      canvas.drawCircle(profilePoints[index], 4, Paint()..color = pillarColors[index]);
    }
  }

  @override
  bool shouldRepaint(_SkillRadarPainter oldDelegate) => scores != oldDelegate.scores || pillarColors != oldDelegate.pillarColors || colors != oldDelegate.colors;
}

class PillarTag extends StatelessWidget {
  const PillarTag({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadii.control)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
    ),
  );
}

/// Deliberately illustrated so sample media cannot be mistaken for a drill demo.
class DrillMediaPlaceholder extends StatelessWidget {
  const DrillMediaPlaceholder({required this.title, super.key, this.compact = false});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final pillars = Theme.of(context).extension<PillarColors>()!;
    return Semantics(
      label: 'Illustrated placeholder for $title. No video is available.',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: AspectRatio(
          aspectRatio: compact ? 2.8 : 16 / 9,
          child: CustomPaint(
            painter: _RinkPainter(colors, pillars.hands),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_hockey_outlined, size: 40, color: colors.brandCream),
                  const SizedBox(height: AppSpacing.xs),
                  Text('DEMO MEDIA', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.dark.textSecondary)),
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
  const _RinkPainter(this.colors, this.blue);

  final AppColors colors;
  final Color blue;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.dark.background);
    final lines = Paint()
      ..color = AppColors.dark.textSecondary.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-size.width * .08, size.height * .13, size.width * 1.16, size.height * .74), Radius.circular(size.height * .32)), lines);
    for (final x in [size.width * .18, size.width * .82]) {
      canvas.drawCircle(Offset(x, size.height / 2), size.height * .18, lines);
    }
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = colors.brandPrimary.withValues(alpha: .68)
        ..strokeWidth = 2,
    );
    for (final x in [size.width * .33, size.width * .67]) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = blue.withValues(alpha: .52)
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.height * .32, lines);
  }

  @override
  bool shouldRepaint(_RinkPainter oldDelegate) => colors != oldDelegate.colors || blue != oldDelegate.blue;
}

class TrainingProgressRing extends StatelessWidget {
  const TrainingProgressRing({required this.progress, required this.value, required this.label, super.key});

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
                    MediaQuery.withClampedTextScaling(maxScaleFactor: 1.4, child: Text(value, style: theme.textTheme.headlineLarge)),
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
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, paint..color = colors.border);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, paint..color = colors.brandPrimary);
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) => progress != oldDelegate.progress || colors != oldDelegate.colors;
}
