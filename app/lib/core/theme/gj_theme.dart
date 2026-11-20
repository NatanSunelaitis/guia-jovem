import 'package:flutter/material.dart';

import 'gj_colors.dart';
import 'gj_transicoes.dart';
import 'gj_typography.dart';

/// ThemeData do Guia Jovem, construído a partir dos tokens do GJDS
/// (seção 7.2 do design system: mapeamento para ColorScheme Material 3).
abstract final class GJTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: GJColors.primary,
      onPrimary: GJColors.primaryOn,
      primaryContainer: GJColors.primaryContainer,
      onPrimaryContainer: GJColors.primaryOn,
      secondary: GJColors.secondary,
      onSecondary: GJColors.primaryOn,
      secondaryContainer: GJColors.secondaryFixed,
      onSecondaryContainer: Color(0xFF003567),
      tertiary: GJColors.tertiary,
      onTertiary: GJColors.primaryOn,
      tertiaryContainer: GJColors.tertiaryFixed,
      onTertiaryContainer: Color(0xFF5D0008),
      error: GJColors.error,
      onError: GJColors.primaryOn,
      errorContainer: GJColors.errorContainer,
      onErrorContainer: GJColors.errorOnContainer,
      background: GJColors.background,
      onBackground: GJColors.textPrimary,
      surface: GJColors.surfaceLowest,
      onSurface: GJColors.textPrimary,
      onSurfaceVariant: GJColors.textSecondary,
      outline: GJColors.textDisabled,
      outlineVariant: GJColors.border,
      inverseSurface: GJColors.inverseSurface,
      onInverseSurface: GJColors.inverseOn,
      inversePrimary: GJColors.primaryFixedDim,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: GJColors.background,
      fontFamily: GJTypography.body().fontFamily,
      textTheme: TextTheme(
        displayLarge: GJTypography.display(),
        headlineLarge: GJTypography.h1(),
        headlineMedium: GJTypography.h2(),
        headlineSmall: GJTypography.h3(),
        titleLarge: GJTypography.h4(),
        bodyLarge: GJTypography.bodyLg(),
        bodyMedium: GJTypography.body(),
        bodySmall: GJTypography.bodySm(),
        labelLarge: GJTypography.label(),
        labelSmall: GJTypography.caption(),
      ),
      dividerColor: GJColors.surfaceDim,
      pageTransitionsTheme: gjPageTransitionsTheme,
    );
  }
}
