import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/universidades/presentation/detalhe_universidade_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const DetalheUniversidadePage(id: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('mostra o detalhe da universidade, campus e programas', (tester) async {
    mockApi({
      '/universidades/1/avaliacoes': envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1}),
      '/universidades/1': envelope({
        'id': 1,
        'nomeFantasia': 'Fatec Sorocaba',
        'razaoSocial': 'Faculdade de Tecnologia de Sorocaba',
        'descricao': 'Descrição da faculdade',
        'logoUrl': null,
        'natureza': 'P',
        'linkPagina': 'https://fatecsorocaba.edu.br',
        'linkSimulados': null,
        'mediaAvaliacao': '4.5',
        'totalAvaliacoes': 2,
        'enderecoPrincipal': {
          'logradouro': 'Rua X',
          'numero': '1',
          'bairro': 'Centro',
          'cidade': 'Sorocaba',
          'estado': 'SP',
          'cep': '18000000',
        },
        'campus': [
          {'id': 10, 'nome': 'Fatec Sorocaba', 'cidade': 'Sorocaba', 'estado': 'SP', 'principal': true},
        ],
        'programas': {
          'ENTRADA': [
            {'id': 1, 'nome': 'ENEM', 'sigla': 'ENEM'},
          ],
          'FINANCIAMENTO': <Map<String, dynamic>>[],
          'BOLSA': <Map<String, dynamic>>[],
        },
      }),
    });

    await pump(tester);

    expect(find.text('Fatec Sorocaba'), findsWidgets);
    expect(find.text('Descrição da faculdade'), findsOneWidget);
    expect(find.text('Nenhuma avaliação ainda'), findsOneWidget);
  });

  testWidgets('mostra estado de erro quando a universidade não existe', (tester) async {
    mockApiError('/universidades/1', code: 'NOT_FOUND', message: 'Universidade não encontrada', status: 404);

    await pump(tester);

    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });

  testWidgets('"Tentar novamente" recarrega o detalhe depois de um erro', (tester) async {
    mockApiError('/universidades/1', message: 'Erro', status: 500);
    await pump(tester);
    expect(find.text('Não foi possível carregar'), findsOneWidget);

    mockApi({
      '/universidades/1/avaliacoes': envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1}),
      '/universidades/1': envelope({
        'id': 1,
        'nomeFantasia': 'Fatec Sorocaba',
        'razaoSocial': 'Faculdade de Tecnologia de Sorocaba',
        'natureza': 'P',
        'totalAvaliacoes': 0,
        'campus': <dynamic>[],
        'programas': <String, dynamic>{},
      }),
    });
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Não foi possível carregar'), findsNothing);
    expect(find.text('Fatec Sorocaba'), findsWidgets);
  });

  testWidgets('marca as bolsas próprias da universidade como "Bolsa institucional"', (tester) async {
    mockApi({
      '/universidades/1/avaliacoes': envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1}),
      '/universidades/1': envelope({
        'id': 1,
        'nomeFantasia': 'Fatec Sorocaba',
        'razaoSocial': 'Faculdade de Tecnologia de Sorocaba',
        'natureza': 'P',
        'totalAvaliacoes': 0,
        'campus': <dynamic>[],
        'programas': {
          'ENTRADA': <Map<String, dynamic>>[],
          'FINANCIAMENTO': <Map<String, dynamic>>[],
          'BOLSA': [
            {'id': 2, 'nome': 'Programa Universidade para Todos', 'sigla': 'ProUni', 'institucional': false},
            {'id': 9, 'nome': 'Bolsa Mérito Fatec', 'sigla': null, 'institucional': true},
          ],
        },
      }),
    });

    await pump(tester);

    expect(find.text('ProUni'), findsOneWidget);
    expect(find.text('Bolsa Mérito Fatec'), findsOneWidget);
    // Só a bolsa própria leva a identificação.
    expect(find.text('Bolsa institucional'), findsOneWidget);
  });
}
