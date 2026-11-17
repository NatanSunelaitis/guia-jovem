import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/features/perfil/presentation/perfil_page.dart';
import 'package:app/features/perfil/presentation/widgets/pesquisas_salvas_secao.dart';
import 'package:app/shared/widgets/gj_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/pump_with_router.dart';

final _aluno = UsuarioSessao(id: 1, nome: 'Ana Souza', email: 'ana@exemplo.com', tipoUsuario: TipoUsuario.aluno);

Map<String, dynamic> _pagina(List<Map<String, dynamic>> itens) =>
    envelope(itens, {'page': 1, 'pageSize': 100, 'total': itens.length, 'totalPages': 1});

Map<String, dynamic> _faculdade(int id, String nome) => {
      'id': id,
      'nomeFantasia': nome,
      'logoUrl': null,
      'natureza': 'P',
      'mediaAvaliacao': '4.60',
      'totalAvaliacoes': 12,
      'cidade': 'Sorocaba',
      'estado': 'SP',
      'programas': <dynamic>[],
      'salva': true,
      'salvaEm': '2026-11-10T12:00:00.000Z',
    };

Map<String, dynamic> _pesquisa(int id, String nome, Map<String, dynamic> parametros) => {
      'id': id,
      'nome': nome,
      'tipo': 'UNIVERSIDADE',
      'parametros': parametros,
      'criadoEm': '2026-11-16T12:00:00.000Z',
    };

