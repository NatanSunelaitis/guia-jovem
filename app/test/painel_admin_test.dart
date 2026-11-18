import 'package:app/features/admin/presentation/painel_admin_page.dart';
import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/features/notificacoes/domain/notificacao.dart';
import 'package:app/features/notificacoes/presentation/notificacoes_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/cadastro_universidade_json.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

final _admin = UsuarioSessao(id: 99, nome: 'Equipe Guia Jovem', email: 'admin@guiajovem.com.br', tipoUsuario: TipoUsuario.admin);

final _semNotificacoes =
    RespostaFalsa(envelope(<dynamic>[], {'page': 1, 'pageSize': 10, 'total': 0, 'totalPages': 1, 'naoLidas': 0}));

Map<String, dynamic> _pagina(List<Map<String, dynamic>> itens, {int pendentes = 0}) => envelope(
      itens,
      {'page': 1, 'pageSize': 20, 'total': itens.length, 'totalPages': 1, 'pendentes': pendentes},
    );

Map<String, dynamic> _itemUniversidade({int id = 7, String nome = 'Fatec Itu', String status = 'P'}) => {
      'id': id,
      'nomeFantasia': nome,
      'razaoSocial': 'Faculdade $nome',
      'cnpj': '12345678000199',
      'natureza': 'P',
      'status': status,
      'cidade': 'Itu',
      'estado': 'SP',
      'criadoEm': '2026-11-10T12:00:00.000Z',
      'aprovadoEm': null,
    };

Map<String, dynamic> _usuario({required int id, required String nome, String tipo = 'A', bool ativo = true}) => {
      'id': id,
      'nome': nome,
      'email': '${nome.split(' ').first.toLowerCase()}@exemplo.com',
      'tipoUsuario': tipo,
      'fotoUrl': null,
      'ativo': ativo,
      'criadoEm': '2026-03-12T12:00:00.000Z',
    };

RespostaFalsa _erro(String code, String message, {int status = 409}) => RespostaFalsa(
      {
        'error': {'code': code, 'message': message, 'details': <dynamic>[]},
      },
      status: status,
    );

Iterable<RequestLike> _requisicoes(String metodo, String sufixo) => requisicoesAuthApi
    .where((r) => r.method == metodo && r.uri.path.endsWith(sufixo))
    .map((r) => RequestLike(r.uri.queryParameters, r.data));

class RequestLike {
  RequestLike(this.query, this.corpo);
  final Map<String, String> query;
  final dynamic corpo;
}

