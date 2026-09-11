import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

/// Tom do GJTag, conforme as tabelas de cor por categoria e por status
/// do design system (seção 2.1).
enum GJTagTone { neutral, entrada, bolsa, financiamento, success, warning, error }

/// Tag/Chip do Guia Jovem Design System (seção 3.6).
class GJTag extends StatelessWidget {
  const GJTag({
    super.key,
    required this.label,
    this.tone = GJTagTone.neutral,
    this.onRemove,
  });

  final String label;
  final GJTagTone tone;
  final VoidCallback? onRemove;

  ({Color background, Color foreground}) get _colors => switch (tone) {
        GJTagTone.neutral => (background: GJColors.surface, foreground: GJColors.textSecondary),
        GJTagTone.entrada => (background: GJColors.primaryFixed, foreground: GJColors.primary),
        GJTagTone.bolsa => (background: GJColors.secondaryFixed, foreground: GJColors.secondary),
        GJTagTone.financiamento => (background: GJColors.tertiaryFixed, foreground: GJColors.tertiary),
        GJTagTone.success => (background: GJColors.successContainer, foreground: GJColors.success),
        GJTagTone.warning => (background: GJColors.warningContainer, foreground: GJColors.warning),
        GJTagTone.error => (background: GJColors.errorContainer, foreground: GJColors.errorOnContainer),
      };

  @override
  Widget build(BuildContext context) {
    final colors = _colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GJSpace.s3, vertical: GJSpace.s1),
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GJTypography.caption(color: colors.foreground).copyWith(fontWeight: FontWeight.w600)),
          if (onRemove != null) ...[
            const SizedBox(width: GJSpace.s1),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Symbols.close, size: 14, color: colors.foreground),
            ),
          ],
        ],
      ),
    );
  }
}
