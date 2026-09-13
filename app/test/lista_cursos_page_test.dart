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

  testWidgets('lista cursos encontrados', (tester) async {
    mockApi({
      '/cursos': envelope(
        [
          {
            'id': 5,
            'nome': 'Administração',
            'areaCurso': 'Negócios',
            'modalidade': 'Presencial',
            'grau': 'Bacharelado',
            'universidade': {'id': 1, 'nomeFantasia': 'Fatec Sorocaba', 'logoUrl': null},
          },
        ],
        {'page': 1, 'pageSize': 20, 'total': 1, 'totalPages': 1},
      ),
    });

    await pump(tester);

    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Fatec Sorocaba'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há cursos', (tester) async {
    mockApi({
      '/cursos': envelope(<dynamic>[], {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1}),
    });

    await pump(tester);

    expect(find.text('Nenhum curso encontrado'), findsOneWidget);
  });
}