Future<void> _pumpAdmin(WidgetTester tester, String local) async {
  sessionController.redefinirParaTestes(usuario: _admin);
  await pumpComRouter(
    tester,
    initialLocation: local,
    rotas: {
      '/admin/universidades/:id': (context) => PainelAdminPage(
            secao: SecaoAdmin.universidades,
            universidadeId: int.parse(GoRouterState.of(context).pathParameters['id']!),
          ),
      '/admin/:secao': (context) => PainelAdminPage(
            key: ValueKey(GoRouterState.of(context).pathParameters['secao']),
            secao: SecaoAdmin.doCaminho(GoRouterState.of(context).pathParameters['secao']),
          ),
      '/sugestoes/:id': (context) => PaginaMarcadora('Sugestão ${GoRouterState.of(context).pathParameters['id']}'),
    },
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  group('Estrutura do painel', () {
    testWidgets('mostra as oito abas do protótipo, todas prontas, e troca de seção', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /universidades/administracao': RespostaFalsa(_pagina([])),
        'GET /cursos/administracao': RespostaFalsa(_pagina([])),
      });

      await _pumpAdmin(tester, '/admin/universidades');

      expect(find.text('Painel de Administração'), findsOneWidget);
      for (final rotulo in [
        'Dashboard',
        'Usuários',
        'Universidades',
        'Cursos',
        'Financiamento',
        'Bolsas de Estudo',
        'Programas de Entrada',
        'Sugestões',
      ]) {
        expect(find.text(rotulo), findsWidgets);
      }
      expect(find.textContaining('em breve'), findsNothing);

      await tester.tap(find.text('Cursos'));
      await tester.pumpAndSettle();
      expect(find.text('Novo curso'), findsOneWidget);
    });

    test('sem seção na URL (ou desconhecida), o painel abre no Dashboard', () {
      expect(SecaoAdmin.doCaminho(null), SecaoAdmin.dashboard);
      expect(SecaoAdmin.doCaminho('inexistente'), SecaoAdmin.dashboard);
      expect(SecaoAdmin.doCaminho('bolsas'), SecaoAdmin.bolsas);
    });

    testWidgets('seção Sugestões traz a lista de recebidas e abre o detalhe', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes': RespostaFalsa(
          envelope([
            {
              'id': 12,
              'titulo': 'Filtro por cidade',
              'texto': 'Seria bom filtrar por cidade.',
              'status': 'EM_ANALISE',
              'resposta': null,
              'criadoEm': '2026-11-10T12:00:00.000Z',
              'avaliadoEm': null,
              'universidade': null,
              'autor': {'nome': 'Ana Souza'},
            },
          ], {'page': 1, 'pageSize': 20, 'total': 1, 'totalPages': 1}),
        ),
      });

      await _pumpAdmin(tester, '/admin/sugestoes');

      expect(find.text('Filtro por cidade'), findsOneWidget);
      await tester.tap(find.text('Avaliar'));
      await tester.pumpAndSettle();
      expect(find.text('Sugestão 12'), findsOneWidget);
    });

    test('a notificação de universidade abre o cadastro (admin) ou o painel (universidade)', () {
      final notificacao = Notificacao.fromJson({
        'id': 1,
        'tipo': 'UNIVERSIDADE_PENDENTE',
        'titulo': 'Nova universidade aguardando aprovação',
        'mensagem': 'Fatec Itu enviou um cadastro para análise.',
        'referenciaTipo': 'universidade',
        'referenciaId': 7,
        'lida': false,
        'criadoEm': '2026-11-10T12:00:00.000Z',
      });

      expect(destinoDaNotificacao(notificacao, TipoUsuario.admin), '/admin/universidades/7');
      expect(destinoDaNotificacao(notificacao, TipoUsuario.universidade), '/painel-universidade');
      expect(destinoDaNotificacao(notificacao, TipoUsuario.aluno), isNull);
    });
  });

  group('Seção Universidades', () {
    testWidgets('abre nas pendentes com o contador, troca de status, busca e abre o cadastro', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /universidades/administracao': RespostaFalsa(_pagina([_itemUniversidade()], pendentes: 2)),
        'GET /universidades/7/cadastro': RespostaFalsa(envelope(cadastroUniversidadeJson())),
      });

      await _pumpAdmin(tester, '/admin/universidades');

      expect(find.text('Pendentes de aprovação (2)'), findsOneWidget);
      expect(find.text('Fatec Itu'), findsOneWidget);
      expect(find.text('Itu / SP'), findsOneWidget);
      expect(_requisicoes('GET', '/universidades/administracao').last.query['status'], 'P');

      await tester.tap(find.text('Inativas'));
      await tester.pumpAndSettle();
      expect(_requisicoes('GET', '/universidades/administracao').last.query['status'], 'I');

      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();
      expect(_requisicoes('GET', '/universidades/administracao').last.query.containsKey('status'), isFalse);

      await tester.enterText(find.byType(TextField).first, 'Itu');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(_requisicoes('GET', '/universidades/administracao').last.query['busca'], 'Itu');

      await tester.tap(find.text('Ver cadastro'));
      await tester.pumpAndSettle();
      expect(find.text('Faculdade de Tecnologia de Itu'), findsOneWidget);
    });

    testWidgets('cadastro pendente mostra os dados e aprova depois da confirmação', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /universidades/7/cadastro': RespostaFalsa(envelope(cadastroUniversidadeJson())),
        'POST /universidades/7/aprovar': RespostaFalsa(
          envelope(cadastroUniversidadeJson(status: 'A', aprovadoEm: '2026-11-17T12:00:00.000Z')),
        ),
      });

      await _pumpAdmin(tester, '/admin/universidades/7');

      expect(find.text('Pendente'), findsOneWidget);
      expect(find.text('12.345.678/0001-99'), findsOneWidget);
      expect(find.text('Campus Itu'), findsOneWidget);
      expect(find.text('Av. Tiradentes, 1211, Centro, Itu / SP, CEP 13309-640'), findsOneWidget);
      expect(find.text('ENEM, ProUni'), findsOneWidget);
      expect(find.text('secretaria@fatecitu.edu.br'), findsOneWidget);
      expect(find.text('Inativar'), findsNothing);

      await tester.tap(find.text('Aprovar'));
      await tester.pumpAndSettle();
      expect(find.text('Aprovar cadastro'), findsOneWidget);
      // Cancelar não chama a API.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(_requisicoes('POST', '/aprovar'), isEmpty);

      await tester.tap(find.text('Aprovar'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Aprovar')));
      await tester.pumpAndSettle();

      expect(_requisicoes('POST', '/universidades/7/aprovar'), hasLength(1));
      expect(find.text('Universidade aprovada. A instituição foi avisada.'), findsOneWidget);
      expect(find.text('Aprovada'), findsOneWidget);
      expect(find.text('Inativar'), findsOneWidget);
    });

    testWidgets('reprovar exige o motivo e envia o texto digitado', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /universidades/7/cadastro': RespostaFalsa(envelope(cadastroUniversidadeJson())),
        'POST /universidades/7/reprovar': RespostaFalsa(
          envelope(cadastroUniversidadeJson(status: 'R', motivoReprovacao: 'CNPJ não confere')),
        ),
      });

      await _pumpAdmin(tester, '/admin/universidades/7');

      await tester.tap(find.text('Reprovar'));
      await tester.pumpAndSettle();
      expect(find.text('Reprovar cadastro'), findsOneWidget);

      final confirmar = find.descendant(of: find.byType(Dialog), matching: find.text('Reprovar'));
      await tester.tap(confirmar);
      await tester.pumpAndSettle();
      expect(find.text('Informe o motivo da reprovação'), findsOneWidget);
      expect(_requisicoes('POST', '/reprovar'), isEmpty);

      await tester.enterText(find.byKey(const Key('motivo-reprovacao')), '  CNPJ não confere  ');
      await tester.tap(confirmar);
      await tester.pumpAndSettle();

      final enviado = _requisicoes('POST', '/universidades/7/reprovar').single;
      expect(enviado.corpo, {'motivo': 'CNPJ não confere'});
      expect(find.text('Reprovada'), findsOneWidget);
      expect(find.text('Motivo da reprovação: CNPJ não confere'), findsOneWidget);
      // Reprovada ainda pode ser aprovada depois.
      expect(find.text('Aprovar'), findsOneWidget);
    });

    testWidgets('aprovada pode ser inativada e inativa pode ser reativada', (tester) async {
      var status = 'A';
      mockAuthApiRotasDinamicas({
        'GET /notificacoes': (_) => _semNotificacoes,
        'GET /universidades/7/cadastro': (_) =>
            RespostaFalsa(envelope(cadastroUniversidadeJson(status: status, aprovadoEm: '2026-11-11T12:00:00.000Z'))),
        'POST /universidades/7/inativar': (_) {
          status = 'I';
          return RespostaFalsa(envelope(cadastroUniversidadeJson(status: 'I', aprovadoEm: '2026-11-11T12:00:00.000Z')));
        },
        'POST /universidades/7/reativar': (_) {
          status = 'A';
          return RespostaFalsa(envelope(cadastroUniversidadeJson(status: 'A', aprovadoEm: '2026-11-11T12:00:00.000Z')));
        },
      });

      await _pumpAdmin(tester, '/admin/universidades/7');

      await tester.tap(find.text('Inativar'));
      await tester.pumpAndSettle();
      expect(find.text('Inativar universidade'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Inativar')));
      await tester.pumpAndSettle();
      expect(find.text('Inativa'), findsOneWidget);

      await tester.tap(find.text('Reativar'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Reativar')));
      await tester.pumpAndSettle();
      expect(find.text('Aprovada'), findsOneWidget);
      expect(_requisicoes('POST', '/inativar'), hasLength(1));
      expect(_requisicoes('POST', '/reativar'), hasLength(1));
    });

    testWidgets('inativa que nunca foi aprovada não mostra "Reativar"', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /universidades/7/cadastro': RespostaFalsa(envelope(cadastroUniversidadeJson(status: 'I'))),
      });

      await _pumpAdmin(tester, '/admin/universidades/7');

      expect(find.text('Inativa'), findsOneWidget);
      expect(find.text('Reativar'), findsNothing);
    });

    testWidgets('decisão já tomada por outro administrador: mostra a mensagem e o status atual', (tester) async {
      var leituras = 0;
      mockAuthApiRotasDinamicas({
        'GET /notificacoes': (_) => _semNotificacoes,
        'GET /universidades/7/cadastro': (_) {
          leituras++;
          return RespostaFalsa(
            envelope(cadastroUniversidadeJson(status: leituras == 1 ? 'P' : 'A', aprovadoEm: leituras == 1 ? null : '2026-11-17T12:00:00.000Z')),
          );
        },
        'POST /universidades/7/aprovar': (_) =>
            _erro('STATUS_INVALIDO', 'Só é possível aprovar uma universidade pendente ou reprovada'),
      });

      await _pumpAdmin(tester, '/admin/universidades/7');
      await tester.tap(find.text('Aprovar'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Aprovar')));
      await tester.pumpAndSettle();

      expect(find.text('Só é possível aprovar uma universidade pendente ou reprovada'), findsOneWidget);
      expect(find.text('Aprovada'), findsOneWidget);
    });
  });

  group('Seção Usuários', () {
    testWidgets('lista, filtra por perfil e situação, e inativa depois da confirmação', (tester) async {
      mockAuthApiRotasDinamicas({
        'GET /notificacoes': (_) => _semNotificacoes,
        'GET /usuarios': (_) => RespostaFalsa(
              envelope([
                _usuario(id: 1, nome: 'Mayara Santos'),
                _usuario(id: 99, nome: 'Equipe Guia Jovem', tipo: 'D'),
              ], {'page': 1, 'pageSize': 20, 'total': 2, 'totalPages': 1}),
            ),
        'PATCH /usuarios/1': (_) => RespostaFalsa(envelope(_usuario(id: 1, nome: 'Mayara Santos', ativo: false))),
      });

      await _pumpAdmin(tester, '/admin/usuarios');

      expect(find.text('Mayara Santos'), findsOneWidget);
      expect(find.text('Aluno'), findsWidgets);
      expect(find.text('Ativo'), findsNWidgets(2));
      // A própria conta não tem o botão (sai pelo menu do avatar).
      expect(find.text('Sua conta'), findsOneWidget);
      expect(find.text('Inativar'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filtro-perfil')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrador').last);
      await tester.pumpAndSettle();
      expect(_requisicoes('GET', '/usuarios').last.query['tipoUsuario'], 'D');

      await tester.tap(find.byKey(const Key('filtro-situacao')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inativos').last);
      await tester.pumpAndSettle();
      expect(_requisicoes('GET', '/usuarios').last.query, containsPair('ativo', 'false'));

      await tester.enterText(find.byType(TextField).first, 'mayara');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(_requisicoes('GET', '/usuarios').last.query['busca'], 'mayara');

      await tester.tap(find.text('Inativar'));
      await tester.pumpAndSettle();
      expect(find.text('Inativar conta'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Inativar')));
      await tester.pumpAndSettle();

      expect(_requisicoes('PATCH', '/usuarios/1').single.corpo, {'ativo': false});
      expect(find.text('Conta inativada.'), findsOneWidget);
      expect(find.text('Inativo'), findsOneWidget);
      expect(find.text('Ativar'), findsOneWidget);
    });

    testWidgets('a regra do último administrador mostra o bloqueio com a mensagem da API', (tester) async {
      const mensagem = 'Esta é a única conta de administrador ativa. Ative ou cadastre outro administrador antes '
          'de inativar, excluir ou mudar o perfil desta conta.';
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /usuarios': RespostaFalsa(
          envelope([_usuario(id: 50, nome: 'Outra Admin', tipo: 'D')], {'page': 1, 'pageSize': 20, 'total': 1, 'totalPages': 1}),
        ),
        'PATCH /usuarios/50': _erro('ULTIMO_ADMINISTRADOR', mensagem),
      });

      await _pumpAdmin(tester, '/admin/usuarios');
      await tester.tap(find.text('Inativar'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Inativar')));
      await tester.pumpAndSettle();

      expect(find.text('Ação não permitida'), findsOneWidget);
      expect(find.text(mensagem), findsOneWidget);
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();
      expect(find.text('Ativo'), findsOneWidget);
    });
  });
}
