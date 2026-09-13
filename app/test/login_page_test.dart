import 'package:app/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

const _usuarioAluno = {
  'id': 1,
  'nome': 'Ana Souza',
  'email': 'ana@exemplo.com',
  'tipoUsuario': 'A',
  'fotoUrl': null,
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpLogin(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/login',
        rotas: {
          '/login': (context) => const LoginPage(),
          '/': (context) => const PaginaMarcadora('Home'),
          '/cadastro': (context) => const PaginaMarcadora('Cadastro'),
          '/recuperar-senha': (context) => const PaginaMarcadora('Recuperar'),
        },
      );

  testWidgets('mostra os campos de e-mail, senha e o botão de acesso', (tester) async {
    await pumpLogin(tester);

    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Acessar minha conta'), findsOneWidget);
  });

  testWidgets('login com sucesso navega para a home', (tester) async {
    mockAuthApi({
      '/auth/login': envelope({
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'usuario': _usuarioAluno,
      }),
    });

    await pumpLogin(tester);

    await tester.enterText(find.byType(TextField).at(0), 'ana@exemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha1234');
    await tester.tap(find.text('Acessar minha conta'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('mostra a mensagem de erro quando as credenciais são inválidas', (tester) async {
    mockAuthApiError('/auth/login', message: 'E-mail ou senha inválidos.');

    await pumpLogin(tester);

    await tester.enterText(find.byType(TextField).at(0), 'ana@exemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'senhaerrada');
    await tester.tap(find.text('Acessar minha conta'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('link "Criar uma conta" navega para a tela de cadastro', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastro'), findsOneWidget);
  });

  testWidgets('link "Esqueci minha senha" navega para recuperação', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar'), findsOneWidget);
  });
}
