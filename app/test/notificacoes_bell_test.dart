import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/shared/layouts/public_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

final _aluno = UsuarioSessao(id: 1, nome: 'Ana Souza', email: 'ana@exemplo.com', tipoUsuario: TipoUsuario.aluno);

Map<String, dynamic> _notificacao({required int id, bool lida = false, String titulo = 'Sua sugestão foi aprovada'}) =>
    {
      'id': id,
      'tipo': 'SUGESTAO_AVALIADA',
      'titulo': titulo,
      'mensagem': 'Fatec Itu respondeu "Mais vagas no noturno".',
      'referenciaTipo': 'sugestao',
      'referenciaId': 12,
      'lida': lida,
      'criadoEm': DateTime.now().toUtc().subtract(const Duration(hours: 2)).toIso8601String(),
    };

Iterable<String> _metodos(String metodo) => requisicoesAuthApi.where((r) => r.method == metodo).map((r) => r.path);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  group('Sino de notificações', () {
    Future<void> pumpHeader(WidgetTester tester, {UsuarioSessao? usuario}) async {
      sessionController.redefinirParaTestes(usuario: usuario);
      await pumpComRouter(
        tester,
        initialLocation: '/',
        rotas: {
          '/': (context) => const PublicLayout(child: SizedBox()),
          '/login': (context) => const PaginaMarcadora('Login'),
          '/sugestoes/:id': (context) => PaginaMarcadora('Sugestão ${GoRouterState.of(context).pathParameters['id']}'),
        },
      );
      await tester.pumpAndSettle();
    }

    testWidgets('visitante não vê o sino', (tester) async {
      await pumpHeader(tester);
      expect(find.byTooltip('Notificações'), findsNothing);
    });

    testWidgets('logado: mostra o contador de não lidas e a lista ao abrir', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': RespostaFalsa(
          envelope(
            [_notificacao(id: 40), _notificacao(id: 41, lida: true, titulo: 'Nova sugestão recebida')],
            {'page': 1, 'pageSize': 10, 'total': 2, 'totalPages': 1, 'naoLidas': 3},
          ),
        ),
      });

      await pumpHeader(tester, usuario: _aluno);

      expect(find.byTooltip('Notificações'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(requisicoesAuthApi.single.queryParameters['pageSize'], '10');

      await tester.tap(find.byTooltip('Notificações'));
      await tester.pumpAndSettle();

      expect(find.text('Sua sugestão foi aprovada'), findsOneWidget);
      expect(find.text('Nova sugestão recebida'), findsOneWidget);
      expect(find.text('há 2 h'), findsNWidgets(2));
      expect(find.text('Marcar todas como lidas'), findsOneWidget);
    });

    testWidgets('clicar numa notificação marca como lida e abre a sugestão', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': RespostaFalsa(
          envelope([_notificacao(id: 40)], {'page': 1, 'pageSize': 10, 'total': 1, 'totalPages': 1, 'naoLidas': 1}),
        ),
        'PATCH /notificacoes/40/lida': RespostaFalsa(envelope(_notificacao(id: 40, lida: true))),
      });

      await pumpHeader(tester, usuario: _aluno);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byTooltip('Notificações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sua sugestão foi aprovada'));
      await tester.pumpAndSettle();

      expect(_metodos('PATCH'), ['/notificacoes/40/lida']);
      expect(find.text('Sugestão 12'), findsOneWidget);
    });

    testWidgets('"Marcar todas como lidas" zera o contador', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': RespostaFalsa(
          envelope([_notificacao(id: 40)], {'page': 1, 'pageSize': 10, 'total': 1, 'totalPages': 1, 'naoLidas': 1}),
        ),
        'PATCH /notificacoes/lidas': RespostaFalsa(envelope({'atualizadas': 1})),
      });

      await pumpHeader(tester, usuario: _aluno);
      await tester.tap(find.byTooltip('Notificações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar todas como lidas'));
      await tester.pumpAndSettle();

      expect(_metodos('PATCH'), ['/notificacoes/lidas']);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('falha ao buscar notificações deixa o sino sem contador', (tester) async {
      mockAuthApiRotas({});

      await pumpHeader(tester, usuario: _aluno);

      expect(find.byTooltip('Notificações'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
