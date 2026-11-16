import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
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

Map<String, dynamic> _resultado() => envelope(
      [
        {
          'id': 1,
          'nomeFantasia': 'Fatec Sorocaba',
          'logoUrl': null,
          'natureza': 'P',
          'mediaAvaliacao': '4.50',
          'totalAvaliacoes': 3,
          'cidade': 'Sorocaba',
          'estado': 'SP',
          'programas': <dynamic>[],
          'salva': false,
        },
      ],
      {'page': 1, 'pageSize': 20, 'total': 1, 'totalPages': 1},
    );

RespostaFalsa _pesquisaSalvaCriada(String nome) => RespostaFalsa(
      envelope({
        'id': 20,
        'nome': nome,
        'tipo': 'UNIVERSIDADE',
        'parametros': {'cidade': 'Sorocaba', 'sort': 'nome'},
        'criadoEm': '2026-11-16T12:00:00.000Z',
      }),
      status: 201,
    );

const _nomeDuplicado = RespostaFalsa(
  {
    'error': {
      'code': 'PESQUISA_DUPLICADA',
      'message': 'Você já tem uma pesquisa salva com esse nome. Escolha outro nome.',
      'details': <dynamic>[],
    },
  },
  status: 409,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  Future<void> pumpPesquisa(WidgetTester tester, {Map<String, String>? filtros}) => pumpComRouter(
        tester,
        initialLocation: '/universidades',
        rotas: {
          '/universidades': (context) => PesquisaUniversidadesPage(filtrosIniciais: filtros),
          '/login': (context) => Text('Login para ${(GoRouterState.of(context).extra as Map?)?['redirect']}'),
        },
      );

  testWidgets('visitante que clica em "Salvar pesquisa" vai ao login e volta com os mesmos filtros', (tester) async {
    mockApi({'/universidades': _resultado()});

    await pumpPesquisa(tester, filtros: {'cidade': 'Sorocaba'});
    await tester.tap(find.text('Salvar pesquisa'));
    await tester.pumpAndSettle();

    expect(find.text('Login para /universidades?cidade=Sorocaba&sort=nome'), findsOneWidget);
  });

  testWidgets('nome duplicado mostra a mensagem e mantém o diálogo aberto; outro nome salva', (tester) async {
    sessionController.redefinirParaTestes(usuario: _aluno);
    mockAuthApiRotas({
      'GET /universidades': RespostaFalsa(_resultado()),
      'POST /pesquisas-salvas': _nomeDuplicado,
    });

    await pumpPesquisa(tester, filtros: {'cidade': 'Sorocaba'});
    await tester.tap(find.text('Salvar pesquisa'));
    await tester.pumpAndSettle();
    expect(find.text('Nome da pesquisa'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Públicas');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Você já tem uma pesquisa salva com esse nome. Escolha outro nome.'), findsOneWidget);
    expect(find.text('Nome da pesquisa'), findsOneWidget);
    final primeiroPost = requisicoesAuthApi.singleWhere((r) => r.method == 'POST');
    expect(primeiroPost.data, {
      'nome': 'Públicas',
      'parametros': {'cidade': 'Sorocaba', 'sort': 'nome'},
    });

    mockAuthApiRotas({'POST /pesquisas-salvas': _pesquisaSalvaCriada('Públicas em Sorocaba')});
    await tester.enterText(find.byType(TextField).last, 'Públicas em Sorocaba');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Nome da pesquisa'), findsNothing);
    expect(find.text('Pesquisa "Públicas em Sorocaba" salva.'), findsOneWidget);
  });

  testWidgets('nome vazio não chama a API', (tester) async {
    sessionController.redefinirParaTestes(usuario: _aluno);
    mockAuthApiRotas({'GET /universidades': RespostaFalsa(_resultado())});

    await pumpPesquisa(tester);
    await tester.tap(find.text('Salvar pesquisa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um nome para a pesquisa'), findsOneWidget);
    expect(requisicoesAuthApi.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('abre uma pesquisa salva pelo id e refaz a pesquisa com os filtros dela', (tester) async {
    sessionController.redefinirParaTestes(usuario: _aluno);
    mockAuthApiRotas({
      'GET /pesquisas-salvas/20': RespostaFalsa(
        envelope({
          'id': 20,
          'nome': 'Públicas em SP',
          'tipo': 'UNIVERSIDADE',
          'parametros': {'cidade': 'Sorocaba', 'estado': 'SP', 'natureza': 'P', 'notaMinima': 4, 'sort': 'media'},
          'criadoEm': '2026-11-16T12:00:00.000Z',
        }),
      ),
      'GET /universidades': RespostaFalsa(_resultado()),
    });

    await pumpPesquisa(tester, filtros: {'pesquisaSalva': '20'});
    await tester.pumpAndSettle();

    expect(find.text('Pesquisa salva: Públicas em SP'), findsOneWidget);
    expect(find.text('Estado: SP'), findsOneWidget);
    expect(find.text('Nota mínima 4,0'), findsOneWidget);
    expect(find.text('Ordenar por média'), findsOneWidget);

    final pesquisa = requisicoesAuthApi.singleWhere((r) => r.path == '/universidades');
    expect(pesquisa.queryParameters, {
      'cidade': 'Sorocaba',
      'estado': 'SP',
      'natureza': 'P',
      'notaMinima': '4.0',
      'sort': 'media',
      'page': '1',
    });
  });

  testWidgets('pesquisa salva de outro aluno mostra o aviso e cai na pesquisa sem filtros', (tester) async {
    sessionController.redefinirParaTestes(usuario: _aluno);
    mockAuthApiRotas({
      'GET /pesquisas-salvas/99': const RespostaFalsa(
        {
          'error': {'code': 'FORBIDDEN', 'message': 'Acesso não permitido', 'details': <dynamic>[]},
        },
        status: 403,
      ),
      'GET /universidades': RespostaFalsa(_resultado()),
    });

    await pumpPesquisa(tester, filtros: {'pesquisaSalva': '99'});
    await tester.pumpAndSettle();

    expect(find.text('Acesso não permitido'), findsOneWidget);
    expect(find.text('1 universidade encontrada'), findsOneWidget);
  });

  testWidgets('aceita os filtros por parâmetro da rota', (tester) async {
    mockApi({'/universidades': _resultado()});

    await pumpPesquisa(tester, filtros: {'estado': 'RJ', 'notaMinima': '3.5', 'sort': 'avaliacoes'});

    expect(find.text('Estado: RJ'), findsOneWidget);
    expect(find.text('Nota mínima 3,5'), findsOneWidget);
    expect(find.text('Ordenar por avaliações'), findsOneWidget);
  });
}
