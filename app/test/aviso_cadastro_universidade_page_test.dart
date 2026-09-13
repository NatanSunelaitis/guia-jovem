import 'package:app/features/auth/data/cadastro_universidade_state.dart';
import 'package:app/features/auth/presentation/aviso_cadastro_universidade_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/pump_with_router.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpAviso(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/cadastro/universidade',
        rotas: {
          '/cadastro/universidade': (context) => const AvisoCadastroUniversidadePage(),
          '/cadastro': (context) => const PaginaMarcadora('TipoCadastro'),
          '/cadastro/universidade/dados': (context) => const PaginaMarcadora('Passo1'),
        },
      );

  testWidgets('"Prosseguir" fica desabilitado até o checkbox ser marcado', (tester) async {
    await pumpAviso(tester);

    await tester.tap(find.text('Prosseguir'));
    await tester.pumpAndSettle();

    expect(find.text('Atenção!'), findsOneWidget);
    expect(find.text('Passo1'), findsNothing);
  });

  testWidgets('marcar o checkbox habilita "Prosseguir" e avança para o passo 1', (tester) async {
    await pumpAviso(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prosseguir'));
    await tester.pumpAndSettle();

    expect(find.text('Passo1'), findsOneWidget);
    expect(cadastroUniversidadeState.aceitouTermos, isTrue);
  });

  testWidgets('"Voltar" retorna para a escolha do tipo de cadastro', (tester) async {
    await pumpAviso(tester);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('TipoCadastro'), findsOneWidget);
  });
}
