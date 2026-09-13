import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/universidades/presentation/pesquisa_universidades_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const PesquisaUniversidadesPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('lista universidades encontradas', (tester) async {
    mockApi({
      '/universidades': envelope(
        [
          {
            'id': 1,
            'nomeFantasia': 'Fatec Sorocaba',
            'logoUrl': null,
            'natureza': 'P',
            'mediaAvaliacao': null,
            'totalAvaliacoes': 0,
            'cidade': 'Sorocaba',
            'estado': 'SP',
            'programas': <Map<String, dynamic>>[],
          },
        ],
        {'page': 1, 'pageSize': 20, 'total': 1, 'totalPages': 1},
      ),
    });

    await pump(tester);

    expect(find.text('Fatec Sorocaba'), findsOneWidget);
    expect(find.text('1 universidade(s) encontrada(s)'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há resultados', (tester) async {
    mockApi({
      '/universidades': envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1}),
    });

    await pump(tester);

    expect(find.text('Nenhuma universidade encontrada'), findsOneWidget);
  });
}
