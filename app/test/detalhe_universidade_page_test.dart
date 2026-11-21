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

  testWidgets('separa as bolsas da própria instituição das bolsas nacionais', (tester) async {
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
    // A bolsa própria fica num grupo à parte, sem a etiqueta colada.
    expect(find.text('BOLSAS DA PRÓPRIA INSTITUIÇÃO'), findsOneWidget);
    expect(find.text('Bolsa institucional'), findsNothing);
  });
  testWidgets('resume os cursos oferecidos com o campus de cada um', (tester) async {
    mockApi({
      '/universidades/1/avaliacoes': envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1}),
      '/universidades/1/campus': envelope([
        {
          'id': 4,
          'nome': 'Campus Centro',
          'principal': true,
          'endereco': {'logradouro': 'Rua A', 'numero': '1', 'bairro': 'Centro', 'cidade': 'Sorocaba', 'estado': 'SP'},
          'cursos': [
            {'id': 30, 'nome': 'Enfermagem', 'turno': 'Integral', 'vagas': 60},
          ],
        },
      ]),
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

    await pump(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Cursos oferecidos'), findsOneWidget);
    expect(find.text('Enfermagem'), findsOneWidget);
    expect(find.text('Campus Centro · Integral · 60 vagas'), findsOneWidget);
  });

  testWidgets('Sobre formatado, razão social, contato e observação dos programas aceitos', (tester) async {
    tester.view.physicalSize = const Size(1366, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockApi({
      '/universidades/1/avaliacoes': envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1}),
      '/universidades/1/campus': envelope([
        {
          'id': 4,
          'nome': 'Campus Centro',
          'principal': true,
          'telefoneFixo': '(15) 3201-4600',
          'emailCampus': 'centro@example.com',
          'endereco': {'logradouro': 'Rua XV de Novembro', 'numero': '1250', 'bairro': 'Centro', 'cidade': 'Sorocaba', 'estado': 'SP', 'cep': '18010081'},
          'cursos': <dynamic>[],
        },
      ]),
      '/universidades/1': envelope({
        'id': 1,
        'nomeFantasia': 'UniVale Sorocaba',
        'razaoSocial': 'Centro Universitário Vale do Sorocaba',
        'descricao': 'Centro universitário em **Sorocaba**.\n\n## Diferenciais\n\n- Laboratórios\n- Estágios',
        'natureza': 'V',
        'telefonePrincipal': '(15) 3201-4500',
        'linkPagina': 'https://www.example.com/univale',
        'totalAvaliacoes': 0,
        'campus': <dynamic>[],
        'programas': {
          'ENTRADA': [
            {'id': 1, 'nome': 'Exame Nacional do Ensino Médio', 'sigla': 'ENEM', 'observacao': null},
            {'id': 4, 'nome': 'Vestibular', 'sigla': 'VESTIBULAR', 'observacao': 'Vestibular de verão com prova on-line'},
          ],
          'FINANCIAMENTO': <dynamic>[],
          'BOLSA': <dynamic>[],
        },
      }),
    });

    await pump(tester);

    expect(find.text('Centro Universitário Vale do Sorocaba'), findsOneWidget);
    expect(find.text('Diferenciais', findRichText: true), findsOneWidget);
    expect(find.text('Laboratórios', findRichText: true), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
    expect(find.text('Contato'), findsWidgets);
    expect(find.text('(15) 3201-4500'), findsOneWidget);
    expect(find.text('(15) 3201-4600'), findsOneWidget);
    expect(find.text('centro@example.com'), findsOneWidget);
    expect(find.text('Rua XV de Novembro, 1250 · Centro · Sorocaba/SP · CEP 18010-081'), findsOneWidget);
    expect(find.text('Vestibular de verão com prova on-line'), findsOneWidget);
    expect(find.text('ENEM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('volume: 25 cursos em 10 por página com busca, e avaliações paginadas com a distribuição de todas', (tester) async {
    tester.view.physicalSize = const Size(1366, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockApi({
      '/universidades/1/avaliacoes': envelope([
        for (var i = 1; i <= 5; i++) {'id': i, 'nota': 5, 'comentario': 'Comentário $i', 'criadoEm': '2026-11-01T00:00:00Z', 'autor': 'Aluno'},
      ], {'page': 1, 'pageSize': 5, 'total': 40, 'totalPages': 8, 'distribuicao': {'1': 10, '2': 0, '3': 10, '4': 0, '5': 20}}),
      '/universidades/1/campus': envelope([
        {
          'id': 4,
          'nome': 'Campus Centro',
          'principal': true,
          'endereco': {'logradouro': 'Rua A', 'numero': '1', 'bairro': 'Centro', 'cidade': 'Sorocaba', 'estado': 'SP'},
          'cursos': [
            for (var i = 1; i <= 25; i++) {'id': i, 'nome': i == 7 ? 'Educação Física' : 'Curso ${i.toString().padLeft(2, '0')}', 'turno': 'Noturno', 'vagas': 30},
          ],
        },
      ]),
      '/universidades/1': envelope({
        'id': 1,
        'nomeFantasia': 'Universidade Volume',
        'razaoSocial': 'Universidade Volume',
        'natureza': 'V',
        'mediaAvaliacao': '3.5',
        'totalAvaliacoes': 40,
        'campus': <dynamic>[],
        'programas': <String, dynamic>{},
      }),
    });

    await pump(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('25 cursos'), findsOneWidget);
    expect(find.text('Página 1 de 3'), findsOneWidget);
    expect(find.text('Curso 01'), findsOneWidget);
    expect(find.text('Curso 12'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Buscar curso'), 'educacao');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Educação Física'), findsOneWidget);
    expect(find.text('1 curso'), findsOneWidget);

    // Distribuição: 20 de 40 com nota 5 (barra pela metade), embora a página tenha só 5.
    expect(find.text('Página 1 de 8'), findsOneWidget);
    final barras = tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).map((b) => b.value).toList();
    expect(barras.first, 0.5);
    expect(find.text('20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
