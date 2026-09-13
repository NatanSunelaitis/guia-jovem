import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/programas/presentation/pesquisa_programas_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const PesquisaProgramasPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('lista programas encontrados', (tester) async {
    mockApi({
      '/programas': envelope(
        [
          {
            'id': 1,
            'nome': 'Exame Nacional do Ensino Médio',
            'sigla': 'ENEM',
            'tipo': 'ENTRADA',
            'descricao': 'Descrição',
            'imagemUrl': null,
            'universidadeId': null,
          },
        ],
        {'page': 1, 'pageSize': 20, 'total': 1, 'totalPages': 1},
      ),
    });

    await pump(tester);

    expect(find.text('Exame Nacional do Ensino Médio'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há programas', (tester) async {
    mockApi({
      '/programas': envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1}),
    });

    await pump(tester);

    expect(find.text('Nenhum programa encontrado'), findsOneWidget);
  });
}
