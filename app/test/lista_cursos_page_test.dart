import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/cursos/presentation/lista_cursos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const ListaCursosPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('lista cursos agrupados por nome, com contagem de universidades', (tester) async {
    mockApi({
      '/cursos/destaques': envelope([
        {'nome': 'Administração', 'areaCurso': 'Negócios', 'totalOfertas': 2},
      ]),
    });

    await pump(tester);

    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Negócios'), findsOneWidget);
    expect(find.text('2 universidades'), findsOneWidget);
  });

  testWidgets('grupo com mais de um grau indica os graus no card e conta universidades', (tester) async {
    mockApi({
      '/cursos/destaques': envelope([
        {
          'nome': 'Educação Física',
          'areaCurso': 'Saúde',
          'graus': ['Licenciatura', 'Bacharelado'],
          'totalOfertas': 3,
          'totalUniversidades': 2,
        },
        {'nome': 'Direito', 'areaCurso': 'Direito', 'graus': ['Bacharelado'], 'totalOfertas': 1, 'totalUniversidades': 1},
      ]),
    });

    await pump(tester);

    expect(find.text('Licenciatura e Bacharelado'), findsOneWidget);
    expect(find.text('2 universidades'), findsOneWidget);
    expect(find.byKey(const Key('graus-Direito')), findsNothing);
  });

  testWidgets('volume: 30 cursos em páginas de 12', (tester) async {
    tester.view.physicalSize = const Size(1366, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockApi({
      '/cursos/destaques': envelope([
        for (var i = 1; i <= 30; i++) {'nome': 'Curso ${i.toString().padLeft(2, '0')}', 'areaCurso': 'Saúde', 'totalOfertas': 1},
      ]),
    });

    await pump(tester);

    expect(find.text('30 cursos'), findsOneWidget);
    expect(find.text('Página 1 de 3'), findsOneWidget);
    expect(find.text('Curso 12'), findsOneWidget);
    expect(find.text('Curso 13'), findsNothing);
    expect(requisicoesApi.last.url.queryParameters['limite'], '200');

    await tester.tap(find.byTooltip('Próxima página'));
    await tester.pump();
    expect(find.text('Curso 13'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há cursos', (tester) async {
    mockApi({
      '/cursos/destaques': envelope(<dynamic>[]),
    });

    await pump(tester);

    expect(find.text('Nenhum curso encontrado'), findsOneWidget);
  });
}
