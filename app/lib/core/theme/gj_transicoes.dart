import 'package:flutter/material.dart';

/// Transição entre telas do app: um fade curto no lugar da tela nova
/// deslizando ou empilhando. As rotas do Material duram 300 ms; o fade
/// acontece na primeira metade (cerca de 150 ms) e a tela de baixo fica
/// parada. Vale para todas as rotas, pelo tema (GJTheme), e não muda a
/// navegação: voltar e avançar do navegador continuam iguais.
class GJFadeTransitionsBuilder extends PageTransitionsBuilder {
  const GJFadeTransitionsBuilder();

  static const curva = Interval(0, 0.5, curve: Curves.easeOut);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: curva), child: child);
  }
}

/// O mesmo fade em todas as plataformas.
const gjPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: GJFadeTransitionsBuilder(),
    TargetPlatform.iOS: GJFadeTransitionsBuilder(),
    TargetPlatform.linux: GJFadeTransitionsBuilder(),
    TargetPlatform.macOS: GJFadeTransitionsBuilder(),
    TargetPlatform.windows: GJFadeTransitionsBuilder(),
    TargetPlatform.fuchsia: GJFadeTransitionsBuilder(),
  },
);
