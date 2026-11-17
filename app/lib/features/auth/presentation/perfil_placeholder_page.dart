import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../data/session_controller.dart';

/// Placeholder de T17 (perfil da universidade) e do perfil do administrador até a Pendência 3
/// (docs/DECISOES.md): o menu do avatar já funciona (RF08 etc.), mas as
/// telas de perfil de verdade ainda não foram construídas.
class PerfilPlaceholderPage extends StatelessWidget {
  const PerfilPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = sessionController.usuario;

    return PublicLayout(
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Perfil', style: GJTypography.h1()),
              const SizedBox(height: GJSpace.s2),
              if (usuario != null) Text('${usuario.nome} · ${usuario.email}', style: GJTypography.body().copyWith(color: GJColors.textSecondary)),
              const SizedBox(height: GJSpace.s8),
              Row(
                children: [
                  const Icon(Symbols.construction, color: GJColors.textDisabled),
                  const SizedBox(width: GJSpace.s3),
                  Expanded(
                    child: Text(
                      'A tela completa de perfil (editar dados, alterar senha, faculdades salvas, sugestões) ainda não foi construída.',
                      style: GJTypography.body().copyWith(color: GJColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
