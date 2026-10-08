import 'package:flutter/material.dart';

@immutable
class MotionTokens extends ThemeExtension<MotionTokens> {
  const MotionTokens({
    this.micro = const Duration(milliseconds: 150),
    this.standard = const Duration(milliseconds: 275),
    this.large = const Duration(milliseconds: 400),
    this.emphasized = Curves.easeInOutCubicEmphasized,
  });

  final Duration micro;
  final Duration standard;
  final Duration large;
  final Curve emphasized;

  @override
  MotionTokens copyWith({Duration? micro, Duration? standard, Duration? large, Curve? emphasized}) {
    return MotionTokens(micro: micro ?? this.micro, standard: standard ?? this.standard, large: large ?? this.large, emphasized: emphasized ?? this.emphasized);
  }

  @override
  MotionTokens lerp(ThemeExtension<MotionTokens>? other, double t) {
    if (other is! MotionTokens) return this;

    return MotionTokens(
      micro: Duration(milliseconds: (micro.inMilliseconds + (other.micro.inMilliseconds - micro.inMilliseconds) * t).round()),
      standard: Duration(milliseconds: (standard.inMilliseconds + (other.standard.inMilliseconds - standard.inMilliseconds) * t).round()),
      large: Duration(milliseconds: (large.inMilliseconds + (other.large.inMilliseconds - large.inMilliseconds) * t).round()),
      emphasized: t < 0.5 ? emphasized : other.emphasized,
    );
  }
}
