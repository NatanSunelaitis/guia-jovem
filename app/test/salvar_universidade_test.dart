import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/features/universidades/presentation/detalhe_universidade_page.dart';
import 'package:app/features/universidades/presentation/pesquisa_universidades_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_api.dart' hide envelope;
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

final _aluno = UsuarioSessao(id: 1, nome: 'Ana Souza', email: 'ana@exemplo.com', tipoUsuario: TipoUsuario.aluno);
final _universidade = UsuarioSessao(id: 3, nome: 'Fatec', email: 'fatec@exemplo.com', tipoUsuario: TipoUsuario.universidade);

Map<String, dynamic> _detalhe({bool salva = false}) => {
      'id': 1,
      'nomeFantasia': 'Fatec Sorocaba',
      'razaoSocial': 'Faculdade de Tecnologia de Sorocaba',
      'descricao': null,
      'logoUrl': null,
      'natureza': 'P',
      'linkPagina': null,
      'linkSimulados': null,
      'mediaAvaliacao': null,
      'totalAvaliacoes': 0,
      'enderecoPrincipal': null,
      'campus': <dynamic>[],
      'programas': {'ENTRADA': <dynamic>[], 'FINANCIAMENTO': <dynamic>[], 'BOLSA': <dynamic>[]},
      'minhaAvaliacao': null,
      'salva': salva,
    };

Map<String, dynamic> _card(int id, String nome, {bool salva = false}) => {
      'id': id,
      'nomeFantasia': nome,
      'logoUrl': null,
      'natureza': 'P',
      'mediaAvaliacao': '4.50',
      'totalAvaliacoes': 3,
      'cidade': 'Sorocaba',
      'estado': 'SP',
      'programas': <dynamic>[],
      'salva': salva,
    };

const _metaUmaPagina = {'page': 1, 'pageSize': 20, 'total': 2, 'totalPages': 1};
const _avaliacoesVazias = {
  'data': <dynamic>[],
  'meta': {'page': 1, 'pageSize': 20, 'total': 0, 'totalPages': 1},
};

Widget _login(BuildContext context) => Text('Login para ${(GoRouterState.of(context).extra as Map?)?['redirect']}');

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  group('no detalhe da universidade', () {
    Future<void> pumpDetalhe(WidgetTester tester) => pumpComRouter(
          tester,
          initialLocation: '/universidades/1',
          rotas: {
            '/universidades/1': (context) => const DetalheUniversidadePage(id: 1),
            '/login': _login,
          },
        );

    testWidgets('aluno salva e remove a faculdade', (tester) async {
      sessionController.redefinirParaTestes(usuario: _aluno);
      mockApi({'/universidades/1/avaliacoes': _avaliacoesVazias});
      mockAuthApiRotas({
        'GET /universidades/1': RespostaFalsa(envelope(_detalhe())),
        'POST /favoritos/universidades': RespostaFalsa(envelope({'universidadeId': 1, 'salva': true}), status: 201),
        'DELETE /favoritos/universidades/1': RespostaFalsa(envelope({'sucesso': true, 'salva': false})),
      });

      await pumpDetalhe(tester);
      await tester.tap(find.byTooltip('Salvar faculdade'));
      await tester.pumpAndSettle();

      final post = requisicoesAuthApi.singleWhere((r) => r.method == 'POST');
      expect(post.data, {'universidadeId': 1});
      expect(find.byTooltip('Remover das salvas'), findsOneWidget);
      expect(find.text('Faculdade salva.'), findsOneWidget);

      await tester.tap(find.byTooltip('Remover das salvas'));
      await tester.pumpAndSettle();

      expect(requisicoesAuthApi.where((r) => r.method == 'DELETE').single.path, '/favoritos/universidades/1');
      expect(find.byTooltip('Salvar faculdade'), findsOneWidget);
    });

    testWidgets('abre como salva quando a API diz que o aluno já salvou', (tester) async {
      sessionController.redefinirParaTestes(usuario: _aluno);
      mockApi({'/universidades/1/avaliacoes': _avaliacoesVazias});
      mockAuthApiRotas({'GET /universidades/1': RespostaFalsa(envelope(_detalhe(salva: true)))});

      await pumpDetalhe(tester);

      expect(find.byTooltip('Remover das salvas'), findsOneWidget);
    });

    testWidgets('visitante vai ao login e volta para o detalhe', (tester) async {
      mockApi({
        '/universidades/1/avaliacoes': _avaliacoesVazias,
        '/universidades/1': envelope(_detalhe()),
      });

      await pumpDetalhe(tester);
      await tester.tap(find.byTooltip('Salvar faculdade'));
      await tester.pumpAndSettle();

      expect(find.text('Login para /universidades/1'), findsOneWidget);
    });

    testWidgets('perfil Universidade recebe aviso e nada é gravado', (tester) async {
      sessionController.redefinirParaTestes(usuario: _universidade);
      mockApi({'/universidades/1/avaliacoes': _avaliacoesVazias});
      mockAuthApiRotas({'GET /universidades/1': RespostaFalsa(envelope(_detalhe()))});

      await pumpDetalhe(tester);
      await tester.tap(find.byTooltip('Salvar faculdade'));
      await tester.pump();

      expect(find.text('Disponível apenas para contas de aluno.'), findsOneWidget);
      expect(requisicoesAuthApi.where((r) => r.method != 'GET'), isEmpty);
    });
  });

  group('nos cards da pesquisa', () {
    Future<void> pumpPesquisa(WidgetTester tester) => pumpComRouter(
          tester,
          initialLocation: '/universidades',
          rotas: {
            '/universidades': (context) => const PesquisaUniversidadesPage(),
            '/login': _login,
          },
        );

    testWidgets('mostra quais estão salvas e alterna sem refazer a pesquisa', (tester) async {
      sessionController.redefinirParaTestes(usuario: _aluno);
      mockAuthApiRotas({
        'GET /universidades': RespostaFalsa(
          envelope([_card(1, 'Fatec Sorocaba', salva: true), _card(2, 'Unesp Sorocaba')], _metaUmaPagina),
        ),
        'POST /favoritos/universidades': RespostaFalsa(envelope({'universidadeId': 2, 'salva': true}), status: 201),
        'DELETE /favoritos/universidades/1': RespostaFalsa(envelope({'sucesso': true, 'salva': false})),
      });

      await pumpPesquisa(tester);

      expect(find.byTooltip('Remover das salvas'), findsOneWidget);
      expect(find.byTooltip('Salvar faculdade'), findsOneWidget);

      await tester.tap(find.byTooltip('Salvar faculdade'));
      await tester.pumpAndSettle();
      expect(requisicoesAuthApi.singleWhere((r) => r.method == 'POST').data, {'universidadeId': 2});
      expect(find.byTooltip('Remover das salvas'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Remover das salvas').first);
      await tester.pumpAndSettle();
      expect(requisicoesAuthApi.singleWhere((r) => r.method == 'DELETE').path, '/favoritos/universidades/1');
      expect(find.byTooltip('Salvar faculdade'), findsOneWidget);

      // A pesquisa só foi feita uma vez.
      expect(requisicoesAuthApi.where((r) => r.method == 'GET'), hasLength(1));
    });

    testWidgets('visitante que clica em salvar vai ao login e volta para a pesquisa', (tester) async {
      mockApi({'/universidades': envelope([_card(1, 'Fatec Sorocaba')], _metaUmaPagina)});

      await pumpPesquisa(tester);
      await tester.tap(find.byTooltip('Salvar faculdade'));
      await tester.pumpAndSettle();

      expect(find.text('Login para /universidades?sort=nome'), findsOneWidget);
    });
  });
}
