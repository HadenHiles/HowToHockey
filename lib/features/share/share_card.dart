import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/tokens/app_colors.dart';

/// The two shapes a card is made in: a phone story, and a square for feeds and group chats.
enum ShareFormat {
  story(label: 'Story', width: 360, height: 640),
  square(label: 'Square', width: 360, height: 360);

  const ShareFormat({required this.label, required this.width, required this.height});

  final String label;

  /// Laid out at this size, then rendered at 1080 pixels wide (three times over), so story is 1080×1920 and square 1080×1080.
  final double width;
  final double height;

  static const outputWidth = 1080.0;

  double get pixelRatio => outputWidth / width;
}

/// What goes on a card. Only numbers and badges: no name, no photo, nothing that identifies a player.
class ShareCardData {
  const ShareCardData({required this.eyebrow, required this.heroValue, required this.heroLabel, required this.stats, required this.dateLabel, this.badges = const [], this.streakDays = 0});

  final String eyebrow;
  final String heroValue;
  final String heroLabel;
  final List<({String value, String label})> stats;
  final List<String> badges;
  final int streakDays;
  final String dateLabel;

  String get semanticLabel => [
    'How To Hockey. $eyebrow, $dateLabel.',
    '$heroValue $heroLabel.',
    for (final stat in stats) '${stat.value} ${stat.label}.',
    if (streakDays > 0) '$streakDays day streak.',
    for (final badge in badges) 'Personal best: $badge.',
  ].join(' ');
}

/// A branded card, drawn in the app's dark look whatever the phone's theme is, at a fixed size and text size
/// so the picture that gets shared always looks the same.
class ShareCard extends StatelessWidget {
  const ShareCard({required this.data, required this.format, super.key});

  final ShareCardData data;
  final ShareFormat format;

  static const _ink = Color(0xFF0E0E10);

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
    final story = format == ShareFormat.story;
    final base = Theme.of(context).textTheme;
    final cream = colors.brandCream;
    TextStyle style(TextStyle? from, {Color? color, double? size, FontWeight? weight, double? spacing}) =>
        (from ?? const TextStyle()).copyWith(color: color ?? cream, fontSize: size, fontWeight: weight, letterSpacing: spacing);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Semantics(
        label: data.semanticLabel,
        child: ExcludeSemantics(
          child: SizedBox(
            width: format.width,
            height: format.height,
            child: ClipRect(
              child: CustomPaint(
                painter: _RinkPainter(line: colors.brandPrimaryOnDark.withValues(alpha: .22), dot: colors.brandPrimaryOnDark.withValues(alpha: .9)),
                child: ColoredBox(
                  color: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(28, story ? 56 : 24, 28, story ? 48 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/brand/HTH_TEXT_ONLY.png', width: story ? 150 : 120, color: cream, colorBlendMode: BlendMode.srcIn),
                        SizedBox(height: story ? 28 : 12),
                        Text(
                          data.eyebrow.toUpperCase(),
                          style: style(base.labelMedium, color: colors.brandPrimaryOnDark, size: 12, weight: FontWeight.w700, spacing: 1.4),
                        ),
                        const SizedBox(height: 2),
                        Text(data.dateLabel, style: style(base.bodySmall, color: colors.textSecondary, size: 12)),
                        if (story) const Spacer(flex: 2) else const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            data.heroValue,
                            style: style(base.displayLarge, size: story ? 96 : 64, weight: FontWeight.w800, spacing: -3),
                          ),
                        ),
                        Text(
                          data.heroLabel.toUpperCase(),
                          style: style(base.labelLarge, color: colors.textSecondary, size: 13, weight: FontWeight.w600, spacing: 1.2),
                        ),
                        if (story) const Spacer() else const SizedBox(height: 14),
                        Row(
                          children: [
                            for (final (index, stat) in data.stats.take(3).indexed) ...[
                              if (index > 0) const SizedBox(width: 28),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        stat.value,
                                        style: style(base.headlineMedium, size: story ? 28 : 22, weight: FontWeight.w700),
                                      ),
                                    ),
                                    Text(stat.label, style: style(base.bodySmall, color: colors.textSecondary, size: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (data.streakDays > 0) ...[
                          SizedBox(height: story ? 20 : 10),
                          Row(
                            children: [
                              Icon(Icons.local_fire_department, color: colors.brandPrimaryOnDark, size: 20),
                              const SizedBox(width: 6),
                              Text('${data.streakDays}-day streak', style: style(base.titleSmall, size: 15, weight: FontWeight.w700)),
                            ],
                          ),
                        ],
                        if (data.badges.isNotEmpty) ...[
                          SizedBox(height: story ? 18 : 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final badge in data.badges.take(story ? 3 : 2))
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.brandPrimaryOnDark.withValues(alpha: .16),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: colors.brandPrimaryOnDark.withValues(alpha: .6)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.emoji_events, color: colors.brandPrimaryOnDark, size: 14),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            badge,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: style(base.labelMedium, size: 12, weight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (story) ...[const SizedBox(height: 28), Text('Off-ice training that gets you better.', style: style(base.bodySmall, color: colors.textSecondary, size: 11))],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Faint rink markings behind the card: a centre line, the circle and a puck dot.
class _RinkPainter extends CustomPainter {
  const _RinkPainter({required this.line, required this.dot});

  final Color line;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ShareCard._ink);
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final centre = Offset(size.width * .78, size.height * .42);
    canvas.drawCircle(centre, math.min(size.width, size.height) * .26, stroke);
    canvas.drawLine(Offset(centre.dx, 0), Offset(centre.dx, size.height), stroke);
    canvas.drawCircle(centre, 7, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_RinkPainter oldDelegate) => oldDelegate.line != line || oldDelegate.dot != dot;
}
