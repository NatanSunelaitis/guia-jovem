import 'package:flutter/material.dart';

/// Grade responsiva que alinha a altura dos cards por linha (como o
/// `align-items: stretch` padrão do CSS Grid): cada linha tem a altura do
/// card mais alto dela, mas linhas diferentes podem ter alturas diferentes.
/// Um `Wrap` simples não faz isso (cada item mantém sua própria altura,
/// mesmo lado a lado com um vizinho mais alto).
///
/// O número de colunas vem da largura disponível e de [itemWidth]. Com menos
/// cards do que colunas (uma pesquisa com um resultado só, por exemplo), cada
/// card mantém a largura que teria na grade cheia. [ocuparLargura] faz os
/// poucos cards dividirem a largura toda (cards de resumo do dashboard).
class GJAlignedGrid extends StatelessWidget {
  const GJAlignedGrid({
    super.key,
    required this.children,
    required this.itemWidth,
    this.spacing = 24,
    this.runSpacing = 24,
    this.ocuparLargura = false,
  });

  final List<Widget> children;
  final double itemWidth;
  final double spacing;
  final double runSpacing;
  final bool ocuparLargura;

  /// Colunas que cabem em [largura] com cards de pelo menos [itemWidth].
  static int colunasPara(double largura, double itemWidth, double spacing) =>
      ((largura + spacing) / (itemWidth + spacing)).floor().clamp(1, 1 << 20);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var colunas = colunasPara(constraints.maxWidth, itemWidth, spacing);
        if (ocuparLargura && children.isNotEmpty && children.length < colunas) colunas = children.length;

        final linhas = <Widget>[];
        for (var i = 0; i < children.length; i += colunas) {
          final itensLinha = children.skip(i).take(colunas).toList();
          if (i > 0) linhas.add(SizedBox(height: runSpacing));
          linhas.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Linha incompleta: as vagas que faltam viram espaços do
                  // mesmo tamanho dos cards, para eles não esticarem.
                  for (var j = 0; j < colunas; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(child: j < itensLinha.length ? itensLinha[j] : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: linhas);
      },
    );
  }
}
