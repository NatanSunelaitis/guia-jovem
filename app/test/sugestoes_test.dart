import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/features/painel_universidade/presentation/painel_universidade_page.dart';
import 'package:app/features/perfil/presentation/perfil_page.dart';
import 'package:app/features/sugestoes/presentation/detalhe_sugestao_page.dart';
import 'package:app/features/sugestoes/presentation/nova_sugestao_dialog.dart';
import 'package:app/features/sugestoes/presentation/sugestoes_recebidas_page.dart';
import 'package:app/features/sugestoes/presentation/widgets/sugestao_card.dart';
import 'package:app/features/perfil/presentation/widgets/historico_sugestoes_secao.dart';
import 'package:app/shared/widgets/gj_button.dart';
import 'package:app/shared/widgets/gj_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/cadastro_universidade_json.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

final _aluno = UsuarioSessao(id: 1, nome: 'Ana Souza', email: 'ana@exemplo.com', tipoUsuario: TipoUsuario.aluno);
final _universidade = UsuarioSessao(
  id: 3,
  nome: 'Fatec Itu',
  email: 'contato@fatecitu.edu.br',
  tipoUsuario: TipoUsuario.universidade,
  universidade: UniversidadeDoUsuario(id: 7, status: 'A'),
);

Map<String, dynamic> _pagina(List<Map<String, dynamic>> itens, {int page = 1, int totalPages = 1}) =>
    envelope(itens, {'page': page, 'pageSize': 20, 'total': itens.length, 'totalPages': totalPages});

Map<String, dynamic> _sugestao({
  int id = 12,
  String titulo = 'Mais vagas no noturno',
  String status = 'EM_ANALISE',
  String texto = 'Abrir mais turmas no período noturno ajudaria quem trabalha.',
  String? resposta,
  String? avaliadoEm,
  Map<String, dynamic>? universidade = const {'id': 7, 'nomeFantasia': 'Fatec Itu'},
  Map<String, dynamic>? autor,
  bool? podeAvaliar,
}) =>
    {
      'id': id,
      'titulo': titulo,
      'texto': texto,
      'status': status,
      'resposta': resposta,
      'criadoEm': '2026-11-10T12:00:00.000Z',
      'avaliadoEm': avaliadoEm,
      'universidade': universidade,
      if (autor != null) 'autor': autor,
      if (podeAvaliar != null) 'podeAvaliar': podeAvaliar,
    };

Map<String, dynamic> _universidadeResumo(int id, String nome) => {
      'id': id,
      'nomeFantasia': nome,
      'logoUrl': null,
      'natureza': 'P',
      'mediaAvaliacao': null,
      'totalAvaliacoes': 0,
      'cidade': 'Itu',
      'estado': 'SP',
      'programas': <dynamic>[],
    };

final _semNotificacoes =
    RespostaFalsa(envelope(<dynamic>[], {'page': 1, 'pageSize': 10, 'total': 0, 'totalPages': 1, 'naoLidas': 0}));

/// Campo de texto de um GJInput (o rótulo fica fora do TextField).
Finder _campo(String rotulo) =>
    find.descendant(of: find.widgetWithText(GJInput, rotulo), matching: find.byType(TextField));

