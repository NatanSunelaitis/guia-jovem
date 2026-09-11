import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'gj_colors.dart';

/// Escala tipográfica do GJDS, seção 2.2.
/// Plus Jakarta Sans para títulos, Inter para corpo e labels.
abstract final class GJTypography {
  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color color = GJColors.textPrimary,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    double? height,
    Color color = GJColors.textPrimary,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      );

  static TextStyle display({double size = 48}) =>
      _jakarta(size: size, weight: FontWeight.w800, height: 1.1, letterSpacing: -0.02 * size);

  static TextStyle h1({double size = 36}) =>
      _jakarta(size: size, weight: FontWeight.w800, height: 1.15);

  static TextStyle h2({double size = 28}) =>
      _jakarta(size: size, weight: FontWeight.w700, height: 1.2);

  static TextStyle h3({double size = 22}) =>
      _jakarta(size: size, weight: FontWeight.w700, height: 1.3);

  static TextStyle h4() => _jakarta(size: 18, weight: FontWeight.w700, height: 1.35);

  static TextStyle eyebrow({Color color = GJColors.primary}) => _jakarta(
        size: 14,
        weight: FontWeight.w800,
        letterSpacing: 0.12 * 14,
        color: color,
      );

  static TextStyle bodyLg() =>
      _inter(size: 18, weight: FontWeight.w400, height: 1.6);

  static TextStyle body() => _inter(size: 16, weight: FontWeight.w400, height: 1.6);

  static TextStyle bodySm({Color color = GJColors.textSecondary}) =>
      _inter(size: 14, weight: FontWeight.w400, height: 1.5, color: color);

  static TextStyle label({Color color = GJColors.textSecondary}) =>
      _inter(size: 14, weight: FontWeight.w600, height: 1.4, color: color);

  static TextStyle caption({Color color = GJColors.textSecondary}) =>
      _inter(size: 12, weight: FontWeight.w500, height: 1.4, color: color);

  static TextStyle logo() =>
      _jakarta(size: 24, weight: FontWeight.w800, letterSpacing: -0.03 * 24);
}
