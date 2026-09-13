import 'package:flutter/material.dart';

/// Grade responsiva que alinha a altura dos cards por linha (como o
/// `align-items: stretch` padrão do CSS Grid): cada linha tem a altura do
/// card mais alto dela, mas linhas diferentes podem ter alturas diferentes.
/// Um `Wrap` simples não faz isso (cada item mantém sua própria altura,
/// mesmo lado a lado com um vizinho mais alto).
class GJAlignedGrid extends StatelessWidget {
  const GJAlignedGrid({super.key, required this.children, required this.itemWidth, this.spacing = 24, this.runSpacing = 24});

  final List<Widget> children;
  final double itemWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = ((constraints.maxWidth + spacing) / (itemWidth + spacing)).floor().clamp(1, children.isEmpty ? 1 : children.length);

        final linhas = <Widget>[];
        for (var i = 0; i < children.length; i += colunas) {
          final itensLinha = children.skip(i).take(colunas).toList();
          if (i > 0) linhas.add(SizedBox(height: runSpacing));
          linhas.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < itensLinha.length; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(child: itensLinha[j]),
                  ],
                  // Preenche a última linha incompleta para os cards não
                  // esticarem além da largura pretendida (itemWidth).
                  if (itensLinha.length < colunas) Spacer(flex: colunas - itensLinha.length),
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
