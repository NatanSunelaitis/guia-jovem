import 'package:flutter/material.dart';

import '../../../../core/theme/gj_breakpoints.dart';
import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_spacing.dart';

/// Fundo das telas de autenticação (T09, T11, T25, T26): seção
/// surface.low com círculos decorativos atrás de um card branco central.
class GJAuthBackground extends StatelessWidget {
  const GJAuthBackground({super.key, required this.child, this.circulos = const []});

  final Widget child;
  final List<Widget> circulos;

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return Container(
      width: double.infinity,
      color: GJColors.surfaceLow,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? GJSpace.s4 : GJSpace.s16,
        vertical: isMobile ? GJSpace.s8 : GJSpace.s16,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [...circulos, child],
      ),
    );
  }
}

Widget gjCirculoDecorativo({double? left, double? top, double? right, double? bottom, double tamanho = 420}) {
  return Positioned(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    child: Container(
      width: tamanho,
      height: tamanho,
      decoration: const BoxDecoration(color: GJColors.primaryFixed, shape: BoxShape.circle),
    ),
  );
}
