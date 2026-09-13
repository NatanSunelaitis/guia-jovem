import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const HomePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('mostra os destaques de universidades, programas e cursos', (tester) async {
    mockApi({
      '/universidades/destaques': envelope([
        {
          'id': 1,
          'nomeFantasia': 'Fatec Sorocaba',
          'logoUrl': null,
          'natureza': 'P',
          'mediaAvaliacao': '5',
          'totalAvaliacoes': 1,
          'cidade': 'Sorocaba',
          'estado': 'SP',
          'programas': [
            {'id': 1, 'nome': 'ENEM', 'sigla': 'ENEM', 'tipo': 'ENTRADA'},
          ],
        },
      ]),
      '/programas/destaques': envelope([
        {
          'id': 1,
          'nome': 'Exame Nacional do Ensino Médio',
          'sigla': 'ENEM',
          'tipo': 'ENTRADA',
          'descricao': 'Descrição',
          'imagemUrl': null,
          'universidadeId': null,
        },
      ]),
      '/cursos/destaques': envelope([
        {'nome': 'Administração', 'totalOfertas': 3},
      ]),
    });

    await pump(tester);

    expect(find.text('Fatec Sorocaba'), findsOneWidget);
    expect(find.text('Exame Nacional do Ensino Médio'), findsOneWidget);
    expect(find.text('Administração'), findsOneWidget);
  });

  testWidgets('mostra estado de erro quando a API falha', (tester) async {
    mockApiError('/universidades/destaques');

    await pump(tester);

    expect(find.text('Não foi possível carregar'), findsWidgets);
  });
}
