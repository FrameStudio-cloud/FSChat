import 'package:flutter/material.dart';
import 'app_colors.dart';

class BubbleStyle extends ThemeExtension<BubbleStyle> {
  final BorderRadiusGeometry ownRadius;
  final BorderRadiusGeometry otherRadius;
  final BoxShadow ownShadow;
  final BoxShadow otherShadow;

  const BubbleStyle({
    required this.ownRadius,
    required this.otherRadius,
    required this.ownShadow,
    required this.otherShadow,
  });

  @override
  ThemeExtension<BubbleStyle> copyWith({
    BorderRadiusGeometry? ownRadius,
    BorderRadiusGeometry? otherRadius,
    BoxShadow? ownShadow,
    BoxShadow? otherShadow,
  }) {
    return BubbleStyle(
      ownRadius: ownRadius ?? this.ownRadius,
      otherRadius: otherRadius ?? this.otherRadius,
      ownShadow: ownShadow ?? this.ownShadow,
      otherShadow: otherShadow ?? this.otherShadow,
    );
  }

  @override
  ThemeExtension<BubbleStyle> lerp(
      covariant ThemeExtension<BubbleStyle>? other, double t) {
    if (other is! BubbleStyle) return this;
    return BubbleStyle(
      ownRadius: BorderRadiusGeometry.lerp(ownRadius, other.ownRadius, t)!,
      otherRadius:
          BorderRadiusGeometry.lerp(otherRadius, other.otherRadius, t)!,
      ownShadow: BoxShadow.lerp(ownShadow, other.ownShadow, t) ?? ownShadow,
      otherShadow:
          BoxShadow.lerp(otherShadow, other.otherShadow, t) ?? otherShadow,
    );
  }
}

class AppTheme {
  static ThemeData light = ThemeData(
    colorSchemeSeed: AppColors.brand,
    brightness: Brightness.light,
    useMaterial3: true,
    extensions: [
      const BubbleStyle(
        ownRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(6),
        ),
        otherRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(18),
        ),
        ownShadow: BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        otherShadow: BoxShadow(
          color: Color(0x08000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ),
    ],
  );

  static ThemeData dark = ThemeData(
    colorSchemeSeed: AppColors.brand,
    brightness: Brightness.dark,
    useMaterial3: true,
    extensions: [
      const BubbleStyle(
        ownRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(6),
        ),
        otherRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(18),
        ),
        ownShadow: BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        otherShadow: BoxShadow(
          color: Color(0x15000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ),
    ],
  );
}
