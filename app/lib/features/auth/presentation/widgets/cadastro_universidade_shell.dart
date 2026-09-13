import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/gj_breakpoints.dart';
import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/layouts/public_layout.dart';
import '../../../../shared/widgets/gj_button.dart';

const _passos = ['Dados', 'Programas', 'Campus'];

/// Casca comum de T13, T14 e T15 (fluxo 7.3): stepper de 3 passos, título e
/// os botões Voltar/Próximo (ou Cadastrar, no passo 3).
class CadastroUniversidadeShell extends StatelessWidget {
  const CadastroUniversidadeShell({
    super.key,
    required this.passoAtual,
    required this.titulo,
    required this.child,
    this.aoVoltar,
    required this.aoAvancar,
    required this.rotuloAvancar,
    this.avancarCarregando = false,
  });

  final int passoAtual;
  final String titulo;
  final Widget child;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoAvancar;
  final String rotuloAvancar;
  final bool avancarCarregando;

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return PublicLayout(
      child: Container(
        width: double.infinity,
        color: GJColors.surfaceLow,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16, vertical: GJSpace.s12),
        child: Center(
          child: Container(
            width: isMobile ? double.infinity : 900,
            padding: EdgeInsets.all(isMobile ? GJSpace.s6 : GJSpace.s8),
            decoration: BoxDecoration(
              color: GJColors.surfaceLowest,
              borderRadius: GJRadius.borderXl,
              boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stepper(passoAtual: passoAtual),
                const SizedBox(height: GJSpace.s6),
                Text(titulo, style: GJTypography.h1(size: 32)),
                const SizedBox(height: GJSpace.s6),
                child,
                const SizedBox(height: GJSpace.s6),
                Row(
                  mainAxisAlignment: aoVoltar != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                  children: [
                    if (aoVoltar != null) GJButton(label: 'Voltar', variant: GJButtonVariant.secondary, onPressed: aoVoltar),
                    GJButton(label: rotuloAvancar, onPressed: aoAvancar, loading: avancarCarregando),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.passoAtual});

  final int passoAtual;

  @override
  Widget build(BuildContext context) {
    final itens = <Widget>[];
    for (var i = 0; i < _passos.length; i++) {
      final numero = i + 1;
      final concluido = numero < passoAtual;
      final atual = numero == passoAtual;

      itens.add(
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: concluido ? GJColors.primary : Colors.transparent,
                border: concluido ? null : Border.all(color: atual ? GJColors.primary : GJColors.border, width: 2),
              ),
              child: concluido
                  ? const Icon(Symbols.check, size: 18, color: GJColors.primaryOn)
                  : Text('$numero', style: GJTypography.label(color: atual ? GJColors.primary : GJColors.textDisabled).copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: GJSpace.s2),
            Text(_passos[i], style: GJTypography.caption(color: atual || concluido ? GJColors.primary : GJColors.textDisabled)),
          ],
        ),
      );

      if (i < _passos.length - 1) {
        itens.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: GJSpace.s3),
              child: Container(height: 2, color: numero < passoAtual ? GJColors.primary : GJColors.border),
            ),
          ),
        );
      }
    }

    return Row(children: itens);
  }
}
