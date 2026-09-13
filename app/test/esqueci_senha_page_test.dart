import 'package:app/features/auth/presentation/esqueci_senha_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpEsqueciSenha(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/recuperar-senha',
        rotas: {
          '/recuperar-senha': (context) => const EsqueciSenhaPage(),
          '/login': (context) => const PaginaMarcadora('Login'),
        },
      );

  testWidgets('mostra sempre a mesma mensagem neutra quando a API responde com sucesso', (tester) async {
    mockAuthApi({'/auth/forgot-password': envelope(null)});

    await pumpEsqueciSenha(tester);
    await tester.enterText(find.byType(TextField), 'aluno@exemplo.com');
    await tester.tap(find.text('Enviar link de recuperação'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Se houver uma conta com esse e-mail'),
      findsOneWidget,
    );
  });

  testWidgets('mostra a mesma mensagem neutra mesmo quando a API falha (RNF: nunca revela se o e-mail existe)', (tester) async {
    mockAuthApiError('/auth/forgot-password', message: 'E-mail não encontrado');

    await pumpEsqueciSenha(tester);
    await tester.enterText(find.byType(TextField), 'inexistente@exemplo.com');
    await tester.tap(find.text('Enviar link de recuperação'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Se houver uma conta com esse e-mail'), findsOneWidget);
    expect(find.text('E-mail não encontrado'), findsNothing);
  });

  testWidgets('link "Voltar para o login" navega para o login', (tester) async {
    await pumpEsqueciSenha(tester);

    await tester.tap(find.text('Voltar para o login'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}
