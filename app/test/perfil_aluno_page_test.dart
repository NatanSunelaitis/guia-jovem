import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/features/perfil/presentation/perfil_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

final _aluno = UsuarioSessao(id: 1, nome: 'Ana Souza', email: 'ana@exemplo.com', tipoUsuario: TipoUsuario.aluno);
final _universidade = UsuarioSessao(id: 3, nome: 'Fatec', email: 'fatec@exemplo.com', tipoUsuario: TipoUsuario.universidade);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpPerfil(WidgetTester tester, {UsuarioSessao? usuario}) async {
    sessionController.redefinirParaTestes(usuario: usuario ?? _aluno);
    await pumpComRouter(tester, initialLocation: '/perfil', rotas: {'/perfil': (context) => const PerfilPage()});
    await tester.pumpAndSettle();
  }

  testWidgets('mostra iniciais, nome, e-mail e as ações da conta', (tester) async {
    mockAuthApiRotas({});
    await pumpPerfil(tester);

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
    expect(find.text('ana@exemplo.com'), findsOneWidget);
    for (final acao in ['Editar perfil', 'Alterar senha', 'Sair', 'Excluir conta']) {
      expect(find.text(acao), findsOneWidget);
    }
  });

  testWidgets('universidade e administrador continuam na página provisória', (tester) async {
    await pumpPerfil(tester, usuario: _universidade);

    expect(find.text('Meu perfil'), findsNothing);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('edita o nome com PATCH e o cartão mostra o nome novo', (tester) async {
    mockAuthApiRotas({
      'PATCH /usuarios/1': RespostaFalsa(envelope({'id': 1, 'nome': 'Ana Paula Souza', 'email': 'ana@exemplo.com'})),
    });
    await pumpPerfil(tester);

    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    expect(find.text('O e-mail não pode ser alterado.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '  Ana Paula Souza ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(requisicoesAuthApi.single.data, {'nome': 'Ana Paula Souza'});
    expect(find.text('Ana Paula Souza'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Dados atualizados.'), findsOneWidget);
    expect(sessionController.usuario!.nome, 'Ana Paula Souza');
  });

  testWidgets('nome vazio não chama a API', (tester) async {
    mockAuthApiRotas({});
    await pumpPerfil(tester);

    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome'), findsOneWidget);
    expect(requisicoesAuthApi, isEmpty);
  });

  testWidgets('erro da API ao salvar aparece no campo e mantém a edição', (tester) async {
    mockAuthApiRotas({
      'PATCH /usuarios/1': const RespostaFalsa(
        {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Dados inválidos',
            'details': [
              {'campo': 'nome', 'mensagem': 'O nome deve ter no máximo 100 caracteres'},
            ],
          },
        },
        status: 400,
      ),
    });
    await pumpPerfil(tester);

    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('O nome deve ter no máximo 100 caracteres'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);
  });

  testWidgets('cancelar a edição volta ao resumo sem salvar', (tester) async {
    mockAuthApiRotas({});
    await pumpPerfil(tester);

    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Outro nome');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(requisicoesAuthApi, isEmpty);
  });

  testWidgets('"Alterar senha" abre o componente de troca de senha', (tester) async {
    mockAuthApiRotas({});
    await pumpPerfil(tester);

    await tester.tap(find.text('Alterar senha'));
    await tester.pumpAndSettle();

    expect(find.text('Senha atual'), findsOneWidget);
    expect(find.text('Confirmar nova senha'), findsOneWidget);
  });

  testWidgets('"Sair" pede confirmação: cancelar mantém a sessão, confirmar encerra', (tester) async {
    mockAuthApiRotas({});
    await pumpPerfil(tester);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Tem certeza que deseja sair da sua conta?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(sessionController.autenticado, isTrue);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair').last);
    await tester.pumpAndSettle();
    expect(sessionController.autenticado, isFalse);
  });

  testWidgets('"Excluir conta" abre a confirmação com o aviso de irreversível', (tester) async {
    mockAuthApiRotas({});
    await pumpPerfil(tester);

    await tester.tap(find.text('Excluir conta'));
    await tester.pumpAndSettle();

    expect(find.text('Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.'), findsOneWidget);
  });
}
