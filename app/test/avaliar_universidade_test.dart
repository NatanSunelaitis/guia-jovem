import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/features/universidades/presentation/detalhe_universidade_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_api.dart' hide envelope;
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

final _aluno = UsuarioSessao(id: 1, nome: 'Ana Souza', email: 'ana@exemplo.com', tipoUsuario: TipoUsuario.aluno);

Map<String, dynamic> _detalhe({Map<String, dynamic>? minhaAvaliacao, String? media, int total = 0}) => {
      'id': 1,
      'nomeFantasia': 'Fatec Sorocaba',
      'razaoSocial': 'Faculdade de Tecnologia de Sorocaba',
      'descricao': null,
      'logoUrl': null,
      'natureza': 'P',
      'linkPagina': null,
      'linkSimulados': null,
      'mediaAvaliacao': media,
      'totalAvaliacoes': total,
      'enderecoPrincipal': null,
      'campus': <dynamic>[],
      'programas': {'ENTRADA': <dynamic>[], 'FINANCIAMENTO': <dynamic>[], 'BOLSA': <dynamic>[]},
      'minhaAvaliacao': minhaAvaliacao,
      'salva': false,
    };

Map<String, dynamic> _listaAvaliacoes(List<Map<String, dynamic>> itens) => {
      'data': itens,
      'meta': {'page': 1, 'pageSize': 20, 'total': itens.length, 'totalPages': 1},
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpDetalhe(WidgetTester tester) => pumpComRouter(
        tester,
        initialLocation: '/universidades/1',
        rotas: {
          '/universidades/1': (context) => const DetalheUniversidadePage(id: 1),
          '/login': (context) => Text('Login para ${(GoRouterState.of(context).extra as Map?)?['redirect']}'),
        },
      );

  testWidgets('visitante que clica em avaliar vai ao login e volta para a mesma universidade', (tester) async {
    mockApi({
      '/universidades/1/avaliacoes': _listaAvaliacoes([]),
      '/universidades/1': envelope(_detalhe()),
    });

    await pumpDetalhe(tester);
    await tester.tap(find.text('Avaliar'));
    await tester.pumpAndSettle();

    expect(find.text('Login para /universidades/1'), findsOneWidget);
  });

  testWidgets('aluno avalia e o detalhe atualiza a média e a lista de avaliações', (tester) async {
    sessionController.redefinirParaTestes(usuario: _aluno);
    mockApi({'/universidades/1/avaliacoes': _listaAvaliacoes([])});
    mockAuthApiRotas({
      'GET /universidades/1': RespostaFalsa(envelope(_detalhe())),
      'POST /universidades/1/avaliacoes': RespostaFalsa(
        envelope({
          'id': 50,
          'universidadeId': 1,
          'nota': 4,
          'comentario': 'Ótimos professores',
          'criadoEm': '2026-11-16T12:00:00.000Z',
          'universidade': {'id': 1, 'mediaAvaliacao': 4, 'totalAvaliacoes': 1},
        }),
        status: 201,
      ),
    });

    await pumpDetalhe(tester);
    expect(find.text('Sem avaliações ainda'), findsOneWidget);

    await tester.tap(find.text('Avaliar'));
    await tester.pumpAndSettle();
    expect(find.text('Como foi sua experiência com a Fatec Sorocaba?'), findsOneWidget);

    await tester.tap(find.byTooltip('4 estrelas'));
    await tester.enterText(find.byType(TextField).last, 'Ótimos professores');
    // A lista recarregada depois do envio já traz a avaliação nova.
    mockApi({
      '/universidades/1/avaliacoes': _listaAvaliacoes([
        {'id': 50, 'nota': 4, 'comentario': 'Ótimos professores', 'criadoEm': '2026-11-16T12:00:00.000Z', 'autor': 'Ana'},
      ]),
    });
    await tester.tap(find.text('Enviar avaliação'));
    await tester.pumpAndSettle();

    final post = requisicoesAuthApi.singleWhere((r) => r.method == 'POST');
    expect(post.data, {'nota': 4, 'comentario': 'Ótimos professores'});
    expect(find.text('4.0 (1 avaliação)'), findsOneWidget);
    expect(find.text('Ótimos professores'), findsOneWidget);
    expect(find.text('Editar minha avaliação'), findsOneWidget);
    expect(find.text('Avaliação enviada. Obrigado!'), findsOneWidget);
  });

  testWidgets('aluno que já avaliou abre o modal preenchido e edita com PUT', (tester) async {
    sessionController.redefinirParaTestes(usuario: _aluno);
    mockApi({
      '/universidades/1/avaliacoes': _listaAvaliacoes([
        {'id': 50, 'nota': 4, 'comentario': 'Bom', 'criadoEm': '2026-11-16T12:00:00.000Z', 'autor': 'Ana'},
      ]),
    });
    mockAuthApiRotas({
      'GET /universidades/1': RespostaFalsa(
        envelope(_detalhe(minhaAvaliacao: {'id': 50, 'nota': 4, 'comentario': 'Bom'}, media: '4.00', total: 1)),
      ),
      'PUT /avaliacoes/50': RespostaFalsa(
        envelope({
          'id': 50,
          'universidadeId': 1,
          'nota': 2,
          'comentario': 'Bom',
          'criadoEm': '2026-11-16T12:00:00.000Z',
          'universidade': {'id': 1, 'mediaAvaliacao': '2.00', 'totalAvaliacoes': 1},
        }),
      ),
    });

    await pumpDetalhe(tester);
    await tester.pumpAndSettle();
    expect(find.text('Editar minha avaliação'), findsOneWidget);
    await tester.tap(find.text('Editar avaliação'));
    await tester.pumpAndSettle();

    expect(find.text('Editar sua avaliação da Fatec Sorocaba'), findsOneWidget);
    final campo = tester.widget<TextField>(find.byType(TextField).last);
    expect(campo.controller!.text, 'Bom');

    await tester.tap(find.byTooltip('2 estrelas'));
    await tester.pump();
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    final put = requisicoesAuthApi.singleWhere((r) => r.method == 'PUT');
    expect(put.path, '/avaliacoes/50');
    expect(put.data, {'nota': 2, 'comentario': 'Bom'});
    expect(find.text('2.0 (1 avaliação)'), findsOneWidget);
    expect(find.text('Avaliação atualizada.'), findsOneWidget);
  });

  testWidgets('erro da API mantém o modal aberto com a mensagem', (tester) async {
    sessionController.redefinirParaTestes(usuario: _aluno);
    mockApi({'/universidades/1/avaliacoes': _listaAvaliacoes([])});
    mockAuthApiRotas({
      'GET /universidades/1': RespostaFalsa(envelope(_detalhe())),
      'POST /universidades/1/avaliacoes': const RespostaFalsa(
        {
          'error': {
            'code': 'AVALIACAO_DUPLICADA',
            'message': 'Você já avaliou esta universidade. Edite a sua avaliação.',
            'details': <dynamic>[],
          },
        },
        status: 409,
      ),
    });

    await pumpDetalhe(tester);
    await tester.tap(find.text('Avaliar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('5 estrelas'));
    await tester.pump();
    await tester.tap(find.text('Enviar avaliação'));
    await tester.pumpAndSettle();

    expect(find.text('Você já avaliou esta universidade. Edite a sua avaliação.'), findsOneWidget);
    expect(find.text('Enviar avaliação'), findsOneWidget);
  });
}
