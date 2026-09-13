import 'package:app/features/auth/presentation/cadastro_aluno_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

const _usuarioAluno = {
  'id': 2,
  'nome': 'Beatriz Lima',
  'email': 'bia@exemplo.com',
  'tipoUsuario': 'A',
  'fotoUrl': null,
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpCadastro(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/cadastro/aluno',
        rotas: {
          '/cadastro/aluno': (context) => const CadastroAlunoPage(),
          '/': (context) => const PaginaMarcadora('Home'),
          '/login': (context) => const PaginaMarcadora('Login'),
        },
      );

  Future<void> preencher(WidgetTester tester, {String nome = 'Beatriz Lima', String email = 'bia@exemplo.com', String senha = 'senha1234', String? confirmar}) async {
    await tester.enterText(find.byType(TextField).at(0), nome);
    await tester.enterText(find.byType(TextField).at(1), email);
    await tester.enterText(find.byType(TextField).at(2), senha);
    await tester.enterText(find.byType(TextField).at(3), confirmar ?? senha);
  }

  testWidgets('mostra erros de validação quando os campos estão vazios', (tester) async {
    await pumpCadastro(tester);

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome'), findsOneWidget);
    expect(find.text('Informe um e-mail válido'), findsOneWidget);
    expect(find.text('Informe uma senha com 7 ou mais caracteres'), findsOneWidget);
  });

  testWidgets('mostra erro quando as senhas não coincidem', (tester) async {
    await pumpCadastro(tester);

    await preencher(tester, confirmar: 'outrasenha');
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('As senhas não coincidem'), findsOneWidget);
  });

  testWidgets('cadastro com sucesso navega para a home', (tester) async {
    mockAuthApi({
      '/auth/register/aluno': envelope({
        'accessToken': 'access-2',
        'refreshToken': 'refresh-2',
        'usuario': _usuarioAluno,
      }),
    });

    await pumpCadastro(tester);
    await preencher(tester);
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('mostra a mensagem de erro geral quando a API falha', (tester) async {
    mockAuthApiError('/auth/register/aluno', message: 'Este e-mail já está em uso.');

    await pumpCadastro(tester);
    await preencher(tester);
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Este e-mail já está em uso.'), findsOneWidget);
  });

  testWidgets('link "entre por aqui" navega para o login', (tester) async {
    await pumpCadastro(tester);

    await tester.tap(find.text('entre por aqui'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}
