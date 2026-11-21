import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/campus/presentation/detalhe_campus_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const DetalheCampusPage(id: 10)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('mostra o detalhe do campus com os cursos', (tester) async {
    mockApi({
      '/campus/10/cursos': envelope([
        {'id': 5, 'nome': 'Administração', 'areaCurso': 'Negócios', 'grau': 'Bacharelado', 'modalidade': 'Presencial', 'turno': 'Integral', 'vagas': 40},
      ], {'page': 1, 'pageSize': 12, 'total': 1, 'totalPages': 1}),
      '/campus/10': envelope({
        'id': 10,
        'nome': 'Fatec Sorocaba',
        'telefoneCelular': null,
        'telefoneFixo': '(15) 3232-0000',
        'emailCampus': null,
        'principal': true,
        'universidade': {'id': 1, 'nomeFantasia': 'Fatec Sorocaba'},
        'endereco': {
          'logradouro': 'Av. X',
          'numero': '100',
          'complemento': null,
          'bairro': 'Centro',
          'cidade': 'Sorocaba',
          'estado': 'SP',
          'cep': '18000000',
        },
        'totalCursos': 1,
        'areasCursos': ['Negócios'],
      }),
    });

    await pump(tester);

    expect(find.text('Fatec Sorocaba'), findsWidgets);
    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Negócios · Bacharelado · Presencial'), findsOneWidget);
    expect(find.text('Integral'), findsOneWidget);
    expect(find.text('40 vagas'), findsOneWidget);
    expect(find.text('1 curso encontrado'), findsOneWidget);
    expect(find.text('Lista de cursos oferecidos neste campus'), findsOneWidget);
  });

  testWidgets('40 cursos: linhas de altura igual, busca, filtro por área e paginação pela API', (tester) async {
    tester.view.physicalSize = const Size(1366, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockApi({
      '/campus/10/cursos': envelope([
        for (var i = 1; i <= 12; i++)
          {'id': i, 'nome': i == 3 ? 'Curso com um nome bem comprido para testar a linha da lista $i' : 'Curso $i', 'areaCurso': i.isEven ? 'Saúde' : 'Exatas', 'grau': 'Bacharelado', 'modalidade': 'Presencial', 'turno': 'Noturno', 'vagas': 40},
      ], {'page': 1, 'pageSize': 12, 'total': 40, 'totalPages': 4}),
      '/campus/10': envelope({
        'id': 10,
        'nome': 'Campus Volume',
        'principal': true,
        'universidade': {'id': 1, 'nomeFantasia': 'Universidade Volume'},
        'endereco': {'logradouro': 'Rua A', 'numero': '1', 'bairro': 'Centro', 'cidade': 'Sorocaba', 'estado': 'SP', 'cep': null},
        'totalCursos': 40,
        'areasCursos': ['Exatas', 'Saúde'],
      }),
    });

    await pump(tester);

    expect(find.text('40 cursos encontrados'), findsOneWidget);
    expect(find.text('Página 1 de 4'), findsOneWidget);
    final alturas = {for (final id in [1, 2, 3]) tester.getSize(find.byKey(Key('curso-campus-$id'))).height};
    expect(alturas, hasLength(1));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Próxima página'));
    await tester.pumpAndSettle();
    expect(requisicoesApi.last.url.queryParameters['page'], '2');

    await tester.enterText(find.byType(TextField).first, 'enfer');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(requisicoesApi.last.url.queryParameters, containsPair('q', 'enfer'));
    expect(requisicoesApi.last.url.queryParameters['page'], '1');

    await tester.tap(find.byKey(const Key('lista-paginada-filtro')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saúde').last);
    await tester.pumpAndSettle();
    expect(requisicoesApi.last.url.queryParameters, containsPair('areaCurso', 'Saúde'));
  });

  testWidgets('mostra estado de erro quando o campus não existe', (tester) async {
    mockApiError('/campus/10', code: 'NOT_FOUND', status: 404);

    await pump(tester);

    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });
}
