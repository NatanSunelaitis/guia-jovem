import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/campus/presentation/detalhe_campus_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const DetalheCampusPage(id: 10)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('mostra o detalhe do campus com os cursos', (tester) async {
    mockApi({
      '/campus/10': envelope({
        'id': 10,
        'nome': 'Fatec Sorocaba',
        'telefoneCelular': null,
        'telefoneFixo': '(15) 3232-0000',
        'emailCampus': null,
        'principal': true,
        'universidade': {'id': 1, 'nomeFantasia': 'Fatec Sorocaba'},
        'endereco': {
          'logradouro': 'Av. X',
          'numero': '100',
          'complemento': null,
          'bairro': 'Centro',
          'cidade': 'Sorocaba',
          'estado': 'SP',
          'cep': '18000000',
        },
        'cursos': [
          {'id': 5, 'nome': 'Administração', 'areaCurso': 'Negócios', 'grau': 'Bacharelado', 'turno': 'Integral', 'vagas': 40},
        ],
      }),
    });

    await pump(tester);

    expect(find.text('Fatec Sorocaba'), findsWidgets);
    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Lista de cursos oferecidos neste campus'), findsOneWidget);
  });

  testWidgets('mostra estado de erro quando o campus não existe', (tester) async {
    mockApiError('/campus/10', code: 'NOT_FOUND', status: 404);

    await pump(tester);

    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });
}
