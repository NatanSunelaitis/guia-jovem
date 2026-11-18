import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/features/painel_universidade/presentation/painel_universidade_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/cadastro_universidade_json.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

final _semNotificacoes =
    RespostaFalsa(envelope(<dynamic>[], {'page': 1, 'pageSize': 10, 'total': 0, 'totalPages': 1, 'naoLidas': 0}));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  group('Painel da universidade (situação do cadastro)', () {
    Future<void> pumpPainel(WidgetTester tester, Map<String, dynamic> cadastro) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /universidades/7/cadastro': RespostaFalsa(envelope(cadastro)),
      });
      sessionController.redefinirParaTestes(
        usuario: UsuarioSessao(
          id: 5,
          nome: 'Secretaria Fatec Itu',
          email: 'secretaria@fatecitu.edu.br',
          tipoUsuario: TipoUsuario.universidade,
          // A sessão guarda o status do login; o painel mostra o da API.
          universidade: UniversidadeDoUsuario(id: 7, status: 'P'),
        ),
      );
      await pumpComRouter(
        tester,
        initialLocation: '/painel-universidade',
        rotas: {
          '/painel-universidade': (context) => const PainelUniversidadePage(),
          '/universidades/:id': (context) => PaginaMarcadora('Página ${GoRouterState.of(context).pathParameters['id']}'),
        },
      );
      await tester.pumpAndSettle();
    }

    testWidgets('pendente: aguardando análise', (tester) async {
      await pumpPainel(tester, cadastroUniversidadeJson());

      expect(find.text('Cadastro em análise'), findsOneWidget);
      expect(find.textContaining('A análise leva até 15 dias'), findsOneWidget);
    });

    testWidgets('reprovada: mostra o motivo informado', (tester) async {
      await pumpPainel(tester, cadastroUniversidadeJson(status: 'R', motivoReprovacao: 'CNPJ não confere'));

      expect(find.text('Cadastro reprovado'), findsOneWidget);
      expect(find.text('Motivo informado pela equipe'), findsOneWidget);
      expect(find.text('CNPJ não confere'), findsOneWidget);
    });

    testWidgets('inativa', (tester) async {
      await pumpPainel(tester, cadastroUniversidadeJson(status: 'I', aprovadoEm: '2026-11-11T12:00:00.000Z'));

      expect(find.text('Universidade inativa'), findsOneWidget);
      expect(find.textContaining('não aparece no site'), findsOneWidget);
    });

    testWidgets('aprovada: página publicada com o link para a página pública', (tester) async {
      await pumpPainel(tester, cadastroUniversidadeJson(status: 'A', aprovadoEm: '2026-11-11T12:00:00.000Z'));

      expect(find.text('Página publicada'), findsOneWidget);
      expect(find.textContaining('desde 11/11/2026'), findsOneWidget);
      await tester.tap(find.text('Ver página pública'));
      await tester.pumpAndSettle();
      expect(find.text('Página 7'), findsOneWidget);
    });
  });
}
