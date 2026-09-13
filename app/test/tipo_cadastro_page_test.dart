import 'package:app/features/auth/presentation/tipo_cadastro_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/pump_with_router.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpTipoCadastro(WidgetTester tester, {Size tamanho = const Size(1440, 1800)}) => pumpComRouter(
        tester,
        initialLocation: '/cadastro',
        tamanhoTela: tamanho,
        rotas: {
          '/cadastro': (context) => const TipoCadastroPage(),
          '/cadastro/aluno': (context) => const PaginaMarcadora('Marcador Aluno'),
          '/cadastro/universidade': (context) => const PaginaMarcadora('Marcador Universidade'),
          '/login': (context) => const PaginaMarcadora('Login'),
        },
      );

  testWidgets('modal desktop mostra as duas opções de cadastro', (tester) async {
    await pumpTipoCadastro(tester);

    expect(find.text('Qual tipo de cadastro gostaria de fazer?'), findsOneWidget);
    expect(find.text('Sou estudante'), findsOneWidget);
    expect(find.text('Represento uma instituição'), findsOneWidget);
  });

  testWidgets('desktop: tocar em "Aluno" navega para o cadastro de aluno', (tester) async {
    await pumpTipoCadastro(tester);

    await tester.tap(find.text('Aluno'));
    await tester.pumpAndSettle();

    expect(find.text('Marcador Aluno'), findsOneWidget);
  });

  testWidgets('desktop: tocar em "Universidade" navega para o aviso de universidade', (tester) async {
    await pumpTipoCadastro(tester);

    await tester.tap(find.text('Universidade'));
    await tester.pumpAndSettle();

    expect(find.text('Marcador Universidade'), findsOneWidget);
  });

  testWidgets('mobile: mostra a folha inferior com as mesmas opções', (tester) async {
    await pumpTipoCadastro(tester, tamanho: const Size(390, 844));

    expect(find.text('Qual tipo de cadastro gostaria de fazer?'), findsOneWidget);
    expect(find.text('Sou estudante'), findsOneWidget);
    expect(find.text('Represento uma instituição'), findsOneWidget);
  });
}
