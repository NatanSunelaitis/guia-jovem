import 'package:flutter/material.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

class GJTimelineItem {
  const GJTimelineItem({
    required this.mes,
    required this.dia,
    this.ano,
    required this.titulo,
    this.descricao,
    this.concluido = false,
  });

  final String mes;
  final String dia;

  /// Ano da data, exibido abaixo do dia.
  final String? ano;
  final String titulo;
  final String? descricao;
  final bool concluido;
}

/// Linha do tempo (seção 3.18), usada no cronograma/"Datas Importantes" dos programas.
class GJTimeline extends StatelessWidget {
  const GJTimeline({super.key, required this.itens, this.cor = GJColors.primary});

  final List<GJTimelineItem> itens;

  /// Cor de destaque (dia e ponto concluído). Acompanha a cor da categoria
  /// do programa (financiamento usa tertiary, por exemplo).
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < itens.length; i++)
          _TimelineRow(item: itens[i], ultimo: i == itens.length - 1, cor: cor),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.ultimo, required this.cor});

  final GJTimelineItem item;
  final bool ultimo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final corPonto = item.concluido ? cor : GJColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(item.mes.toUpperCase(), style: GJTypography.caption().copyWith(fontWeight: FontWeight.w600)),
                Text(item.dia, style: GJTypography.h3().copyWith(color: cor)),
                if (item.ano != null) Text(item.ano!, style: GJTypography.caption()),
              ],
            ),
          ),
          const SizedBox(width: GJSpace.s4),
          SizedBox(
            width: 2,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // No último evento a linha desce só até o ponto, para chegar nele.
                if (ultimo) Container(width: 2, height: 13, color: GJColors.border) else Container(width: 2, color: GJColors.border),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: corPonto, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
          const SizedBox(width: GJSpace.s4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : GJSpace.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.titulo, style: GJTypography.body().copyWith(fontWeight: FontWeight.w600)),
                  if (item.descricao != null) ...[
                    const SizedBox(height: 2),
                    Text(item.descricao!, style: GJTypography.bodySm()),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
