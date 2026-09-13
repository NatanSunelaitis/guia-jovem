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

  testWidgets('lista cursos agrupados por nome, com contagem de universidades', (tester) async {
    mockApi({
      '/cursos/destaques': envelope([
        {'nome': 'Administração', 'areaCurso': 'Negócios', 'totalOfertas': 2},
      ]),
    });

    await pump(tester);

    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Negócios'), findsOneWidget);
    expect(find.text('2 universidades'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há cursos', (tester) async {
    mockApi({
      '/cursos/destaques': envelope(<dynamic>[]),
    });

    await pump(tester);

    expect(find.text('Nenhum curso encontrado'), findsOneWidget);
  });
}
