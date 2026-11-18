import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

class GJBarra {
  const GJBarra({required this.rotulo, required this.valor});

  final String rotulo;
  final int valor;
}

/// Gráfico de barras simples do dashboard (T24.1): barras proporcionais ao
/// maior valor, a escala no eixo e rótulos espaçados para não encavalar.
/// Feito com widgets, sem biblioteca de gráficos (o app roda no Flutter
/// 3.13 da CI). Cada barra tem dica com o valor ao passar o mouse.
class GJBarChart extends StatelessWidget {
  const GJBarChart({
    super.key,
    required this.barras,
    this.cor = GJColors.primary,
    this.altura = 180,
    this.descricaoValor = 'visitas',
  });

  final List<GJBarra> barras;
  final Color cor;
  final double altura;

  /// Unidade na dica (ex.: "12 visitas").
  final String descricaoValor;

  static const _maxRotulos = 8;

  @override
  Widget build(BuildContext context) {
    final maximo = barras.fold<int>(0, (atual, barra) => math.max(atual, barra.valor));
    final passoRotulo = math.max(1, (barras.length / _maxRotulos).ceil());

    return Semantics(
      label: 'Gráfico de barras com ${barras.length} períodos e máximo de $maximo $descricaoValor',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: altura,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: GJSpace.s12,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$maximo', style: GJTypography.caption()),
                      Text('${(maximo / 2).round()}', style: GJTypography.caption()),
                      Text('0', style: GJTypography.caption()),
                    ],
                  ),
                ),
                const SizedBox(width: GJSpace.s2),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: GJColors.surfaceDim)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final barra in barras)
                          Expanded(
                            child: Tooltip(
                              message: '${barra.rotulo}: ${barra.valor} $descricaoValor',
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: barras.length > 40 ? 0 : GJSpace.s1 / 2),
                                child: FractionallySizedBox(
                                  heightFactor: maximo == 0 ? 0 : barra.valor / maximo,
                                  alignment: Alignment.bottomCenter,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: cor,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(GJRadius.xs)),
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GJSpace.s2),
          Row(
            children: [
              const SizedBox(width: GJSpace.s12 + GJSpace.s2),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < barras.length; i++)
                      Expanded(
                        child: i % passoRotulo == 0
                            ? Text(
                                barras[i].rotulo,
                                style: GJTypography.caption(),
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
