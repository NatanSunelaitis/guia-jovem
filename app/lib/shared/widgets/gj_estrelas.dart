import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';

/// Quantas estrelas cheias e se há meia estrela para a média, arredondada
/// para o meio ponto mais próximo (4.5 dá quatro e meia; 4.3 dá quatro e meia;
/// 4.2 dá quatro).
({int cheias, bool meia}) estrelasDaMedia(double media) {
  final meios = (media.clamp(0, 5) * 2).round();
  return (cheias: meios ~/ 2, meia: meios.isOdd);
}

/// Cinco estrelas da média de avaliações, com meia estrela (RF01). Sem média,
/// as cinco ficam vazias na cor de borda.
class GJEstrelasMedia extends StatelessWidget {
  const GJEstrelasMedia({super.key, required this.media, this.tamanho = 18});

  final double? media;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final valor = media;
    final estrelas = valor == null ? (cheias: 0, meia: false) : estrelasDaMedia(valor);
    final cor = valor == null ? GJColors.border : GJColors.rating;

    return Semantics(
      label: valor == null ? 'Sem avaliações' : 'Média ${valor.toStringAsFixed(1)} de 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i == estrelas.cheias + 1 && estrelas.meia ? Symbols.star_half : Symbols.star,
              size: tamanho,
              fill: i <= estrelas.cheias || (i == estrelas.cheias + 1 && estrelas.meia) ? 1 : 0,
              color: cor,
            ),
        ],
      ),
    );
  }
}
