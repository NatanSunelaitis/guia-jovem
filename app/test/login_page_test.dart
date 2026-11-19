import 'package:app/features/auth/data/google_login.dart';
import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/google_login_falso.dart';
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

  group('Entrar com Google (RF05)', () {
    late GoogleLogin original;
    setUp(() => original = googleLogin);
    tearDown(() => googleLogin = original);

    testWidgets('sem GOOGLE_CLIENT_ID o botão não aparece', (tester) async {
      await pumpLogin(tester);

      expect(googleLogin.disponivel, isFalse);
      expect(find.text('Entrar com Google'), findsNothing);
      expect(find.text('OU'), findsNothing);
    });

    testWidgets('com o client ID o botão aparece', (tester) async {
      googleLogin = GoogleLoginFalso();
      await pumpLogin(tester);

      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(find.text('OU'), findsOneWidget);
    });

    testWidgets('envia o ID token para a API, entra e vai para a home', (tester) async {
      googleLogin = GoogleLoginFalso();
      mockAuthApiRotas({
        'POST /auth/google': RespostaFalsa(envelope({
          'accessToken': 'access-g',
          'refreshToken': 'refresh-g',
          'usuario': _usuarioAluno,
        })),
      });
      await pumpLogin(tester);

      await tester.tap(find.text('Entrar com Google'));
      await tester.pumpAndSettle();

      final enviadas = requisicoesAuthApi.where((r) => r.method == 'POST' && r.uri.path.endsWith('/auth/google'));
      expect(enviadas.single.data, {'idToken': 'id-token-do-google'});
      expect(sessionController.usuario!.email, 'ana@exemplo.com');
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('mostra a mensagem da API quando o token é recusado', (tester) async {
      googleLogin = GoogleLoginFalso();
      mockAuthApiRotas({
        'POST /auth/google': const RespostaFalsa(
          {
            'error': {'code': 'FORBIDDEN', 'message': 'Esta conta não pode ser acessada com o Google', 'details': <dynamic>[]},
          },
          status: 403,
        ),
      });
      await pumpLogin(tester);

      await tester.tap(find.text('Entrar com Google'));
      await tester.pumpAndSettle();

      expect(find.text('Esta conta não pode ser acessada com o Google'), findsOneWidget);
      expect(sessionController.autenticado, isFalse);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('mostra o aviso quando o Google não carrega', (tester) async {
      googleLogin = GoogleLoginFalso(falhar: true);
      mockAuthApiRotas({});
      await pumpLogin(tester);

      await tester.tap(find.text('Entrar com Google'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar o login com Google.'), findsOneWidget);
      expect(requisicoesAuthApi, isEmpty);
    });
  });
}
