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

  testWidgets('mostra estado de erro quando o programa não existe', (tester) async {
    mockApiError('/programas/999', code: 'NOT_FOUND', status: 404);

    await pump(tester, 999);

    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });
}
