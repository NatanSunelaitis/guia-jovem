import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/gj_breakpoints.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_button.dart';
import '../data/cadastro_universidade_state.dart';
import 'widgets/gj_auth_background.dart';

/// T12 Aviso de cadastro de universidade (`/cadastro/universidade`, Figura
/// 27). "Prosseguir" só habilita depois do checkbox marcado.
class AvisoCadastroUniversidadePage extends StatefulWidget {
  const AvisoCadastroUniversidadePage({super.key});

  @override
  State<AvisoCadastroUniversidadePage> createState() => _AvisoCadastroUniversidadePageState();
}

class _AvisoCadastroUniversidadePageState extends State<AvisoCadastroUniversidadePage> {
  late bool _aceito = cadastroUniversidadeState.aceitouTermos;

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return PublicLayout(
      child: GJAuthBackground(
        circulos: [gjCirculoDecorativo(left: 80, bottom: -40, tamanho: 280)],
        child: Container(
          width: isMobile ? double.infinity : 760,
          padding: const EdgeInsets.all(GJSpace.s8),
          decoration: BoxDecoration(
            color: GJColors.surfaceLowest,
            borderRadius: GJRadius.borderXl,
            boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: GJColors.warningContainer, borderRadius: GJRadius.borderMd),
                    child: const Icon(Icons.warning_rounded, size: 28, color: GJColors.warning),
                  ),
                  const SizedBox(width: GJSpace.s4),
                  Text('Atenção!', style: GJTypography.h1(size: 32)),
                ],
              ),
              const SizedBox(height: GJSpace.s4),
              Text(
                'Para segurança dos alunos, todos os cadastros de universidades passam por uma avaliação pela nossa '
                'equipe administrativa. Por isso, no cadastro, é necessário informar algumas informações da instituição, '
                'como CNPJ, endereço dos campus, entre outros. Esses dados serão utilizados somente na validação da '
                'universidade para as informações digitadas. Após o cadastro, em até 15 dias úteis você receberá no '
                'e-mail de cadastro a aprovação do cadastro ou solicitação de revisão nas informações digitadas.',
                style: GJTypography.body(),
              ),
              const SizedBox(height: GJSpace.s4),
              GestureDetector(
                onTap: () => setState(() => _aceito = !_aceito),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(value: _aceito, onChanged: (valor) => setState(() => _aceito = valor ?? false)),
                    const SizedBox(width: GJSpace.s2),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: GJSpace.s2),
                        child: Text('Concordo com os termos e condições', style: GJTypography.body()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GJSpace.s4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GJButton(label: 'Voltar', variant: GJButtonVariant.ghost, onPressed: () => context.go('/cadastro')),
                  const SizedBox(width: GJSpace.s3),
                  GJButton(
                    label: 'Prosseguir',
                    onPressed: _aceito
                        ? () {
                            cadastroUniversidadeState.aceitouTermos = true;
                            context.go('/cadastro/universidade/dados');
                          }
                        : null,
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
