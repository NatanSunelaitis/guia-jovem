import 'package:flutter/material.dart';

import '../../core/theme/gj_breakpoints.dart';
import '../../core/theme/gj_spacing.dart';

/// Contêiner de conteúdo das páginas públicas: largura máxima de 1280px,
/// centralizado na página, com a mesma calha lateral em toda tela (T01 a
/// T08). Sem isso, cada página definia seu próprio padding horizontal e o
/// conteúdo variava de largura conforme o tamanho da tela.
class GJPageContainer extends StatelessWidget {
  const GJPageContainer({super.key, required this.child});

  final Widget child;

  static const double larguraMaxima = 1280;

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: larguraMaxima),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16),
          child: child,
        ),
      ),
    );
  }
}
