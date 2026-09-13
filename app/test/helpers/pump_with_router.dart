import 'package:app/core/theme/gj_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Monta um GoRouter mínimo, só com as rotas que o teste precisa, para
/// telas que navegam com `context.go(...)`. Cada teste usa seu próprio
/// GoRouter (não o `appRouter` do app) para não reaproveitar o
/// `GlobalKey<NavigatorState>` entre pumps diferentes.
Future<GoRouter> pumpComRouter(
  WidgetTester tester, {
  required String initialLocation,
  required Map<String, WidgetBuilder> rotas,
  Size tamanhoTela = const Size(1440, 1800),
}) async {
  // As telas públicas (com o cartão de auth centralizado) costumam ser mais
  // altas que os 800x600 padrão do flutter test, e ficariam fora da área
  // visível (sem rolar) para tap/ensureVisible. Usar um viewport 1440x1800
  // também casa com a comparação visual a 1440px feita à parte com Playwright.
  final viewOriginal = tester.view.physicalSize;
  final dprOriginal = tester.view.devicePixelRatio;
  tester.view.physicalSize = tamanhoTela;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.physicalSize = viewOriginal;
    tester.view.devicePixelRatio = dprOriginal;
  });

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      for (final entrada in rotas.entries) GoRoute(path: entrada.key, builder: (context, state) => entrada.value(context)),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(theme: GJTheme.light, routerConfig: router));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return router;
}

/// Página marcadora, usada como destino de navegação nos testes: só
/// precisa aparecer (`find.text(rotulo)`) para confirmar que a navegação
/// aconteceu.
class PaginaMarcadora extends StatelessWidget {
  const PaginaMarcadora(this.rotulo, {super.key});

  final String rotulo;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(rotulo)));
}
