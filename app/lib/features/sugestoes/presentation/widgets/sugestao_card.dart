import 'package:flutter/material.dart';

import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/utils/formatar_data.dart';
import '../../../../shared/widgets/gj_status_badge.dart';
import '../../domain/sugestao.dart';

/// Rótulo e cor do status (Em análise, Aprovada, Reprovada).
(String, GJStatusTone) rotuloStatusSugestao(StatusSugestao status) => switch (status) {
      StatusSugestao.aprovada => ('Aprovada', GJStatusTone.success),
      StatusSugestao.reprovada => ('Reprovada', GJStatusTone.error),
      StatusSugestao.emAnalise => ('Em análise', GJStatusTone.warning),
    };

class SugestaoStatusBadge extends StatelessWidget {
  const SugestaoStatusBadge({super.key, required this.status});

  final StatusSugestao status;

  @override
  Widget build(BuildContext context) {
    final (rotulo, tom) = rotuloStatusSugestao(status);
    return GJStatusBadge(label: rotulo, tone: tom);
  }
}

/// Cartão de uma sugestão nas listas (histórico do aluno e recebidas). Para o
/// destinatário ([mostrarAutor]), a linha de origem traz o autor em vez do destino.
class SugestaoCard extends StatelessWidget {
  const SugestaoCard({super.key, required this.sugestao, this.onTap, this.mostrarAutor = false, this.acao});

  final Sugestao sugestao;
  final VoidCallback? onTap;
  final bool mostrarAutor;

  /// Botão à direita (ex.: "Avaliar" nas recebidas).
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final origem = mostrarAutor
        ? 'De: ${sugestao.autorNome ?? 'Usuário removido'}'
        : 'Para: ${sugestao.destino}';

    return Material(
      color: GJColors.surfaceLowest,
      borderRadius: GJRadius.borderLg,
      child: InkWell(
        borderRadius: GJRadius.borderLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GJSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: GJSpace.s3,
                runSpacing: GJSpace.s2,
                children: [
                  Text(sugestao.titulo, style: GJTypography.h4()),
                  SugestaoStatusBadge(status: sugestao.status),
                ],
              ),
              const SizedBox(height: GJSpace.s1),
              Text('${formatarData(sugestao.criadoEm)} · $origem', style: GJTypography.caption()),
              const SizedBox(height: GJSpace.s2),
              Text(sugestao.texto, style: GJTypography.bodySm(), maxLines: 3, overflow: TextOverflow.ellipsis),
              if (sugestao.resposta != null) ...[
                const SizedBox(height: GJSpace.s3),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(GJSpace.s3),
                  decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resposta: ${sugestao.resposta}', style: GJTypography.bodySm()),
                      if (sugestao.avaliadoEm != null) ...[
                        const SizedBox(height: GJSpace.s1),
                        Text('Respondida em ${formatarData(sugestao.avaliadoEm!)}', style: GJTypography.caption()),
                      ],
                    ],
                  ),
                ),
              ],
              if (acao != null) ...[
                const SizedBox(height: GJSpace.s3),
                Align(alignment: Alignment.centerRight, child: acao!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
