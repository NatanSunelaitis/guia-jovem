import 'package:flutter/material.dart';

/// Tokens de cor do Guia Jovem Design System (GJDS v1.2), seção 2.1.
/// Nenhuma outra cor deve ser usada fora deste arquivo.
abstract final class GJColors {
  // Marca e ação
  static const primary = Color(0xFF0061A4);
  static const primaryContainer = Color(0xFF2196F3);
  static const primaryOn = Color(0xFFFFFFFF);
  static const primaryContainerOn = Color(0xFF002C4F);
  static const primaryFixed = Color(0xFFD1E4FF);
  static const primaryFixedDim = Color(0xFF9ECAFF);
  static const primaryDark = Color(0xFF00497D);

  // Secundária (Bolsas)
  static const secondary = Color(0xFF005FAF);
  static const secondaryContainer = Color(0xFF54A0FE);
  static const secondaryFixed = Color(0xFFD4E3FF);

  // Terciária (Financiamento e perigo)
  static const tertiary = Color(0xFFB3272A);
  static const tertiaryContainer = Color(0xFFFA5B57);
  static const tertiaryFixed = Color(0xFFFFDAD7);
  /// Hover/pressed de botões na categoria Financiamento, simétrico ao `primaryDark` (v1.2).
  static const tertiaryDark = Color(0xFF8C1D20);

  // Semânticas
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const errorOnContainer = Color(0xFF93000A);
  static const success = Color(0xFF1B7F3B);
  static const successContainer = Color(0xFFD8F3DC);
  static const warning = Color(0xFFB26A00);
  static const warningContainer = Color(0xFFFFE8B8);
  static const rating = Color(0xFFF5A623);

  // Superfícies e texto
  static const background = Color(0xFFF9F9F9);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF3F3F3);
  static const surface = Color(0xFFEEEEEE);
  static const surfaceHigh = Color(0xFFE8E8E8);
  static const surfaceHighest = Color(0xFFE2E2E2);
  static const surfaceDim = Color(0xFFDADADA);
  static const textPrimary = Color(0xFF1A1C1C);
  static const textSecondary = Color(0xFF404752);
  static const textDisabled = Color(0xFF707883);
  static const border = Color(0xFFBFC7D4);
  static const inverseSurface = Color(0xFF2F3131);
  static const inverseOn = Color(0xFFF1F1F1);
}
