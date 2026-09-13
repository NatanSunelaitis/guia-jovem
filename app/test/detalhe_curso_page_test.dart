import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/cursos/presentation/detalhe_curso_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('mostra o detalhe do curso por id', (tester) async {
    mockApi({
      '/cursos/5': envelope({
        'id': 5,
        'nome': 'Administração',
        'areaCurso': 'Negócios',
        'notaMec': null,
        'modalidade': 'Presencial',
        'grau': 'Bacharelado',
        'duracaoSemestres': 8,
        'descricao': 'Descrição do curso',
        'universidade': {'id': 1, 'nomeFantasia': 'Fatec Sorocaba', 'logoUrl': null},
        'campus': [
          {'id': 10, 'nome': 'Fatec Sorocaba', 'cidade': 'Sorocaba', 'estado': 'SP', 'turno': 'Integral', 'vagas': 40},
        ],
      }),
    });

    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const DetalheCursoPage.porId(id: 5)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Descrição do curso'), findsOneWidget);
    expect(find.text('Fatec Sorocaba'), findsOneWidget);
  });

  testWidgets('mostra universidades por nome do curso', (tester) async {
    mockApi({
      '/cursos/nome/Farmácia': envelope({
        'nome': 'Farmácia',
        'universidades': [
          {
            'cursoId': 7,
            'universidade': {'id': 2, 'nomeFantasia': 'USP', 'logoUrl': null},
            'campus': [
              {'id': 3, 'nome': 'USP São Paulo', 'cidade': 'São Paulo', 'estado': 'SP'},
            ],
          },
        ],
      }),
    });

    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const DetalheCursoPage.porNome(nome: 'Farmácia')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Farmácia'), findsOneWidget);
    expect(find.text('USP'), findsOneWidget);
    expect(find.text('Em quais universidades este curso está disponível'), findsOneWidget);
  });
}