Iterable<String> _metodos(String metodo) => requisicoesAuthApi.where((r) => r.method == metodo).map((r) => r.path);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  group('Histórico do aluno (aba Sugestões)', () {
    Future<void> pumpHistorico(WidgetTester tester) async {
      sessionController.redefinirParaTestes(usuario: _aluno);
      await pumpComRouter(
        tester,
        initialLocation: '/perfil?aba=sugestoes',
        rotas: {
          '/perfil': (context) => const PerfilPage(),
          '/sugestoes/:id': (context) => PaginaMarcadora('Detalhe ${GoRouterState.of(context).pathParameters['id']}'),
        },
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lista status, destino, resposta e data da avaliação vindos da API', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes/minhas': RespostaFalsa(_pagina([
          _sugestao(
            status: 'APROVADA',
            resposta: 'Vamos abrir uma turma em 2027.',
            avaliadoEm: '2026-11-12T12:00:00.000Z',
          ),
          _sugestao(id: 13, titulo: 'Filtro por cidade', universidade: null),
        ])),
      });

      await pumpHistorico(tester);

      expect(find.text('Mais vagas no noturno'), findsOneWidget);
      expect(find.text('Aprovada'), findsOneWidget);
      expect(find.text('10/11/2026 · Para: Fatec Itu'), findsOneWidget);
      expect(find.text('Resposta: Vamos abrir uma turma em 2027.'), findsOneWidget);
      expect(find.text('Respondida em 12/11/2026'), findsOneWidget);
      expect(find.text('Em análise'), findsOneWidget);
      expect(find.text('10/11/2026 · Para: Equipe Guia Jovem'), findsOneWidget);

      await tester.tap(find.text('Filtro por cidade'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhe 13'), findsOneWidget);
    });

    // Tamanhos de tela conferidos: notebook comum e o menor desktop usual.
    for (final tela in const [Size(1366, 768), Size(1280, 720)]) {
      for (final quantidade in const [1, 3]) {
        testWidgets(
            'em ${tela.width.toInt()} x ${tela.height.toInt()}, com $quantidade item(ns), cada card ocupa a largura da aba, '
            'alinhado ao botão "Nova sugestão"', (tester) async {
          tester.view.physicalSize = tela;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          mockAuthApiRotas({
            'GET /notificacoes': _semNotificacoes,
            'GET /sugestoes/minhas': RespostaFalsa(_pagina([
              // Textos curtos: sem a correção, o card ficava com a largura do conteúdo.
              for (var i = 0; i < quantidade; i++) _sugestao(id: 20 + i, titulo: 'T$i', texto: 'Curto.', universidade: null),
            ])),
          });

          await pumpHistorico(tester);

          final botao = tester.getRect(find.widgetWithText(GJButton, 'Nova sugestão'));
          final secao = tester.getRect(find.byType(HistoricoSugestoesSecao));
          final cards = find.byType(SugestaoCard);
          expect(cards, findsNWidgets(quantidade));
          for (var i = 0; i < quantidade; i++) {
            final card = tester.getRect(cards.at(i));
            expect(card.left, moreOrLessEquals(secao.left), reason: 'card $i não começa na margem da aba');
            expect(card.right, moreOrLessEquals(botao.right), reason: 'card $i não termina no botão');
          }
        });
      }
    }

    testWidgets('texto longo sem espaços quebra dentro do card, em até três linhas com reticências', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final palavra = 'Pneumoultramicroscopicossilicovulcanoconiotico' * 6;
      const link = 'https://www.exemplo.com.br/um/caminho/muito/comprido/sem/espacos/para/testar/a/quebra/da/linha/'
          'dentro/do/card/de/sugestao/do/perfil/do/aluno/no/guia/jovem/com/varias/pastas/e/mais/pastas/e/ainda/mais';
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes/minhas': RespostaFalsa(_pagina([
          _sugestao(
            titulo: palavra,
            texto: '$link $palavra $palavra',
            status: 'APROVADA',
            resposta: '$link$palavra$palavra',
            avaliadoEm: '2026-11-12T12:00:00.000Z',
          ),
        ])),
      });

      await pumpHistorico(tester);

      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(SugestaoCard));
      for (final chave in const ['sugestao-card-titulo', 'sugestao-card-texto', 'sugestao-card-resposta']) {
        final texto = find.byKey(Key(chave));
        final caixa = tester.getRect(texto);
        expect(caixa.right, lessThanOrEqualTo(card.right), reason: '$chave estourou a largura do card');
        final paragrafo = tester.renderObject<RenderParagraph>(find.descendant(of: texto, matching: find.byType(RichText)));
        // Quebrou em várias linhas (não cortou numa linha só) e parou em três.
        expect(paragrafo.size.height, greaterThan(paragrafo.text.style!.fontSize! * 2), reason: '$chave não quebrou');
        // O texto completo é mais alto que o mostrado: parou em três linhas.
        final completo = TextPainter(text: paragrafo.text, textDirection: TextDirection.ltr, textScaleFactor: paragrafo.textScaleFactor)
          ..layout(maxWidth: paragrafo.size.width);
        expect(completo.height, greaterThan(paragrafo.size.height), reason: '$chave não parou em três linhas');
        expect((tester.widget<Text>(texto)).maxLines, 3);
      }
    });

    testWidgets('sem sugestões, mostra o estado vazio com o atalho para enviar', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes/minhas': RespostaFalsa(_pagina([])),
      });

      await pumpHistorico(tester);

      expect(find.text('Você ainda não enviou sugestões'), findsOneWidget);
      expect(find.text('Enviar uma sugestão'), findsOneWidget);
    });

    testWidgets('erro mostra "Tentar novamente"', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes/minhas': const RespostaFalsa(
          {
            'error': {'code': 'INTERNAL_ERROR', 'message': 'Erro interno.', 'details': <dynamic>[]},
          },
          status: 500,
        ),
      });

      await pumpHistorico(tester);

      expect(find.text('Não foi possível carregar'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('envia sugestão para uma universidade buscada pelo nome e recarrega a lista', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes/minhas': RespostaFalsa(_pagina([])),
        'GET /universidades': RespostaFalsa(_pagina([_universidadeResumo(7, 'Fatec Itu')])),
        'POST /sugestoes': RespostaFalsa(envelope(_sugestao()), status: 201),
      });

      await pumpHistorico(tester);
      await tester.tap(find.text('Nova sugestão'));
      await tester.pumpAndSettle();

      // Validação local antes de chamar a API.
      await tester.tap(find.text('Enviar sugestão'));
      await tester.pumpAndSettle();
      expect(find.text('Dê um título com pelo menos 3 caracteres'), findsOneWidget);
      expect(find.text('Escreva a sugestão com pelo menos 10 caracteres'), findsOneWidget);
      expect(_metodos('POST'), isEmpty);

      await tester.enterText(_campo('Título'), 'Mais vagas no noturno');
      await tester.enterText(find.byKey(const Key('texto-sugestao')), 'Abrir mais turmas no período noturno.');
      await tester.enterText(_campo('Universidade (opcional)'), 'Fatec');
      await tester.pump(atrasoBuscaUniversidade);
      await tester.pumpAndSettle();

      final busca = requisicoesAuthApi.lastWhere((r) => r.path == '/universidades');
      expect(busca.queryParameters['q'], 'Fatec');

      await tester.tap(find.text('Fatec Itu'));
      await tester.pumpAndSettle();
      expect(find.text('Para: Fatec Itu'), findsOneWidget);

      await tester.tap(find.text('Enviar sugestão'));
      await tester.pumpAndSettle();

      final envio = requisicoesAuthApi.singleWhere((r) => r.method == 'POST');
      expect(envio.data, {
        'titulo': 'Mais vagas no noturno',
        'texto': 'Abrir mais turmas no período noturno.',
        'universidadeId': 7,
      });
      expect(find.text('Nova sugestão'), findsOneWidget); // o diálogo fechou; sobra o botão da aba
      expect(find.textContaining('Sugestão enviada para Fatec Itu'), findsOneWidget);
      expect(requisicoesAuthApi.where((r) => r.path == '/sugestoes/minhas'), hasLength(2));
    });

    testWidgets('sem universidade, envia para a equipe e mostra os erros da API por campo', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes/minhas': RespostaFalsa(_pagina([])),
        'POST /sugestoes': const RespostaFalsa(
          {
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Dados inválidos',
              'details': [
                {'campo': 'titulo', 'mensagem': 'O título deve ter no máximo 100 caracteres'},
              ],
            },
          },
          status: 400,
        ),
      });

      await pumpHistorico(tester);
      await tester.tap(find.text('Nova sugestão'));
      await tester.pumpAndSettle();

      await tester.enterText(_campo('Título'), 'Filtro por cidade');
      await tester.enterText(find.byKey(const Key('texto-sugestao')), 'Seria ótimo filtrar pela cidade.');
      await tester.tap(find.text('Enviar sugestão'));
      await tester.pumpAndSettle();

      final envio = requisicoesAuthApi.singleWhere((r) => r.method == 'POST');
      expect((envio.data as Map).containsKey('universidadeId'), isFalse);
      expect(find.text('O título deve ter no máximo 100 caracteres'), findsOneWidget);
    });
  });

  group('Avaliação pelo destinatário', () {
    Future<void> pumpDetalhe(WidgetTester tester, {required UsuarioSessao usuario}) async {
      sessionController.redefinirParaTestes(usuario: usuario);
      await pumpComRouter(
        tester,
        initialLocation: '/sugestoes/12',
        rotas: {
          '/sugestoes/12': (context) => const DetalheSugestaoPage(id: 12),
          '/sugestoes-recebidas': (context) => const PaginaMarcadora('Recebidas'),
          '/perfil': (context) => const PaginaMarcadora('Perfil'),
        },
      );
      await tester.pumpAndSettle();
    }

    testWidgets('universidade reprova com resposta obrigatória e vê o resultado', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes/12': RespostaFalsa(envelope(_sugestao(autor: {'nome': 'Ana Souza'}, podeAvaliar: true))),
        'PATCH /sugestoes/12/status': RespostaFalsa(
          envelope(
            _sugestao(
              status: 'REPROVADA',
              resposta: 'Não há turma noturna prevista.',
              avaliadoEm: '2026-11-13T12:00:00.000Z',
              autor: {'nome': 'Ana Souza'},
              podeAvaliar: false,
            ),
          ),
        ),
      });

      await pumpDetalhe(tester, usuario: _universidade);

      expect(find.text('Enviada em 10/11/2026 · De: Ana Souza · Para: Fatec Itu'), findsOneWidget);
      expect(find.text('Avaliar sugestão'), findsOneWidget);

      await tester.tap(find.text('Reprovar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar avaliação'));
      await tester.pumpAndSettle();
      expect(find.text('Escreva a resposta para o autor'), findsOneWidget);
      expect(_metodos('PATCH'), isEmpty);

      await tester.enterText(find.byKey(const Key('resposta-sugestao')), '  Não há turma noturna prevista. ');
      await tester.tap(find.text('Enviar avaliação'));
      await tester.pumpAndSettle();

      final avaliacao = requisicoesAuthApi.singleWhere((r) => r.method == 'PATCH');
      expect(avaliacao.data, {'status': 'REPROVADA', 'resposta': 'Não há turma noturna prevista.'});
      expect(find.text('Avaliação enviada. O autor foi notificado.'), findsOneWidget);
      expect(find.text('Avaliar sugestão'), findsNothing);
      expect(find.text('Reprovada'), findsOneWidget);
      expect(find.text('Não há turma noturna prevista.'), findsOneWidget);
      expect(find.text('Respondida em 13/11/2026'), findsOneWidget);

      await tester.tap(find.text('Voltar para sugestões recebidas'));
      await tester.pumpAndSettle();
      expect(find.text('Recebidas'), findsOneWidget);
    });

    testWidgets('avaliação feita por outra pessoa antes (409): mostra a avaliação que valeu', (tester) async {
      // A primeira leitura vem em análise; depois do 409, já avaliada.
      var leituras = 0;
      mockAuthApiRotasDinamicas({
        'GET /notificacoes': (_) => _semNotificacoes,
        'GET /sugestoes/12': (_) => RespostaFalsa(
              leituras++ == 0
                  ? envelope(_sugestao(autor: {'nome': 'Ana Souza'}, podeAvaliar: true))
                  : envelope(
                      _sugestao(
                          status: 'APROVADA', resposta: 'Aprovada pela coordenação.', autor: {'nome': 'Ana Souza'}),
                    ),
            ),
        'PATCH /sugestoes/12/status': (_) => const RespostaFalsa(
              {
                'error': {
                  'code': 'SUGESTAO_JA_AVALIADA',
                  'message': 'Esta sugestão já foi avaliada',
                  'details': <dynamic>[],
                },
              },
              status: 409,
            ),
      });

      await pumpDetalhe(tester, usuario: _universidade);
      await tester.tap(find.text('Aprovar'));
      await tester.enterText(find.byKey(const Key('resposta-sugestao')), 'Ótima ideia.');
      await tester.tap(find.text('Enviar avaliação'));
      await tester.pumpAndSettle();

      expect(find.text('Esta sugestão já foi avaliada'), findsOneWidget);
      expect(find.text('Aprovada pela coordenação.'), findsOneWidget);
      expect(find.text('Avaliar sugestão'), findsNothing);
    });

    testWidgets('autor vê a própria sugestão em análise, sem o formulário', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes/12': RespostaFalsa(envelope(_sugestao(podeAvaliar: false))),
      });

      await pumpDetalhe(tester, usuario: _aluno);

      expect(find.text('Ainda em análise. Você recebe uma notificação quando houver resposta.'), findsOneWidget);
      expect(find.text('Avaliar sugestão'), findsNothing);

      await tester.tap(find.text('Voltar para o perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('sugestão de terceiros (403) mostra que está indisponível', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes/12': const RespostaFalsa(
          {
            'error': {'code': 'FORBIDDEN', 'message': 'Acesso não permitido', 'details': <dynamic>[]},
          },
          status: 403,
        ),
      });

      await pumpDetalhe(tester, usuario: _aluno);

      expect(find.text('Sugestão indisponível'), findsOneWidget);
    });
  });

  group('Sugestões recebidas', () {
    Future<void> pumpRecebidas(WidgetTester tester) async {
      sessionController.redefinirParaTestes(usuario: _universidade);
      await pumpComRouter(
        tester,
        initialLocation: '/sugestoes-recebidas',
        rotas: {
          '/sugestoes-recebidas': (context) => const SugestoesRecebidasPage(),
          '/sugestoes/:id': (context) => PaginaMarcadora('Sugestão ${GoRouterState.of(context).pathParameters['id']}'),
        },
      );
      await tester.pumpAndSettle();
    }

    testWidgets('abre em "Em análise", filtra por status e leva à avaliação', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes': RespostaFalsa(_pagina([
          _sugestao(autor: {'nome': 'Ana Souza'})
        ])),
      });

      await pumpRecebidas(tester);

      expect(find.text('Sugestões que estudantes enviaram para a sua universidade.'), findsOneWidget);
      expect(find.text('10/11/2026 · De: Ana Souza'), findsOneWidget);
      final primeira = requisicoesAuthApi.lastWhere((r) => r.path == '/sugestoes');
      expect(primeira.queryParameters['status'], 'EM_ANALISE');

      await tester.tap(find.text('Aprovadas'));
      await tester.pumpAndSettle();
      expect(requisicoesAuthApi.lastWhere((r) => r.path == '/sugestoes').queryParameters['status'], 'APROVADA');

      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();
      expect(
          requisicoesAuthApi.lastWhere((r) => r.path == '/sugestoes').queryParameters.containsKey('status'), isFalse);

      await tester.tap(find.text('Avaliar'));
      await tester.pumpAndSettle();
      expect(find.text('Sugestão 12'), findsOneWidget);
    });

    testWidgets('carrega a próxima página com "Carregar mais"', (tester) async {
      mockAuthApiRotasDinamicas({
        'GET /notificacoes': (_) => _semNotificacoes,
        'GET /sugestoes': (requisicao) => requisicao.queryParameters['page'] == '2'
            ? RespostaFalsa(_pagina([_sugestao(id: 20, titulo: 'Segunda página')], page: 2, totalPages: 2))
            : RespostaFalsa(_pagina([_sugestao(titulo: 'Primeira página')], totalPages: 2)),
      });

      await pumpRecebidas(tester);
      expect(find.text('Primeira página'), findsOneWidget);

      await tester.ensureVisible(find.text('Carregar mais'));
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();

      expect(find.text('Primeira página'), findsOneWidget);
      expect(find.text('Segunda página'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
    });

    testWidgets('sem sugestões em análise, mostra o estado vazio', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /sugestoes': RespostaFalsa(_pagina([])),
      });

      await pumpRecebidas(tester);

      expect(find.text('Nenhuma sugestão aguardando avaliação'), findsOneWidget);
    });

    testWidgets('o painel da universidade tem a seção de sugestões recebidas', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': _semNotificacoes,
        'GET /universidades/7/cadastro': RespostaFalsa(envelope(cadastroUniversidadeJson(status: 'A'))),
        'GET /sugestoes': RespostaFalsa(_pagina([])),
      });
      sessionController.redefinirParaTestes(usuario: _universidade);
      await pumpComRouter(
        tester,
        initialLocation: '/painel-universidade/sugestoes',
        rotas: {
          '/painel-universidade/sugestoes': (context) =>
              const PainelUniversidadePage(secao: SecaoUniversidade.sugestoes),
        },
      );
      await tester.pumpAndSettle();

      expect(find.byType(SugestoesRecebidasLista), findsOneWidget);
      expect(find.text('Nenhuma sugestão aguardando avaliação'), findsOneWidget);
    });
  });
}
