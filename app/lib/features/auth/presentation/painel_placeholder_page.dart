import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_button.dart';

/// Placeholder de T23/T24 (painel administrativo da universidade / do
/// Guia Jovem) até a Pendência 3 (docs/DECISOES.md).
class PainelPlaceholderPage extends StatelessWidget {
  const PainelPlaceholderPage({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: GJTypography.h1()),
              const SizedBox(height: GJSpace.s8),
              Row(
                children: [
                  const Icon(Symbols.construction, color: GJColors.textDisabled),
                  const SizedBox(width: GJSpace.s3),
                  Expanded(
                    child: Text(
                      'O painel administrativo ainda não foi construído.',
                      style: GJTypography.body().copyWith(color: GJColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GJSpace.s8),
              // Já disponível antes do painel: entra nele como aba depois.
              GJButton(
                label: 'Sugestões recebidas',
                icon: Symbols.forum,
                onPressed: () => context.go('/sugestoes-recebidas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
