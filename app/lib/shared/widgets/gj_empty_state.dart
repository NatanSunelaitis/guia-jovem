import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';
import 'gj_button.dart';

/// Estado vazio/erro (seção 3.15): ícone, título, texto e botão opcional.
class GJEmptyState extends StatelessWidget {
  const GJEmptyState({
    super.key,
    required this.titulo,
    this.texto,
    this.icone = Symbols.search_off,
    this.acaoLabel,
    this.onAcao,
  });

  final String titulo;
  final String? texto;
  final IconData icone;
  final String? acaoLabel;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GJSpace.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 48, color: GJColors.textDisabled),
          const SizedBox(height: GJSpace.s4),
          Text(titulo, style: GJTypography.h4(), textAlign: TextAlign.center),
          if (texto != null) ...[
            const SizedBox(height: GJSpace.s2),
            Text(texto!, style: GJTypography.bodySm(), textAlign: TextAlign.center),
          ],
          if (acaoLabel != null) ...[
            const SizedBox(height: GJSpace.s4),
            GJButton(label: acaoLabel!, variant: GJButtonVariant.secondary, onPressed: onAcao),
          ],
        ],
      ),
    );
  }
}