const _erroServidor = RespostaFalsa(
  {
    'error': {'code': 'INTERNAL_ERROR', 'message': 'Erro interno. Tente novamente mais tarde.', 'details': <dynamic>[]},
  },
  status: 500,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpPerfil(WidgetTester tester, {bool aguardar = true}) async {
    sessionController.redefinirParaTestes(usuario: _aluno);
    await pumpComRouter(
      tester,
      initialLocation: '/perfil',
      rotas: {
        '/perfil': (context) => const PerfilPage(),
        '/universidades': (context) =>
            Text('Pesquisa ${GoRouterState.of(context).uri.queryParameters['pesquisaSalva'] ?? 'sem filtros'}'),
        '/universidades/7': (context) => const PaginaMarcadora('Detalhe da Fatec'),
      },
    );
    if (aguardar) await tester.pumpAndSettle();
  }

  Future<void> abrirAba(WidgetTester tester, String aba) async {
    await tester.tap(find.text(aba));
    await tester.pumpAndSettle();
  }

  group('Faculdades salvas', () {
    testWidgets('mostra o carregamento e depois os cards', (tester) async {
      mockAuthApiRotas({
        'GET /favoritos/universidades': RespostaFalsa(
          _pagina([_faculdade(7, 'Fatec Sorocaba')]),
          atraso: const Duration(milliseconds: 500),
        ),
      });

      await pumpPerfil(tester, aguardar: false);
      expect(find.byType(GJSkeleton), findsWidgets);

      await tester.pumpAndSettle();
      expect(find.text('Fatec Sorocaba'), findsOneWidget);
      expect(find.byType(GJSkeleton), findsNothing);
    });

    testWidgets('remove uma faculdade e mostra o estado vazio quando acaba a lista', (tester) async {
      mockAuthApiRotas({
        'GET /favoritos/universidades': RespostaFalsa(_pagina([_faculdade(7, 'Fatec Sorocaba')])),
        'DELETE /favoritos/universidades/7': RespostaFalsa(envelope({'sucesso': true, 'salva': false})),
      });
      await pumpPerfil(tester);

      await tester.tap(find.byTooltip('Remover das salvas'));
      await tester.pumpAndSettle();

      expect(requisicoesAuthApi.singleWhere((r) => r.method == 'DELETE').path, '/favoritos/universidades/7');
      expect(find.text('Fatec Sorocaba'), findsNothing);
      expect(find.text('Nenhuma faculdade salva ainda'), findsOneWidget);
      expect(find.text('Faculdade removida das salvas.'), findsOneWidget);
    });

    testWidgets('o card leva ao detalhe da universidade', (tester) async {
      mockAuthApiRotas({'GET /favoritos/universidades': RespostaFalsa(_pagina([_faculdade(7, 'Fatec Sorocaba')]))});
      await pumpPerfil(tester);

      await tester.tap(find.text('Saiba mais'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhe da Fatec'), findsOneWidget);
    });

    testWidgets('estado vazio tem atalho para a pesquisa', (tester) async {
      mockAuthApiRotas({'GET /favoritos/universidades': RespostaFalsa(_pagina([]))});
      await pumpPerfil(tester);

      expect(find.text('Nenhuma faculdade salva ainda'), findsOneWidget);
      await tester.tap(find.text('Pesquisar universidades'));
      await tester.pumpAndSettle();

      expect(find.text('Pesquisa sem filtros'), findsOneWidget);
    });

    testWidgets('erro mostra a mensagem e "Tentar novamente" recarrega', (tester) async {
      mockAuthApiRotas({'GET /favoritos/universidades': _erroServidor});
      await pumpPerfil(tester);

      expect(find.text('Não foi possível carregar'), findsOneWidget);
      expect(find.text('Erro interno. Tente novamente mais tarde.'), findsOneWidget);

      mockAuthApiRotas({'GET /favoritos/universidades': RespostaFalsa(_pagina([_faculdade(7, 'Fatec Sorocaba')]))});
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Fatec Sorocaba'), findsOneWidget);
    });
  });

  group('Pesquisas salvas', () {
    Map<String, RespostaFalsa> rotas(RespostaFalsa pesquisas, [Map<String, RespostaFalsa> extras = const {}]) => {
          'GET /favoritos/universidades': RespostaFalsa(_pagina([])),
          'GET /pesquisas-salvas': pesquisas,
          ...extras,
        };

    testWidgets('lista nome, data e filtros; "Executar" reabre a pesquisa pelo id', (tester) async {
      mockAuthApiRotas(rotas(RespostaFalsa(_pagina([
        _pesquisa(20, 'Públicas em Sorocaba', {'cidade': 'Sorocaba', 'natureza': 'P', 'notaMinima': 4, 'sort': 'media'}),
      ]))));
      await pumpPerfil(tester);
      await abrirAba(tester, 'Pesquisas salvas');

      expect(find.text('Públicas em Sorocaba'), findsOneWidget);
      expect(find.text('Salva em 16/11/2026'), findsOneWidget);
      for (final filtro in ['Cidade: Sorocaba', 'Públicas', 'Nota mínima 4,0', 'Ordenado por média']) {
        expect(find.text(filtro), findsOneWidget);
      }

      await tester.tap(find.text('Executar'));
      await tester.pumpAndSettle();
      expect(find.text('Pesquisa 20'), findsOneWidget);
    });

    testWidgets('excluir pede confirmação: cancelar mantém, confirmar exclui', (tester) async {
      mockAuthApiRotas(rotas(
        RespostaFalsa(_pagina([_pesquisa(20, 'Públicas em Sorocaba', {'cidade': 'Sorocaba'})])),
        {'DELETE /pesquisas-salvas/20': RespostaFalsa(envelope({'sucesso': true}))},
      ));
      await pumpPerfil(tester);
      await abrirAba(tester, 'Pesquisas salvas');

      await tester.tap(find.byTooltip('Excluir pesquisa'));
      await tester.pumpAndSettle();
      expect(find.text('Tem certeza que deseja excluir a pesquisa "Públicas em Sorocaba"?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(requisicoesAuthApi.where((r) => r.method == 'DELETE'), isEmpty);
      expect(find.text('Públicas em Sorocaba'), findsOneWidget);

      await tester.tap(find.byTooltip('Excluir pesquisa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(requisicoesAuthApi.singleWhere((r) => r.method == 'DELETE').path, '/pesquisas-salvas/20');
      expect(find.text('Nenhuma pesquisa salva'), findsOneWidget);
      expect(find.text('Pesquisa excluída.'), findsOneWidget);
    });

    testWidgets('estado vazio tem atalho para a pesquisa', (tester) async {
      mockAuthApiRotas(rotas(RespostaFalsa(_pagina([]))));
      await pumpPerfil(tester);
      await abrirAba(tester, 'Pesquisas salvas');

      expect(find.text('Nenhuma pesquisa salva'), findsOneWidget);
      await tester.tap(find.text('Fazer uma pesquisa'));
      await tester.pumpAndSettle();
      expect(find.text('Pesquisa sem filtros'), findsOneWidget);
    });

    testWidgets('erro mostra a mensagem com "Tentar novamente"', (tester) async {
      mockAuthApiRotas(rotas(_erroServidor));
      await pumpPerfil(tester);
      await abrirAba(tester, 'Pesquisas salvas');

      expect(find.text('Não foi possível carregar'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    test('descreve os filtros gravados em texto legível', () {
      expect(descreverFiltros({}), isEmpty);
      expect(descreverFiltros({'sort': 'nome'}), isEmpty);
      expect(
        descreverFiltros({'q': 'Fatec', 'estado': 'SP', 'natureza': 'V', 'areaCurso': 'Saúde', 'programaId': 3, 'sort': 'avaliacoes'}),
        ['Universidade: Fatec', 'Estado: SP', 'Privadas', 'Área: Saúde', 'Programa aceito', 'Ordenado por avaliações'],
      );
    });
  });

  group('Minhas avaliações', () {
    Map<String, RespostaFalsa> rotas(RespostaFalsa avaliacoes) => {
          'GET /favoritos/universidades': RespostaFalsa(_pagina([])),
          'GET /avaliacoes/minhas': avaliacoes,
        };

    testWidgets('lista as avaliações com acesso à universidade', (tester) async {
      mockAuthApiRotas(rotas(RespostaFalsa(_pagina([
        {
          'id': 50,
          'universidadeId': 7,
          'nota': 4,
          'comentario': 'Ótimos professores',
          'criadoEm': '2026-11-16T12:00:00.000Z',
          'universidade': {'id': 7, 'nomeFantasia': 'Fatec Sorocaba', 'logoUrl': null},
        },
      ]))));
      await pumpPerfil(tester);
      await abrirAba(tester, 'Avaliações');

      expect(find.text('Fatec Sorocaba'), findsOneWidget);
      expect(find.text('Ótimos professores'), findsOneWidget);
      expect(find.text('Avaliada em 16/11/2026'), findsOneWidget);

      await tester.tap(find.text('Ver universidade'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhe da Fatec'), findsOneWidget);
    });

    testWidgets('estado vazio', (tester) async {
      mockAuthApiRotas(rotas(RespostaFalsa(_pagina([]))));
      await pumpPerfil(tester);
      await abrirAba(tester, 'Avaliações');

      expect(find.text('Você ainda não avaliou nenhuma universidade'), findsOneWidget);
    });

    testWidgets('erro mostra a mensagem com "Tentar novamente"', (tester) async {
      mockAuthApiRotas(rotas(_erroServidor));
      await pumpPerfil(tester);
      await abrirAba(tester, 'Avaliações');

      expect(find.text('Não foi possível carregar'), findsOneWidget);
    });
  });
}
