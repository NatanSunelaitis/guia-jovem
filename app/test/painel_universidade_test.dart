import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/features/auth/domain/usuario_sessao.dart';
import 'package:app/features/painel_universidade/presentation/painel_universidade_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/cadastro_universidade_json.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/painel_admin.dart';
import 'helpers/pump_with_router.dart';

final _universidade = UsuarioSessao(
  id: 5,
  nome: 'Secretaria Fatec Itu',
  email: 'secretaria@fatecitu.edu.br',
  tipoUsuario: TipoUsuario.universidade,
  // A sessão guarda o status do login; o painel mostra o da API.
  universidade: UniversidadeDoUsuario(id: 7, status: 'P'),
);

Map<String, dynamic> _campus({int id = 20, String nome = 'Campus Itu', bool principal = true, int ofertas = 0}) => {
      'id': id,
      'nome': nome,
      'cnpj': null,
      'telefoneCelular': null,
      'telefoneFixo': '1140000000',
      'emailCampus': null,
      'principal': principal,
      'endereco': {
        'logradouro': 'Av. Tiradentes',
        'numero': '1211',
        'complemento': null,
        'bairro': 'Centro',
        'cidade': 'Itu',
        'estado': 'SP',
        'cep': '13309640',
      },
      'totalOfertas': ofertas,
    };

Map<String, dynamic> _curso({List<Map<String, dynamic>> ofertas = const []}) => {
      'id': 40,
      'nome': 'Análise e Desenvolvimento de Sistemas',
      'areaCurso': 'Tecnologia',
      'notaMec': null,
      'modalidade': 'Presencial',
      'grau': 'Tecnólogo',
      'duracaoSemestres': 6,
      'descricao': null,
      'ofertas': ofertas,
    };

final _programas = [
  {'id': 1, 'nome': 'Exame Nacional do Ensino Médio', 'sigla': 'ENEM', 'tipo': 'ENTRADA', 'aceito': true, 'observacao': null},
  {'id': 2, 'nome': 'Fundo de Financiamento Estudantil', 'sigla': 'FIES', 'tipo': 'FINANCIAMENTO', 'aceito': false, 'observacao': null},
  {'id': 3, 'nome': 'Programa Universidade para Todos', 'sigla': 'ProUni', 'tipo': 'BOLSA', 'aceito': false, 'observacao': null},
];

/// Rotas do painel com respostas padrão; [extras] sobrescreve ou acrescenta.
Map<String, RespostaFalsa Function(RequestOptions)> _rotas(
  Map<String, dynamic> cadastro, [
  Map<String, RespostaFalsa Function(RequestOptions)> extras = const {},
]) =>
    {
      'GET /notificacoes': (_) => semNotificacoes,
      'GET /universidades/7/cadastro': (_) => RespostaFalsa(envelope(cadastro)),
      'GET /universidades/7/estatisticas': (_) => RespostaFalsa(
            envelope({'de': '2026-10-20', 'ate': '2026-11-18', 'visitas': 42, 'mediaAvaliacao': 4.5, 'totalAvaliacoes': 2}),
          ),
      'GET /universidades/7/gestao/campus': (_) => RespostaFalsa(envelope([_campus()])),
      'GET /universidades/7/gestao/cursos': (_) => RespostaFalsa(envelope([_curso()])),
      'GET /universidades/7/gestao/programas': (_) => RespostaFalsa(envelope(_programas)),
      'GET /universidades/7/gestao/bolsas': (_) => RespostaFalsa(envelope(<dynamic>[])),
      'GET /universidades/7/gestao/avaliacoes': (_) => RespostaFalsa(paginaDe([])),
      ...extras,
    };

