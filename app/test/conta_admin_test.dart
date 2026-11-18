import 'package:app/core/router/app_router.dart';
import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/painel_admin.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  group('Conta do administrador', () {
    testWidgets('mostra nome e e-mail, com editar nome, alterar senha e sair', (tester) async {
      mockAuthApiRotas({'GET /notificacoes': semNotificacoes});
      await pumpPainelAdmin(tester, '/admin/conta');

      expect(find.text('Conta'), findsWidgets);
      expect(find.text('Equipe Guia Jovem'), findsWidgets);
      expect(find.text('admin@guiajovem.com.br'), findsOneWidget);
      expect(find.text('Editar nome'), findsOneWidget);
      expect(find.text('Alterar senha'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('edita o nome e atualiza a sessão', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'PATCH /usuarios/99': RespostaFalsa(envelope({'id': 99, 'nome': 'Natan Administrador'})),
      });
      await pumpPainelAdmin(tester, '/admin/conta');

      await tester.tap(find.text('Editar nome'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Nome'), 'Natan Administrador');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(requisicoes('PATCH', '/usuarios/99').single.corpo, {'nome': 'Natan Administrador'});
      expect(sessionController.usuario!.nome, 'Natan Administrador');
      expect(find.text('Nome atualizado.'), findsOneWidget);
      expect(find.text('Editar nome'), findsOneWidget);
    });

    testWidgets('nome vazio não é enviado', (tester) async {
      mockAuthApiRotas({'GET /notificacoes': semNotificacoes});
      await pumpPainelAdmin(tester, '/admin/conta');

      await tester.tap(find.text('Editar nome'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Nome'), '   ');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome'), findsOneWidget);
      expect(requisicoes('PATCH', '/usuarios/99'), isEmpty);
    });

    testWidgets('alterar senha abre o componente reutilizável e sair pede confirmação', (tester) async {
      mockAuthApiRotas({'GET /notificacoes': semNotificacoes});
      await pumpPainelAdmin(tester, '/admin/conta');

      await tester.tap(find.text('Alterar senha'));
      await tester.pumpAndSettle();
      expect(find.text('Senha atual'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(find.text('Tem certeza que deseja sair da sua conta?'), findsOneWidget);
      await confirmarNoDialogo(tester, 'Cancelar');
      expect(sessionController.autenticado, isTrue);
    });
  });

  group('/perfil', () {
    test('o administrador vai para a seção Conta do painel', () {
      sessionController.redefinirParaTestes(usuario: adminDeTeste);
      expect(redirecionarPelaSessao('/perfil'), '/admin/conta');
    });

    test('a universidade vai para a Conta do painel dela e o aluno fica no perfil', () {
      sessionController.redefinirParaTestes(
        usuario: UsuarioSessao(id: 5, nome: 'Fatec', email: 'u@exemplo.com', tipoUsuario: TipoUsuario.universidade),
      );
      expect(redirecionarPelaSessao('/perfil'), '/painel-universidade/conta');

      sessionController.redefinirParaTestes(
        usuario: UsuarioSessao(id: 6, nome: 'Ana', email: 'a@exemplo.com', tipoUsuario: TipoUsuario.aluno),
      );
      expect(redirecionarPelaSessao('/perfil'), isNull);
      expect(redirecionarPelaSessao('/admin/conta'), '/perfil');
    });

    test('sem sessão, o perfil e a conta do painel pedem login', () {
      sessionController.redefinirParaTestes();
      expect(redirecionarPelaSessao('/perfil'), '/login');
      expect(redirecionarPelaSessao('/admin/conta'), '/login');
    });
  });
}

