import 'package:app/features/auth/presentation/redefinir_senha_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpRedefinir(WidgetTester tester, {String? token}) => pumpComRouter(
        tester,
        initialLocation: token == null ? '/redefinir-senha' : '/redefinir-senha?token=$token',
        rotas: {
          '/redefinir-senha': (context) {
            final uriToken = GoRouterState.of(context).uri.queryParameters['token'];
            return RedefinirSenhaPage(token: uriToken);
          },
          '/recuperar-senha': (context) => const PaginaMarcadora('Recuperar'),
          '/login': (context) => const PaginaMarcadora('Login'),
        },
      );

  testWidgets('sem token na URL, mostra o estado de link inválido', (tester) async {
    await pumpRedefinir(tester);

    expect(find.text('Link inválido ou expirado'), findsOneWidget);

    await tester.tap(find.text('Solicitar novo link'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar'), findsOneWidget);
  });

  testWidgets('com token, mostra erros de validação da senha', (tester) async {
    await pumpRedefinir(tester, token: 'token-valido');

    await tester.enterText(find.byType(TextField).at(0), '123');
    await tester.enterText(find.byType(TextField).at(1), '456');
    await tester.tap(find.text('Redefinir senha').last);
    await tester.pumpAndSettle();

    expect(find.text('Informe uma senha com 7 ou mais caracteres'), findsOneWidget);
    expect(find.text('As senhas não coincidem'), findsOneWidget);
  });

  testWidgets('com token e senha válida, mostra a tela de sucesso', (tester) async {
    mockAuthApi({'/auth/reset-password': envelope(null)});

    await pumpRedefinir(tester, token: 'token-valido');

    await tester.enterText(find.byType(TextField).at(0), 'novaSenha123');
    await tester.enterText(find.byType(TextField).at(1), 'novaSenha123');
    await tester.tap(find.text('Redefinir senha').last);
    await tester.pumpAndSettle();

    expect(find.text('Senha redefinida'), findsOneWidget);

    await tester.tap(find.text('Ir para o login'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('com token, mostra o erro geral quando a API rejeita o token', (tester) async {
    mockAuthApiError('/auth/reset-password', message: 'Link de redefinição expirado.');

    await pumpRedefinir(tester, token: 'token-expirado');

    await tester.enterText(find.byType(TextField).at(0), 'novaSenha123');
    await tester.enterText(find.byType(TextField).at(1), 'novaSenha123');
    await tester.tap(find.text('Redefinir senha').last);
    await tester.pumpAndSettle();

    expect(find.text('Link de redefinição expirado.'), findsOneWidget);
  });
}