Future<void> _pumpPainel(
  WidgetTester tester, {
  String status = 'A',
  String secao = 'dados',
  String? motivo,
  Map<String, RespostaFalsa Function(RequestOptions)> extras = const {},
}) async {
  final cadastro = cadastroUniversidadeJson(
    status: status,
    motivoReprovacao: motivo,
    aprovadoEm: status == 'A' || status == 'I' ? '2026-11-11T12:00:00.000Z' : null,
  );
  mockAuthApiRotasDinamicas(_rotas(cadastro, extras));
  sessionController.redefinirParaTestes(usuario: _universidade);
  await pumpComRouter(
    tester,
    initialLocation: '/painel-universidade/$secao',
    rotas: {
      '/painel-universidade/:secao': (context) => PainelUniversidadePage(
            key: ValueKey(GoRouterState.of(context).pathParameters['secao']),
            secao: SecaoUniversidade.doCaminho(GoRouterState.of(context).pathParameters['secao']),
          ),
      '/universidades/:id': (context) => PaginaMarcadora('Página ${GoRouterState.of(context).pathParameters['id']}'),
    },
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  group('Faixa de situação', () {
    testWidgets('pendente: em análise, com as seções editáveis', (tester) async {
      await _pumpPainel(tester, status: 'P');

      expect(find.text('Cadastro em análise'), findsOneWidget);
      expect(find.textContaining('A análise leva até 15 dias'), findsOneWidget);
      expect(find.text('Reenviar para análise'), findsNothing);
      expect(find.text('Ver página pública'), findsNothing);
      expect(find.text('Editar dados'), findsOneWidget);
    });

    testWidgets('aprovada: página publicada e o link para a página pública', (tester) async {
      await _pumpPainel(tester, status: 'A');

      expect(find.text('Página publicada'), findsOneWidget);
      expect(find.textContaining('desde 11/11/2026'), findsOneWidget);
      await tester.tap(find.text('Ver página pública'));
      await tester.pumpAndSettle();
      expect(find.text('Página 7'), findsOneWidget);
    });

    testWidgets('reprovada: mostra o motivo e reenvia para análise depois de confirmar', (tester) async {
      await _pumpPainel(
        tester,
        status: 'R',
        motivo: 'CNPJ não confere',
        extras: {
          'POST /universidades/7/reenviar': (_) => RespostaFalsa(envelope(cadastroUniversidadeJson(status: 'P'))),
        },
      );

      expect(find.text('Cadastro reprovado'), findsOneWidget);
      expect(find.text('CNPJ não confere'), findsOneWidget);

      await tester.tap(find.text('Reenviar para análise'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      // Cancelar não reenvia.
      await confirmarNoDialogo(tester, 'Cancelar');
      expect(requisicoes('POST', '/reenviar'), isEmpty);

      await tester.tap(find.text('Reenviar para análise'));
      await tester.pumpAndSettle();
      await confirmarNoDialogo(tester, 'Reenviar');

      expect(requisicoes('POST', '/universidades/7/reenviar'), hasLength(1));
      expect(find.text('Cadastro em análise'), findsOneWidget);
      expect(find.text('Cadastro reenviado para análise.'), findsOneWidget);
    });

    testWidgets('inativa: somente leitura, sem editar', (tester) async {
      await _pumpPainel(tester, status: 'I');

      expect(find.text('Universidade inativa'), findsOneWidget);
      expect(find.textContaining('fora do site'), findsWidgets);
      expect(find.text('Editar dados'), findsNothing);
      expect(find.byKey(const Key('aviso-somente-leitura')), findsOneWidget);
    });
  });

  group('Dados da instituição', () {
    testWidgets('mostra os dados, o desempenho da página e edita pelo formulário', (tester) async {
      await _pumpPainel(
        tester,
        extras: {
          'PATCH /universidades/7': (requisicao) => RespostaFalsa(
                envelope({...cadastroUniversidadeJson(status: 'A'), 'linkSimulados': 'https://fatecitu.edu.br/simulados'}),
              ),
        },
      );

      expect(find.text('Faculdade de Tecnologia de Itu'), findsOneWidget);
      expect(find.text('12.345.678/0001-99'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('4,5 (2 avaliações)'), findsOneWidget);

      await tester.tap(find.text('Editar dados'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Simulados'), 'https://fatecitu.edu.br/simulados');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final corpo = requisicoes('PATCH', '/universidades/7').single.corpo as Map;
      expect(corpo['linkSimulados'], 'https://fatecitu.edu.br/simulados');
      expect(find.text('https://fatecitu.edu.br/simulados'), findsOneWidget);
    });
  });

  group('Campi', () {
    testWidgets('único campus: excluir desabilitado', (tester) async {
      await _pumpPainel(tester, secao: 'campus');

      expect(find.text('Campus Itu'), findsOneWidget);
      expect(find.text('Itu / SP'), findsOneWidget);
      final excluir = tester.widget<IconButton>(
        find.ancestor(of: find.byTooltip('A universidade precisa ter ao menos um campus'), matching: find.byType(IconButton)),
      );
      expect(excluir.onPressed, isNull);
    });

    testWidgets('novo campus: valida o CEP e envia o endereço', (tester) async {
      await _pumpPainel(
        tester,
        secao: 'campus',
        extras: {'POST /universidades/7/campus': (_) => RespostaFalsa(envelope(_campus(id: 21, nome: 'Campus Salto', principal: false)), status: 201)},
      );

      await tester.tap(find.text('Novo campus'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Nome do campus'), 'Campus Salto');
      await tester.enterText(campo('Logradouro'), 'Rua Nova');
      await tester.enterText(campo('Número'), '10');
      await tester.enterText(campo('Bairro'), 'Centro');
      await tester.enterText(campo('Cidade'), 'Salto');
      await escolher(tester, const Key('campus-estado'), 'SP');
      await tester.ensureVisible(find.text('Salvar campus'));
      await tester.tap(find.text('Salvar campus'));
      await tester.pumpAndSettle();
      expect(find.text('CEP deve ter 8 dígitos'), findsOneWidget);
      expect(requisicoes('POST', '/campus'), isEmpty);

      await tester.enterText(campo('CEP'), '13320-000');
      await tester.ensureVisible(find.text('Salvar campus'));
      await tester.tap(find.text('Salvar campus'));
      await tester.pumpAndSettle();

      final corpo = requisicoes('POST', '/universidades/7/campus').single.corpo as Map;
      expect(corpo['nome'], 'Campus Salto');
      expect(corpo['principal'], false);
      expect((corpo['endereco'] as Map)['cep'], '13320-000');
      expect(find.text('Campus criado.'), findsOneWidget);
    });

    testWidgets('mostra a mensagem da API quando a exclusão é bloqueada', (tester) async {
      await _pumpPainel(
        tester,
        secao: 'campus',
        extras: {
          'GET /universidades/7/gestao/campus': (_) =>
              RespostaFalsa(envelope([_campus(), _campus(id: 21, nome: 'Campus Salto', principal: false, ofertas: 1)])),
          'DELETE /campus/21': (_) => erroDaApi('CAMPUS_COM_OFERTAS', 'Este campus oferta 1 curso. Remova as ofertas antes de excluir.'),
        },
      );

      await tester.tap(find.byTooltip('Excluir Campus Salto'));
      await tester.pumpAndSettle();
      await confirmarNoDialogo(tester, 'Excluir');

      expect(find.text('Ação não permitida'), findsOneWidget);
      expect(find.textContaining('Remova as ofertas'), findsOneWidget);
    });

    testWidgets('reprovada ainda corrige os campi', (tester) async {
      await _pumpPainel(tester, status: 'R', motivo: 'Endereço incompleto', secao: 'campus');

      expect(find.text('Novo campus'), findsOneWidget);
      expect(find.byKey(const Key('aviso-somente-leitura')), findsNothing);
    });

    testWidgets('inativa: campi só para leitura', (tester) async {
      await _pumpPainel(tester, status: 'I', secao: 'campus');

      expect(find.text('Campus Itu'), findsOneWidget);
      expect(find.text('Novo campus'), findsNothing);
      expect(find.byTooltip('Editar Campus Itu'), findsNothing);
    });
  });

  group('Cursos', () {
    testWidgets('lista as ofertas por campus, turno e vagas e cadastra uma oferta', (tester) async {
      await _pumpPainel(
        tester,
        secao: 'cursos',
        extras: {
          'GET /universidades/7/gestao/cursos': (_) => RespostaFalsa(envelope([
                _curso(ofertas: [
                  {'cursoId': 40, 'campusId': 20, 'campusNome': 'Campus Itu', 'turno': 'Noturno', 'vagas': 40},
                ]),
              ])),
          'GET /universidades/7/gestao/campus': (_) =>
              RespostaFalsa(envelope([_campus(), _campus(id: 21, nome: 'Campus Salto', principal: false)])),
          'POST /cursos/40/ofertas': (_) => RespostaFalsa(envelope({}), status: 201),
        },
      );

      expect(find.text('Análise e Desenvolvimento de Sistemas'), findsOneWidget);
      expect(find.text('Campus Itu · Noturno · 40 vagas'), findsOneWidget);

      await tester.tap(find.byTooltip('Ofertas de Análise e Desenvolvimento de Sistemas'));
      await tester.pumpAndSettle();
      await escolher(tester, const Key('oferta-campus'), 'Campus Salto');
      await escolher(tester, const Key('oferta-turno'), 'Matutino');
      await tester.enterText(campo('Vagas'), '30');
      await tester.tap(find.text('Adicionar oferta'));
      await tester.pumpAndSettle();

      final corpo = requisicoes('POST', '/cursos/40/ofertas').single.corpo as Map;
      expect(corpo, {'campusId': 21, 'turno': 'Matutino', 'vagas': 30});
    });

    testWidgets('novo curso usa a universidade da conta, sem escolher', (tester) async {
      await _pumpPainel(
        tester,
        secao: 'cursos',
        extras: {
          'POST /universidades/7/cursos': (_) => RespostaFalsa(
                envelope({'id': 41, 'nome': 'Gestão Empresarial', 'universidade': {'id': 7, 'nomeFantasia': 'Fatec Itu'}}),
                status: 201,
              ),
        },
      );

      await tester.tap(find.text('Novo curso'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('curso-universidade')), findsNothing);
      await tester.enterText(campo('Nome'), 'Gestão Empresarial');
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect((requisicoes('POST', '/universidades/7/cursos').single.corpo as Map)['nome'], 'Gestão Empresarial');
    });

    testWidgets('reprovada: cursos bloqueados até a aprovação', (tester) async {
      await _pumpPainel(tester, status: 'R', motivo: 'CNPJ não confere', secao: 'cursos');

      expect(find.byKey(const Key('aviso-somente-leitura')), findsOneWidget);
      expect(find.textContaining('Disponível depois que o cadastro for aprovado'), findsOneWidget);
      expect(find.text('Novo curso'), findsNothing);
      expect(find.byTooltip('Editar Análise e Desenvolvimento de Sistemas'), findsNothing);
    });
  });

  group('Programas aceitos', () {
    testWidgets('marca um programa com observação e salva o conjunto', (tester) async {
      await _pumpPainel(
        tester,
        secao: 'programas',
        extras: {
          'PUT /universidades/7/programas': (_) => RespostaFalsa(envelope([
                for (final p in _programas) {...p, 'aceito': p['id'] != 3},
              ])),
        },
      );

      expect(find.text('Programas de entrada'), findsOneWidget);
      expect(find.text('Financiamento'), findsOneWidget);
      await tester.tap(find.byKey(const Key('programa-2')));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Observação (opcional)').last, 'Em todos os cursos');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final corpo = requisicoes('PUT', '/universidades/7/programas').single.corpo as Map;
      expect(corpo['programas'], [
        {'programaId': 1, 'observacao': null},
        {'programaId': 2, 'observacao': 'Em todos os cursos'},
      ]);
      expect(find.text('Programas aceitos atualizados.'), findsOneWidget);
    });

    testWidgets('inativa: sem salvar e com as marcações desabilitadas', (tester) async {
      await _pumpPainel(tester, status: 'I', secao: 'programas');

      expect(find.text('Salvar'), findsNothing);
      final marcacao = tester.widget<CheckboxListTile>(find.byKey(const Key('programa-1')));
      expect(marcacao.onChanged, isNull);
    });
  });

  group('Bolsas institucionais', () {
    testWidgets('cria uma bolsa própria', (tester) async {
      await _pumpPainel(
        tester,
        secao: 'bolsas',
        extras: {'POST /universidades/7/bolsas': (_) => RespostaFalsa(envelope({}), status: 201)},
      );

      expect(find.text('Nenhuma bolsa institucional'), findsOneWidget);
      await tester.tap(find.text('Nova bolsa'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Nome da bolsa'), 'Bolsa Mérito');
      await tester.enterText(find.byKey(const Key('bolsa-descricao')), 'Desconto de 50% para os melhores colocados');
      await tester.ensureVisible(find.text('Salvar bolsa'));
      await tester.tap(find.text('Salvar bolsa'));
      await tester.pumpAndSettle();

      final corpo = requisicoes('POST', '/universidades/7/bolsas').single.corpo as Map;
      expect(corpo['nome'], 'Bolsa Mérito');
      expect(find.text('Bolsa criada.'), findsOneWidget);
    });
  });

  group('Sugestões e avaliações recebidas', () {
    testWidgets('sugestões recebidas reaproveitam a lista existente', (tester) async {
      await _pumpPainel(
        tester,
        secao: 'sugestoes',
        extras: {
          'GET /sugestoes': (_) => RespostaFalsa(paginaDe([
                {
                  'id': 12,
                  'titulo': 'Mais vagas no noturno',
                  'texto': 'Abrir mais turmas.',
                  'status': 'EM_ANALISE',
                  'resposta': null,
                  'criadoEm': '2026-11-10T12:00:00.000Z',
                  'avaliadoEm': null,
                  'universidade': {'id': 7, 'nomeFantasia': 'Fatec Itu'},
                  'autor': {'nome': 'Ana'},
                  'podeAvaliar': true,
                },
              ])),
        },
      );

      expect(find.text('Mais vagas no noturno'), findsOneWidget);
    });

    testWidgets('avaliações recebidas em modo leitura', (tester) async {
      await _pumpPainel(
        tester,
        secao: 'avaliacoes',
        extras: {
          'GET /universidades/7/gestao/avaliacoes': (_) => RespostaFalsa(paginaDe([
                {'id': 1, 'nota': 4, 'comentario': 'Ótimos professores', 'criadoEm': '2026-11-12T12:00:00.000Z', 'autor': 'Ana'},
              ])),
        },
      );

      expect(find.text('Ótimos professores'), findsOneWidget);
      expect(find.text('Ana · 12/11/2026'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('Conta', () {
    testWidgets('alterar senha, sair com confirmação e excluir conta avisando da inativação', (tester) async {
      await _pumpPainel(tester, status: 'I', secao: 'conta');

      expect(find.text('Alterar senha'), findsOneWidget);
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(find.text('Tem certeza que deseja sair da sua conta?'), findsOneWidget);
      await confirmarNoDialogo(tester, 'Cancelar');

      await tester.tap(find.text('Excluir conta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('A universidade fica inativa'), findsOneWidget);
    });
  });

  testWidgets('a troca de aba muda a URL da seção', (tester) async {
    await _pumpPainel(tester);

    await tester.tap(find.text('Campi'));
    await tester.pumpAndSettle();

    expect(find.text('A universidade tem sempre um campus principal.'), findsOneWidget);
  });
}
