import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/features/auth/presentation/widgets/alterar_senha_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

final _aluno = UsuarioSessao(id: 1, nome: 'Ana Souza', email: 'ana@exemplo.com', tipoUsuario: TipoUsuario.aluno);

RespostaFalsa _erro(String code, String message, {List<Map<String, String>> details = const [], int status = 400}) =>
    RespostaFalsa(
      {
        'error': {'code': code, 'message': message, 'details': details},
      },
      status: status,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> abrirDialogo(WidgetTester tester) async {
    sessionController.redefinirParaTestes(usuario: _aluno);
    await pumpComRouter(
      tester,
      initialLocation: '/',
      rotas: {
        '/': (context) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => mostrarDialogoAlterarSenha(context),
                  child: const Text('Abrir'),
                ),
              ),
            ),
      },
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> preencher(WidgetTester tester, {String atual = 'senha-antiga', String nova = 'senha-nova-1', String? confirmacao}) async {
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), atual);
    await tester.enterText(campos.at(1), nova);
    await tester.enterText(campos.at(2), confirmacao ?? nova);
  }

  testWidgets('troca a senha com PATCH, avisa e encerra a sessão', (tester) async {
    mockAuthApiRotas({'PATCH /usuarios/1/senha': RespostaFalsa(envelope({'sucesso': true}))});

    await abrirDialogo(tester);
    await preencher(tester);
    await tester.tap(find.text('Alterar senha').last);
    await tester.pumpAndSettle();

    final patch = requisicoesAuthApi.single;
    expect(patch.method, 'PATCH');
    expect(patch.data, {'senhaAtual': 'senha-antiga', 'novaSenha': 'senha-nova-1', 'confirmacao': 'senha-nova-1'});
    expect(find.text('Senha atual'), findsNothing);
    expect(find.text('Senha alterada. Entre novamente com a nova senha.'), findsOneWidget);
    expect(sessionController.autenticado, isFalse);
  });

  testWidgets('senha atual incorreta aparece no campo e o diálogo continua aberto', (tester) async {
    mockAuthApiRotas({
      'PATCH /usuarios/1/senha': _erro('SENHA_ATUAL_INVALIDA', 'Senha atual incorreta'),
    });

    await abrirDialogo(tester);
    await preencher(tester, atual: 'errada');
    await tester.tap(find.text('Alterar senha').last);
    await tester.pumpAndSettle();

    expect(find.text('Senha atual incorreta'), findsOneWidget);
    expect(find.text('Senha atual'), findsOneWidget);
    expect(sessionController.autenticado, isTrue);
  });

  testWidgets('erros de validação da API aparecem em cada campo', (tester) async {
    mockAuthApiRotas({
      'PATCH /usuarios/1/senha': _erro('VALIDATION_ERROR', 'Dados inválidos', details: [
        {'campo': 'novaSenha', 'mensagem': 'Informe uma senha com 7 ou mais caracteres'},
        {'campo': 'confirmacao', 'mensagem': 'A confirmação deve ser igual à nova senha'},
      ]),
    });

    await abrirDialogo(tester);
    await preencher(tester, nova: '123', confirmacao: '456');
    await tester.tap(find.text('Alterar senha').last);
    await tester.pumpAndSettle();

    expect(find.text('Informe uma senha com 7 ou mais caracteres'), findsOneWidget);
    expect(find.text('A confirmação deve ser igual à nova senha'), findsOneWidget);
    expect(find.text('Dados inválidos'), findsNothing);
  });

  testWidgets('conta só com Google mostra a mensagem geral da API', (tester) async {
    mockAuthApiRotas({
      'PATCH /usuarios/1/senha': _erro(
        'SEM_SENHA_DEFINIDA',
        'Esta conta usa login com Google e ainda não tem senha definida',
      ),
    });

    await abrirDialogo(tester);
    await preencher(tester);
    await tester.tap(find.text('Alterar senha').last);
    await tester.pumpAndSettle();

    expect(find.text('Esta conta usa login com Google e ainda não tem senha definida'), findsOneWidget);
  });

  testWidgets('cancelar fecha sem chamar a API', (tester) async {
    mockAuthApiRotas({});

    await abrirDialogo(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Senha atual'), findsNothing);
    expect(requisicoesAuthApi, isEmpty);
    expect(sessionController.autenticado, isTrue);
  });
}
