import 'package:app/core/theme/gj_theme.dart';
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
    expect(find.text('Programa de Entrada'), findsOneWidget);
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
    expect(find.text('Financiamento Estudantil'), findsOneWidget);
  });

  testWidgets('mostra estado de erro quando o programa não existe', (tester) async {
    mockApiError('/programas/999', code: 'NOT_FOUND', status: 404);

    await pump(tester, 999);

    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });
}
