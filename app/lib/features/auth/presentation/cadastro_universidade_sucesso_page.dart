import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_breakpoints.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_button.dart';
import 'widgets/gj_auth_background.dart';

/// Tela de sucesso do fluxo 7.3, ao fim de T15: "Cadastro enviado para
/// análise".
class CadastroUniversidadeSucessoPage extends StatelessWidget {
  const CadastroUniversidadeSucessoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return PublicLayout(
      child: GJAuthBackground(
        circulos: [gjCirculoDecorativo(right: -140, top: -120, tamanho: 380)],
        child: Container(
          width: isMobile ? double.infinity : 640,
          padding: const EdgeInsets.symmetric(horizontal: GJSpace.s8, vertical: GJSpace.s12),
          decoration: BoxDecoration(
            color: GJColors.surfaceLowest,
            borderRadius: GJRadius.borderXl,
            boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: GJColors.successContainer, shape: BoxShape.circle),
                child: const Icon(Symbols.check_circle, size: 48, color: GJColors.success, fill: 1),
              ),
              const SizedBox(height: GJSpace.s5),
              Text('Cadastro enviado para análise', style: GJTypography.h1(size: 32), textAlign: TextAlign.center),
              const SizedBox(height: GJSpace.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(
                  'Você receberá um e-mail em até 15 dias úteis com a aprovação do cadastro ou o pedido de revisão das informações.',
                  style: GJTypography.body(),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: GJSpace.s6),
              GJButton(label: 'Voltar para a página inicial', onPressed: () => context.go('/')),
            ],
          ),
        ),
      ),
    );
  }
}
