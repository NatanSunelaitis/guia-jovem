import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/home/presentation/home_page.dart';
import 'package:app/features/universidades/presentation/pesquisa_universidades_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

final _vazio = envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1});

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('busca da home', () {
    late Map<String, String>? recebido;

    Future<void> abrirHome(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      recebido = null;
      mockApi({
        '/universidades/destaques': envelope(<dynamic>[]),
        '/programas/destaques': envelope(<dynamic>[]),
        '/cursos/destaques': envelope(<dynamic>[]),
      });
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/universidades',
          builder: (context, state) {
            recebido = state.extra as Map<String, String>?;
            return const Scaffold(body: Text('pesquisa'));
          },
        ),
      ]);
      await tester.pumpWidget(MaterialApp.router(theme: GJTheme.light, routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('"Todas" vem marcado e a pesquisa sai sem filtro de natureza, com o curso pelo nome', (tester) async {
      await abrirHome(tester);

      expect(find.text('Todas'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Curso que deseja estudar'), 'Enfermagem');
      await tester.tap(find.text('Pesquisar'));
      await tester.pumpAndSettle();

      expect(recebido, {'curso': 'Enfermagem'});
    });

    testWidgets('escolher "Privadas" leva a natureza; "Mais filtros" abre os avançados', (tester) async {
      await abrirHome(tester);

      await tester.tap(find.text('Privadas'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('home-mais-filtros')));
      await tester.pumpAndSettle();

      expect(recebido, {'natureza': 'V', 'filtrosAvancados': 'true'});
    });
  });

  group('pesquisa de universidades', () {
    Future<void> abrirPesquisa(WidgetTester tester, Map<String, String> filtros) async {
      tester.view.physicalSize = const Size(1366, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      mockApi({
        '/cursos/areas': envelope(['Engenharia', 'Saúde']),
        '/programas': envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1}),
        '/universidades': _vazio,
      });
      await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: PesquisaUniversidadesPage(filtrosIniciais: filtros)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('o campo Curso existe e chega preenchido da home, e vai para a API como curso', (tester) async {
      await abrirPesquisa(tester, {'curso': 'Enfermagem', 'cidade': 'Sorocaba'});

      expect(find.widgetWithText(TextField, 'Enfermagem'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Sorocaba'), findsOneWidget);
      final pedido = requisicoesApi.lastWhere((r) => r.url.path.endsWith('/universidades'));
      expect(pedido.url.queryParameters, containsPair('curso', 'Enfermagem'));
      // Sem filtro avançado em uso, eles ficam fechados.
      expect(find.byKey(const Key('filtro-area-curso')), findsNothing);
      expect(find.text('Filtros avançados'), findsOneWidget);
    });

    testWidgets('filtro avançado em uso abre sozinho, mostra a contagem e a área é uma lista de opções', (tester) async {
      await abrirPesquisa(tester, {'areaCurso': 'Saúde', 'estado': 'SP'});

      expect(find.text('Filtros avançados (2)'), findsOneWidget);
      expect(find.byKey(const Key('filtro-area-curso')), findsOneWidget);
      await tester.tap(find.byKey(const Key('filtro-area-curso')));
      await tester.pumpAndSettle();
      expect(find.text('Engenharia').last, findsOneWidget);
      await tester.tap(find.text('Engenharia').last);
      await tester.pumpAndSettle();
      final pedido = requisicoesApi.lastWhere((r) => r.url.path.endsWith('/universidades'));
      expect(pedido.url.queryParameters, containsPair('areaCurso', 'Engenharia'));
    });

    testWidgets('"Mais filtros" da home abre os avançados mesmo sem nenhum em uso', (tester) async {
      await abrirPesquisa(tester, {'filtrosAvancados': 'true'});

      expect(find.byKey(const Key('filtro-area-curso')), findsOneWidget);
      expect(find.text('Filtros avançados'), findsOneWidget);
    });
  });
}
