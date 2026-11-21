import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/programas/domain/programa.dart';
import 'package:app/features/programas/presentation/detalhe_programa_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, int id) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: DetalheProgramaPage(id: id)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('mostra o detalhe do ENEM (categoria entrada)', (tester) async {
    mockApi({
      '/programas/1': envelope({
        'id': 1,
        'nome': 'Exame Nacional do Ensino Médio',
        'sigla': 'ENEM',
        'tipo': 'ENTRADA',
        'descricao': 'Descrição do ENEM',
        'requisitos': 'Requisitos',
        'comoFunciona': 'Como funciona',
        'linkOficial': 'https://enem.inep.gov.br',
        'imagemUrl': null,
        'universidadeId': null,
        'eventos': <Map<String, dynamic>>[],
        'universidades': <Map<String, dynamic>>[],
      }),
    });

    await pump(tester, 1);

    expect(find.text('Exame Nacional do Ensino Médio'), findsOneWidget);
    expect(find.text('PROGRAMA DE ENTRADA'), findsOneWidget);
    expect(find.text('Ver site oficial'), findsOneWidget);
  });

  testWidgets('mostra o detalhe do FIES (categoria financiamento)', (tester) async {
    mockApi({
      '/programas/5': envelope({
        'id': 5,
        'nome': 'Fundo de Financiamento Estudantil',
        'sigla': 'FIES',
        'tipo': 'FINANCIAMENTO',
        'descricao': 'Descrição do FIES',
        'requisitos': 'Requisitos',
        'comoFunciona': 'Como funciona',
        'linkOficial': 'https://fies.mec.gov.br',
        'imagemUrl': null,
        'universidadeId': null,
        'eventos': <Map<String, dynamic>>[],
        'universidades': <Map<String, dynamic>>[],
      }),
    });

    await pump(tester, 5);

    expect(find.text('Fundo de Financiamento Estudantil'), findsOneWidget);
    expect(find.text('FINANCIAMENTO ESTUDANTIL'), findsOneWidget);
  });

  testWidgets('bolsa institucional mostra a universidade dona e passos próprios', (tester) async {
    mockApi({
      '/programas/12': envelope({
        'id': 12,
        'nome': 'Bolsa Primeira Geração UniVale',
        'sigla': null,
        'tipo': 'BOLSA',
        'descricao': 'Desconto de 30%',
        'requisitos': 'Escola pública',
        'comoFunciona': 'Na secretaria',
        'linkOficial': null,
        'imagemUrl': null,
        'universidadeId': 1,
        'universidade': {'id': 1, 'nomeFantasia': 'UniVale Sorocaba', 'logoUrl': null},
        'eventos': [
          {'id': 1, 'titulo': 'Inscrições', 'descricao': null, 'dataInicio': '2026-11-10T00:00:00.000Z', 'dataFim': null},
          {'id': 2, 'titulo': 'Resultado', 'descricao': null, 'dataInicio': '2027-01-29T00:00:00.000Z', 'dataFim': null},
        ],
        'universidades': <Map<String, dynamic>>[],
      }),
    });

    await pump(tester, 12);

    expect(find.text('Universidade que oferece esta bolsa'), findsOneWidget);
    expect(find.text('Nenhuma universidade cadastrada ainda para este programa'), findsNothing);
    expect(find.textContaining('critérios de renda'), findsNothing);
    expect(find.text('Cronograma 2026 e 2027'), findsOneWidget);
    expect(find.text('2027'), findsOneWidget);
  });

  Map<String, dynamic> programa({required List<Map<String, dynamic>> eventos}) => envelope({
        'id': 8,
        'nome': 'Programa Escola da Família',
        'sigla': 'Escola da Família',
        'tipo': 'BOLSA',
        'descricao': 'Descrição',
        'requisitos': 'Requisitos',
        'comoFunciona': 'Como funciona',
        'linkOficial': null,
        'imagemUrl': null,
        'universidadeId': null,
        'eventos': eventos,
        'universidades': <Map<String, dynamic>>[],
      });

  testWidgets('sem datas importantes, os próximos passos ocupam a largura toda', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockApi({'/programas/8': programa(eventos: [])});

    await pump(tester, 8);

    expect(find.textContaining('Cronograma'), findsNothing);
    // Começa na mesma coluna do "Como Funciona" e passa da metade da página.
    final passos = find.text('Próximos Passos');
    expect(tester.getTopLeft(passos).dx, tester.getTopLeft(find.text('Como Funciona')).dx);
    final ultimoPasso = find.textContaining('Anote as datas');
    expect(tester.getTopLeft(ultimoPasso).dx, greaterThan(1366 / 2));
  });

  testWidgets('com datas, cronograma e próximos passos ficam lado a lado', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockApi({
      '/programas/8': programa(eventos: [
        {'id': 1, 'titulo': 'Inscrições', 'descricao': null, 'dataInicio': '2027-01-11T00:00:00.000Z', 'dataFim': null},
      ]),
    });

    await pump(tester, 8);

    expect(tester.getTopLeft(find.text('Próximos Passos')).dx, greaterThan(tester.getTopLeft(find.text('Cronograma 2027')).dx));
  });

  testWidgets('o cabeçalho mostra a foto do programa', (tester) async {
    mockApi({'/programas/8': programa(eventos: [])});

    await pump(tester, 8);

    final imagem = tester.widget<Image>(find.byType(Image).first);
    expect((imagem.image as AssetImage).assetName, 'assets/fotos/programas/escola-da-familia.jpg');
  });

  test('o título do cronograma traz os anos das datas', () {
    ProgramaEvento evento(int ano) => ProgramaEvento(id: ano, titulo: 't', dataInicio: DateTime(ano, 3, 1));
    expect(tituloCronograma([evento(2027), evento(2027)]), 'Cronograma 2027');
    expect(tituloCronograma([evento(2027), evento(2026)]), 'Cronograma 2026 e 2027');
    expect(tituloCronograma([evento(2026), evento(2028), evento(2027)]), 'Cronograma 2026 a 2028');
  });

  testWidgets('descrição em seções: abertura no topo, um card por seção e nada dos símbolos', (tester) async {
    tester.view.physicalSize = const Size(1366, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockApi({
      '/programas/9': envelope({
        'id': 9,
        'nome': 'Programa Universidade para Todos',
        'sigla': 'ProUni',
        'tipo': 'BOLSA',
        'descricao': '## O que é\n\nPrograma do governo federal com **bolsas**.\n\n'
            '## Quem pode participar\n\n- Quem fez o Enem\n\n'
            '## Passo a passo\n\n1. Faça o Enem\n2. Inscreva-se\n\n'
            'Confira o edital no [site oficial](https://acessounico.mec.gov.br/prouni).',
        'requisitos': null,
        'comoFunciona': null,
        'linkOficial': 'https://acessounico.mec.gov.br/prouni',
        'imagemUrl': null,
        'universidadeId': null,
        'eventos': [
          {'id': 1, 'titulo': 'Inscrições', 'descricao': 'Primeiro semestre', 'dataInicio': '2027-01-26', 'dataFim': '2027-01-29'},
        ],
        'universidades': [
          {'id': 3, 'nomeFantasia': 'UniVale Sorocaba', 'logoUrl': null, 'observacao': 'Bolsas integrais e parciais em todos os cursos'},
          {'id': 4, 'nomeFantasia': 'FEITU', 'logoUrl': null, 'observacao': null},
        ],
        'totalUniversidades': 2,
      }),
      '/programas/9/universidades': envelope([
        {'id': 3, 'nomeFantasia': 'UniVale Sorocaba', 'logoUrl': null, 'cidade': 'Sorocaba', 'estado': 'SP', 'observacao': 'Bolsas integrais e parciais em todos os cursos'},
        {'id': 4, 'nomeFantasia': 'FEITU', 'logoUrl': null, 'cidade': 'Itu', 'estado': 'SP', 'observacao': null},
      ], {'page': 1, 'pageSize': 8, 'total': 2, 'totalPages': 1}),
    });

    await pump(tester, 9);

    // Abertura (primeiro parágrafo) no topo, em texto puro.
    expect(find.text('Programa do governo federal com bolsas.'), findsOneWidget);
    // A seção "O que é" ficou só com a abertura, então não vira card.
    expect(find.text('O que é'), findsNothing);
    expect(find.text('Quem pode participar'), findsOneWidget);
    expect(find.text('Passo a passo'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('site oficial', findRichText: true), findsNothing);
    expect(find.text('Confira o edital no site oficial.', findRichText: true), findsOneWidget);
    expect(find.textContaining('##', findRichText: true), findsNothing);
    expect(find.textContaining('**', findRichText: true), findsNothing);
    // Sem "como funciona" e "requisitos", os dois cards antigos não aparecem.
    expect(find.text('Como Funciona'), findsNothing);
    expect(find.text('Elegibilidade'), findsNothing);
    // Observação da universidade e o período do evento.
    expect(find.text('Bolsas integrais e parciais em todos os cursos'), findsOneWidget);
    expect(find.text('Primeiro semestre · Até 29 jan 2027'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('abertura e seções do programa', () {
    expect(aberturaDoPrograma('Só um parágrafo.'), 'Só um parágrafo.');
    expect(secoesDoPrograma('Só um parágrafo.'), isEmpty);
    final secoes = secoesDoPrograma('Abertura.\n\nMais um parágrafo.\n\n## Documentos\n\n- RG');
    expect(secoes.map((s) => s.titulo), [null, 'Documentos']);
  });

  test('descrição do evento com o fim do período', () {
    final evento = ProgramaEvento(id: 1, titulo: 'T', dataInicio: DateTime(2027, 5, 10), dataFim: DateTime(2027, 5, 21));
    expect(descricaoDoEvento(evento), 'Até 21 mai 2027');
    expect(descricaoDoEvento(ProgramaEvento(id: 2, titulo: 'T', descricao: 'D', dataInicio: DateTime(2027, 5, 10))), 'D');
  });

  testWidgets('60 universidades: 8 por página, cards de altura igual, busca por nome ou cidade', (tester) async {
    tester.view.physicalSize = const Size(1366, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockApi({
      '/programas/7/universidades': envelope([
        for (var i = 1; i <= 8; i++)
          {
            'id': i,
            'nomeFantasia': i == 2 ? 'Centro Universitário de Nome Muito Comprido da Região Metropolitana $i' : 'Universidade $i',
            'logoUrl': null,
            'cidade': 'Sorocaba',
            'estado': 'SP',
            'observacao': i.isOdd ? 'Observação $i' : null,
          },
      ], {'page': 1, 'pageSize': 8, 'total': 60, 'totalPages': 8}),
      '/programas/7': envelope({
        'id': 7,
        'nome': 'Programa Universidade para Todos',
        'sigla': 'ProUni',
        'tipo': 'BOLSA',
        'descricao': 'Bolsas.',
        'linkOficial': null,
        'imagemUrl': null,
        'universidadeId': null,
        'eventos': <dynamic>[],
        'universidades': <dynamic>[],
        'totalUniversidades': 60,
      }),
    });

    await pump(tester, 7);

    expect(find.text('60 universidades aceitam este programa'), findsOneWidget);
    expect(find.text('Página 1 de 8'), findsOneWidget);
    expect(requisicoesApi.last.url.queryParameters, containsPair('pageSize', '8'));
    final alturas = {for (var i = 1; i <= 8; i++) tester.getSize(find.byKey(Key('universidade-programa-$i'))).height};
    expect(alturas, hasLength(1));
    expect(find.text('Observação 1'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).first, 'itu');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(requisicoesApi.last.url.queryParameters, containsPair('q', 'itu'));
  });

  testWidgets('mostra estado de erro quando o programa não existe', (tester) async {
    mockApiError('/programas/999', code: 'NOT_FOUND', status: 404);

    await pump(tester, 999);

    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });
}
