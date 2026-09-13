import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/shared/layouts/public_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

UsuarioSessao _usuario({TipoUsuario tipo = TipoUsuario.aluno}) => UsuarioSessao(
      id: 1,
      nome: 'Ana Souza',
      email: 'ana@exemplo.com',
      tipoUsuario: tipo,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpLayout(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/',
        rotas: {
          '/': (context) => const PublicLayout(child: SizedBox()),
          '/login': (context) => const PaginaMarcadora('Login'),
          '/perfil': (context) => const PaginaMarcadora('Perfil'),
          '/painel-universidade': (context) => const PaginaMarcadora('PainelUniversidade'),
          '/admin': (context) => const PaginaMarcadora('PainelAdmin'),
        },
      );

  testWidgets('visitante: mostra "Entrar" e navega para o login', (tester) async {
    await pumpLayout(tester);

    expect(find.text('Entrar'), findsOneWidget);

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('logado (aluno): mostra o menu do avatar sem Painel Administrativo', (tester) async {
    sessionController.redefinirParaTestes(usuario: _usuario());
    await pumpLayout(tester);

    expect(find.text('Entrar'), findsNothing);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    expect(find.text('Visualizar Perfil'), findsOneWidget);
    expect(find.text('Painel Administrativo'), findsNothing);
    expect(find.text('Desligar'), findsOneWidget);
    expect(find.text('Excluir Conta'), findsOneWidget);
  });

  testWidgets('logado (universidade): o menu do avatar mostra o Painel Administrativo', (tester) async {
    sessionController.redefinirParaTestes(usuario: _usuario(tipo: TipoUsuario.universidade));
    await pumpLayout(tester);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    expect(find.text('Painel Administrativo'), findsOneWidget);

    await tester.tap(find.text('Painel Administrativo'));
    await tester.pumpAndSettle();

    expect(find.text('PainelUniversidade'), findsOneWidget);
  });

  testWidgets('"Visualizar Perfil" navega para /perfil', (tester) async {
    sessionController.redefinirParaTestes(usuario: _usuario());
    await pumpLayout(tester);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visualizar Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('"Desligar" pede confirmação antes de encerrar a sessão', (tester) async {
    sessionController.redefinirParaTestes(usuario: _usuario());
    await pumpLayout(tester);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desligar'));
    await tester.pumpAndSettle();

    expect(find.text('Tem certeza que deseja sair da sua conta?'), findsOneWidget);

    // Cancelar não encerra a sessão.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(sessionController.autenticado, isTrue);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desligar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(sessionController.autenticado, isFalse);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('"Excluir Conta" abre o diálogo de confirmação em vermelho', (tester) async {
    sessionController.redefinirParaTestes(usuario: _usuario());
    await pumpLayout(tester);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir Conta'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmação'), findsOneWidget);
    expect(find.text('Digite EXCLUIR para confirmar'), findsWidgets);

    mockAuthApi({'/usuarios/1': envelope(null)});

    await tester.enterText(find.byType(TextField), 'EXCLUIR');
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(sessionController.autenticado, isFalse);
  });
}
