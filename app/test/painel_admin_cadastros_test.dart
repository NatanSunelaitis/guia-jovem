import 'package:app/features/admin/presentation/painel_admin_page.dart';
import 'package:app/features/admin/presentation/secao_dashboard.dart';
import 'package:app/features/auth/data/session_controller.dart';
import 'package:app/shared/widgets/gj_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/auth_test_setup.dart';
import 'helpers/cadastro_universidade_json.dart';
import 'helpers/mock_auth_api.dart';
import 'helpers/painel_admin.dart';
import 'helpers/pump_with_router.dart';

Map<String, dynamic> _resumo() => {
      'usuariosPorPerfil': {'A': 120, 'U': 8, 'D': 2, 'total': 130},
      'universidadesPorStatus': {'P': 3, 'A': 7, 'R': 1, 'I': 0, 'total': 11},
      'cursos': 42,
      'programasPorTipo': {'ENTRADA': 2, 'FINANCIAMENTO': 1, 'BOLSA': 3, 'total': 6},
    };

Map<String, dynamic> _visitas({String agrupar = 'dia'}) => {
      'de': '2026-11-15',
      'ate': '2026-11-17',
      'agrupar': agrupar,
      'totalVisitas': 57,
      'loginsUnicos': 9,
      'visitasPorPerfil': {'visitante': 50, 'A': 7, 'U': 0, 'D': 0},
      'serie': [
        {'periodo': '2026-11-15', 'visitas': 20, 'loginsUnicos': 4},
        {'periodo': '2026-11-16', 'visitas': 0, 'loginsUnicos': 0},
        {'periodo': '2026-11-17', 'visitas': 37, 'loginsUnicos': 6},
      ],
    };

Map<String, dynamic> _ranking({bool vazio = false}) => {
      'de': '2026-11-15',
      'ate': '2026-11-17',
      'universidades': vazio
          ? <dynamic>[]
          : [
              {'id': 7, 'nome': 'Fatec Itu', 'visitas': 31},
              {'id': 8, 'nome': 'Fatec Sorocaba', 'visitas': 12},
            ],
      'programas': vazio
          ? <dynamic>[]
          : [
              {'id': 1, 'nome': 'ENEM', 'visitas': 15},
            ],
      'cursos': <dynamic>[],
    };

Map<String, RespostaFalsa> _rotasDashboard({bool rankingVazio = false}) => {
      'GET /notificacoes': semNotificacoes,
      'GET /estatisticas/resumo': RespostaFalsa(envelope(_resumo())),
      'GET /estatisticas/visitas': RespostaFalsa(envelope(_visitas())),
      'GET /estatisticas/ranking': RespostaFalsa(envelope(_ranking(vazio: rankingVazio))),
    };

Map<String, dynamic> _curso({int id = 30, String nome = 'Análise e Desenvolvimento de Sistemas', int campus = 0}) => {
      'id': id,
      'nome': nome,
      'areaCurso': 'Tecnologia',
      'notaMec': null,
      'modalidade': 'Presencial',
      'grau': 'Tecnólogo',
      'duracaoSemestres': 6,
      'descricao': null,
      'universidade': {'id': 7, 'nomeFantasia': 'Fatec Itu'},
      'totalCampus': campus,
    };

Map<String, dynamic> _programa({int id = 3, String sigla = 'PROUNI', List<Map<String, dynamic>> eventos = const []}) => {
      'id': id,
      'nome': 'Programa Universidade para Todos',
      'sigla': sigla,
      'tipo': 'BOLSA',
      'descricao': 'Bolsas integrais e parciais.',
      'requisitos': null,
      'comoFunciona': null,
      'linkOficial': 'https://prouni.mec.gov.br',
      'imagemUrl': null,
      'criadoEm': '2026-01-01T00:00:00.000Z',
      'totalUniversidades': 4,
      'eventos': eventos,
    };

Map<String, dynamic> _evento({int id = 40, String titulo = 'Inscrições'}) =>
    {'id': id, 'titulo': titulo, 'descricao': null, 'dataInicio': '2026-02-01', 'dataFim': '2026-02-10'};

Map<String, dynamic> _usuario({required int id, required String nome, String tipo = 'A', bool ativo = true}) => {
      'id': id,
      'nome': nome,
      'email': '${nome.split(' ').first.toLowerCase()}@exemplo.com',
      'tipoUsuario': tipo,
      'fotoUrl': null,
      'ativo': ativo,
      'criadoEm': '2026-03-12T12:00:00.000Z',
    };

final _erroInterno = erroDaApi('INTERNAL_ERROR', 'Erro interno. Tente novamente mais tarde.', status: 500);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(configurarAmbienteDeTeste);

  group('Dashboard', () {
    testWidgets('mostra os totais, os gráficos e os mais visitados', (tester) async {
      mockAuthApiRotas(_rotasDashboard());

      await pumpPainelAdmin(tester, '/admin/dashboard');

      expect(find.text('130'), findsOneWidget);
      expect(find.text('120 alunos, 8 universidades, 2 administradores'), findsOneWidget);
      expect(find.text('Universidades aprovadas'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('57'), findsOneWidget);
      expect(find.text('Logins únicos'), findsOneWidget);
      expect(find.text('Visitas por dia'), findsOneWidget);
      expect(find.text('Logins únicos por dia'), findsOneWidget);
      expect(find.text('15/11'), findsNWidgets(2));
      expect(find.text('Fatec Itu'), findsOneWidget);
      expect(find.text('31 visitas'), findsOneWidget);

      await tester.ensureVisible(find.text('Programas').last);
      await tester.tap(find.text('Programas').last);
      await tester.pumpAndSettle();
      expect(find.text('ENEM'), findsOneWidget);

      await tester.tap(find.text('Cursos').last);
      await tester.pumpAndSettle();
      expect(find.text('Nenhum acesso no período.'), findsOneWidget);
    });

    testWidgets('sem acessos no período, o ranking avisa', (tester) async {
      mockAuthApiRotas(_rotasDashboard(rankingVazio: true));

      await pumpPainelAdmin(tester, '/admin/dashboard');

      expect(find.text('Nenhum acesso no período.'), findsOneWidget);
    });

    testWidgets('erro mostra "Tentar novamente", que recarrega', (tester) async {
      var falhar = true;
      mockAuthApiRotasDinamicas({
        'GET /notificacoes': (_) => semNotificacoes,
        'GET /estatisticas/resumo': (_) => falhar ? _erroInterno : RespostaFalsa(envelope(_resumo())),
        'GET /estatisticas/visitas': (_) => RespostaFalsa(envelope(_visitas())),
        'GET /estatisticas/ranking': (_) => RespostaFalsa(envelope(_ranking())),
      });

      await pumpPainelAdmin(tester, '/admin/dashboard');
      expect(find.text('Não foi possível carregar o dashboard'), findsOneWidget);

      falhar = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('130'), findsOneWidget);
    });

    testWidgets('o seletor de período pede 7 dias, 30 dias ou 12 meses ao mês', (tester) async {
      mockAuthApiRotas(_rotasDashboard());
      await pumpComRouter(
        tester,
        initialLocation: '/',
        rotas: {
          '/': (context) => Scaffold(
                body: SingleChildScrollView(child: SecaoDashboard(agora: () => DateTime(2026, 11, 17, 10))),
              ),
        },
      );
      await tester.pumpAndSettle();

      expect(requisicoes('GET', '/estatisticas/visitas').last.query,
          {'de': '2026-10-19', 'ate': '2026-11-17', 'agrupar': 'dia'});

      await tester.tap(find.text('7 dias'));
      await tester.pumpAndSettle();
      expect(requisicoes('GET', '/estatisticas/visitas').last.query,
          {'de': '2026-11-11', 'ate': '2026-11-17', 'agrupar': 'dia'});

      await tester.tap(find.text('12 meses'));
      await tester.pumpAndSettle();
      expect(requisicoes('GET', '/estatisticas/visitas').last.query,
          {'de': '2025-12-01', 'ate': '2026-11-17', 'agrupar': 'mes'});
      expect(requisicoes('GET', '/estatisticas/ranking').last.query, {'de': '2025-12-01', 'ate': '2026-11-17'});
      expect(find.text('Visitas por mês'), findsOneWidget);
    });
  });

  group('Cursos', () {
    testWidgets('lista, vazio e erro', (tester) async {
      var resposta = RespostaFalsa(paginaDe([_curso(campus: 2)]));
      mockAuthApiRotasDinamicas({
        'GET /notificacoes': (_) => semNotificacoes,
        'GET /cursos/administracao': (_) => resposta,
      });

      await pumpPainelAdmin(tester, '/admin/cursos');
      expect(find.text('Análise e Desenvolvimento de Sistemas'), findsOneWidget);
      expect(find.text('Fatec Itu'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      resposta = RespostaFalsa(paginaDe([]));
      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(requisicoes('GET', '/cursos/administracao').last.query['busca'], 'zzz');
      expect(find.text('Nenhum curso encontrado'), findsOneWidget);

      resposta = _erroInterno;
      await tester.enterText(find.byType(TextField).first, 'x');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível carregar'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('novo curso: exige nome e universidade e envia os campos', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /cursos/administracao': RespostaFalsa(paginaDe([])),
        'GET /universidades/administracao': RespostaFalsa(
          envelope([
            {
              'id': 7,
              'nomeFantasia': 'Fatec Itu',
              'razaoSocial': 'Faculdade',
              'cnpj': '12345678000199',
              'natureza': 'P',
              'status': 'A',
              'cidade': 'Itu',
              'estado': 'SP',
              'criadoEm': '2026-11-10T12:00:00.000Z',
              'aprovadoEm': null,
            },
          ], {'page': 1, 'pageSize': 100, 'total': 1, 'totalPages': 1, 'pendentes': 0}),
        ),
        'POST /universidades/7/cursos': RespostaFalsa(envelope(_curso()), status: 201),
      });

      await pumpPainelAdmin(tester, '/admin/cursos');
      await tester.tap(find.text('Novo curso'));
      await tester.pumpAndSettle();
      expect(requisicoes('GET', '/universidades/administracao').single.query['pageSize'], '100');

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('Informe o nome do curso'), findsOneWidget);
      expect(find.text('Escolha a universidade'), findsOneWidget);
      expect(requisicoes('POST', '/cursos'), isEmpty);

      await escolher(tester, const Key('curso-universidade'), 'Fatec Itu (Aprovada)');
      await tester.enterText(campo('Nome'), 'Análise e Desenvolvimento de Sistemas');
      await tester.enterText(campo('Duração (semestres)'), '6');
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final corpo = requisicoes('POST', '/universidades/7/cursos').single.corpo as Map;
      expect(corpo['nome'], 'Análise e Desenvolvimento de Sistemas');
      expect(corpo['duracaoSemestres'], 6);
      expect(corpo['areaCurso'], isNull);
      expect(find.text('Curso criado.'), findsOneWidget);
    });

    testWidgets('editar envia o PATCH com os dados do formulário', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /cursos/administracao': RespostaFalsa(paginaDe([_curso()])),
        'PATCH /cursos/30': RespostaFalsa(envelope(_curso(nome: 'ADS'))),
      });

      await pumpPainelAdmin(tester, '/admin/cursos');
      await tester.tap(find.byTooltip('Editar Análise e Desenvolvimento de Sistemas'));
      await tester.pumpAndSettle();
      expect(find.text('Universidade: Fatec Itu'), findsOneWidget);

      await tester.enterText(campo('Nome'), 'ADS');
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect((requisicoes('PATCH', '/cursos/30').single.corpo as Map)['nome'], 'ADS');
      expect(find.text('Curso atualizado.'), findsOneWidget);
    });

    testWidgets('excluir pede confirmação; curso ofertado mostra o bloqueio da API', (tester) async {
      const mensagem = 'Este curso está ofertado em 2 campi. Remova as ofertas antes de excluir.';
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /cursos/administracao': RespostaFalsa(paginaDe([_curso(campus: 2)])),
        'DELETE /cursos/30': erroDaApi('CURSO_OFERTADO', mensagem),
      });

      await pumpPainelAdmin(tester, '/admin/cursos');
      await tester.tap(find.byTooltip('Excluir Análise e Desenvolvimento de Sistemas'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir curso'), findsOneWidget);
      await confirmarNoDialogo(tester, 'Excluir');

      expect(requisicoes('DELETE', '/cursos/30'), hasLength(1));
      expect(find.text('Ação não permitida'), findsOneWidget);
      expect(find.text(mensagem), findsOneWidget);
    });
  });

  group('Programas (Bolsas de Estudo)', () {
    testWidgets('lista filtrada pelo tipo da aba, vazio e erro', (tester) async {
      var resposta = RespostaFalsa(paginaDe([_programa(eventos: [_evento()])]));
      mockAuthApiRotasDinamicas({
        'GET /notificacoes': (_) => semNotificacoes,
        'GET /programas/administracao': (_) => resposta,
      });

      await pumpPainelAdmin(tester, '/admin/bolsas');
      expect(requisicoes('GET', '/programas/administracao').last.query['tipo'], 'BOLSA');
      expect(find.text('PROUNI'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Nova bolsa'), findsOneWidget);

      resposta = RespostaFalsa(paginaDe([]));
      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum programa encontrado'), findsOneWidget);

      resposta = _erroInterno;
      await tester.enterText(find.byType(TextField).first, 'x');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível carregar'), findsOneWidget);
    });

    testWidgets('as abas Financiamento e Programas de Entrada pedem o próprio tipo', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /programas/administracao': RespostaFalsa(paginaDe([])),
      });

      await pumpPainelAdmin(tester, '/admin/financiamento');
      expect(requisicoes('GET', '/programas/administracao').last.query['tipo'], 'FINANCIAMENTO');
      expect(find.text('Novo financiamento'), findsOneWidget);

      await tester.ensureVisible(find.text('Programas de Entrada'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Programas de Entrada'));
      await tester.pumpAndSettle();
      expect(requisicoes('GET', '/programas/administracao').last.query['tipo'], 'ENTRADA');
    });

    testWidgets('nova bolsa: cria e, já em edição, cadastra uma data importante', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /programas/administracao': RespostaFalsa(paginaDe([])),
        'POST /programas': RespostaFalsa(envelope(_programa(id: 9, sigla: 'BM')), status: 201),
        'POST /programas/9/eventos': RespostaFalsa(envelope(_evento(id: 50, titulo: 'Resultado')), status: 201),
      });

      await pumpPainelAdmin(tester, '/admin/bolsas');
      await tester.tap(find.text('Nova bolsa'));
      await tester.pumpAndSettle();
      expect(find.text('Salve o programa para cadastrar as datas importantes.'), findsOneWidget);

      await tester.ensureVisible(find.text('Criar programa'));
      await tester.tap(find.text('Criar programa'));
      await tester.pumpAndSettle();
      expect(find.text('Informe o nome do programa'), findsOneWidget);
      expect(find.text('Informe a descrição'), findsOneWidget);

      await tester.enterText(campo('Nome'), 'Bolsa Mérito');
      await tester.enterText(find.byKey(const Key('programa-descricao')), 'Desconto por desempenho.');
      await tester.ensureVisible(find.text('Criar programa'));
      await tester.tap(find.text('Criar programa'));
      await tester.pumpAndSettle();

      final corpo = requisicoes('POST', '/programas').single.corpo as Map;
      expect(corpo, containsPair('tipo', 'BOLSA'));
      expect(corpo, containsPair('nome', 'Bolsa Mérito'));
      expect(corpo['linkOficial'], isNull);

      await tester.ensureVisible(find.text('Adicionar data'));
      await tester.tap(find.text('Adicionar data'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Título'), 'Resultado');
      await tester.enterText(campo('Início'), '10/02/2026');
      await tester.enterText(campo('Fim (opcional)'), '01/02/2026');
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Salvar')));
      await tester.pumpAndSettle();
      expect(find.text('A data de fim deve ser igual ou posterior à de início'), findsOneWidget);
      expect(requisicoes('POST', '/eventos'), isEmpty);

      await tester.enterText(campo('Fim (opcional)'), '20/02/2026');
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Salvar')));
      await tester.pumpAndSettle();

      expect(requisicoes('POST', '/programas/9/eventos').single.corpo,
          {'titulo': 'Resultado', 'descricao': null, 'dataInicio': '2026-02-10', 'dataFim': '2026-02-20'});
      expect(find.text('Resultado'), findsOneWidget);
      expect(find.text('01/02/2026 a 10/02/2026'), findsOneWidget);
    });

    testWidgets('editar carrega o programa com as datas e exclui uma data', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /programas/administracao/3': RespostaFalsa(envelope(_programa(eventos: [_evento()]))),
        'GET /programas/administracao': RespostaFalsa(paginaDe([_programa(eventos: [_evento()])])),
        'DELETE /programas/eventos/40': RespostaFalsa(envelope({'sucesso': true})),
      });

      await pumpPainelAdmin(tester, '/admin/bolsas');
      await tester.tap(find.byTooltip('Editar Programa Universidade para Todos'));
      await tester.pumpAndSettle();

      expect(find.text('Programa Universidade para Todos'), findsWidgets);
      expect(find.text('Inscrições'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Excluir Inscrições'));
      await tester.tap(find.byTooltip('Excluir Inscrições'));
      await tester.pumpAndSettle();
      await confirmarNoDialogo(tester, 'Excluir');

      expect(requisicoes('DELETE', '/programas/eventos/40'), hasLength(1));
      expect(find.text('Nenhuma data cadastrada.'), findsOneWidget);
    });

    testWidgets('a ilustração interna aparece como prévia, sem expor o caminho, e continua ao salvar', (tester) async {
      final comIlustracao = {..._programa(), 'imagemUrl': 'assets/img/programas/prouni.svg'};
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /programas/administracao/3': RespostaFalsa(envelope(comIlustracao)),
        'GET /programas/administracao': RespostaFalsa(paginaDe([comIlustracao])),
        'PATCH /programas/3': RespostaFalsa(envelope(comIlustracao)),
      });

      await pumpPainelAdmin(tester, '/admin/bolsas');
      await tester.tap(find.byTooltip('Editar Programa Universidade para Todos'));
      await tester.pumpAndSettle();

      expect(find.textContaining('assets/img'), findsNothing);
      expect(find.textContaining('ilustração padrão do programa'), findsOneWidget);

      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final patch = requisicoes('PATCH', '/programas/3').single;
      expect((patch.corpo as Map)['imagemUrl'], 'assets/img/programas/prouni.svg');
    });

    testWidgets('programa aceito por universidades não é excluído (bloqueio da API)', (tester) async {
      const mensagem = 'Este programa é aceito por 4 universidades. Ele só pode ser excluído quando nenhuma universidade o aceitar.';
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /programas/administracao': RespostaFalsa(paginaDe([_programa()])),
        'DELETE /programas/3': erroDaApi('PROGRAMA_ACEITO', mensagem),
      });

      await pumpPainelAdmin(tester, '/admin/bolsas');
      await tester.tap(find.byTooltip('Excluir Programa Universidade para Todos'));
      await tester.pumpAndSettle();
      await confirmarNoDialogo(tester, 'Excluir');

      expect(find.text('Ação não permitida'), findsOneWidget);
      expect(find.text(mensagem), findsOneWidget);
    });
  });

  group('Universidades: editar dados', () {
    testWidgets('abre preenchido, envia o PATCH e mostra os dados novos', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /universidades/7/cadastro': RespostaFalsa(envelope(cadastroUniversidadeJson(status: 'A'))),
        'PATCH /universidades/7': RespostaFalsa(
          envelope(cadastroUniversidadeJson(status: 'A', nomeFantasia: 'Fatec Itu Nova')),
        ),
      });

      await pumpPainelAdmin(tester, '/admin/universidades/7');
      await tester.ensureVisible(find.text('Editar dados'));
      await tester.tap(find.text('Editar dados'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(campo('CNPJ')).controller!.text, '12.345.678/0001-99');
      await tester.enterText(campo('Nome fantasia'), 'Fatec Itu Nova');
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final corpo = requisicoes('PATCH', '/universidades/7').single.corpo as Map;
      expect(corpo['nomeFantasia'], 'Fatec Itu Nova');
      expect(corpo['natureza'], 'P');
      expect(find.text('Dados da universidade atualizados.'), findsOneWidget);
      expect(find.text('Fatec Itu Nova'), findsOneWidget);
    });

    testWidgets('CNPJ de outra universidade aparece no campo', (tester) async {
      mockAuthApiRotas({
        'GET /notificacoes': semNotificacoes,
        'GET /universidades/7/cadastro': RespostaFalsa(envelope(cadastroUniversidadeJson(status: 'A'))),
        'PATCH /universidades/7': erroDaApi('CNPJ_EM_USO', 'Este CNPJ já está cadastrado em outra universidade'),
      });

      await pumpPainelAdmin(tester, '/admin/universidades/7');
      await tester.ensureVisible(find.text('Editar dados'));
      await tester.tap(find.text('Editar dados'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Este CNPJ já está cadastrado em outra universidade'), findsWidgets);
    });
  });

  group('Usuários: novo e editar perfil', () {
    Map<String, RespostaFalsa> rotas({RespostaFalsa? patch}) => {
          'GET /notificacoes': semNotificacoes,
          'GET /usuarios': RespostaFalsa(paginaDe([
            _usuario(id: 1, nome: 'Mayara Santos'),
            _usuario(id: 99, nome: 'Equipe Guia Jovem', tipo: 'D'),
          ])),
          'POST /usuarios': RespostaFalsa(envelope(_usuario(id: 5, nome: 'Nova Admin', tipo: 'D')), status: 201),
          'PATCH /usuarios/1': patch ?? RespostaFalsa(envelope(_usuario(id: 1, nome: 'Mayara Santos', tipo: 'D'))),
        };

    testWidgets('novo usuário valida e cria com o perfil escolhido', (tester) async {
      mockAuthApiRotas(rotas());

      await pumpPainelAdmin(tester, '/admin/usuarios');
      await tester.tap(find.text('Novo usuário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar usuário'));
      await tester.pumpAndSettle();
      expect(find.text('Informe um e-mail válido'), findsOneWidget);
      expect(find.text('Informe uma senha com 7 ou mais caracteres'), findsOneWidget);

      await tester.enterText(campo('Nome'), 'Nova Admin');
      await tester.enterText(campo('E-mail'), 'nova@guiajovem.com.br');
      await tester.enterText(campo('Senha inicial'), 'senha1234');
      await escolher(tester, const Key('usuario-perfil'), 'Administrador');
      await tester.ensureVisible(find.text('Criar usuário'));
      await tester.tap(find.text('Criar usuário'));
      await tester.pumpAndSettle();

      expect(requisicoes('POST', '/usuarios').single.corpo,
          {'nome': 'Nova Admin', 'email': 'nova@guiajovem.com.br', 'senha': 'senha1234', 'tipoUsuario': 'D'});
      expect(find.text('Usuário criado.'), findsOneWidget);
    });

    testWidgets('editar muda o perfil e atualiza a linha', (tester) async {
      mockAuthApiRotas(rotas());

      await pumpPainelAdmin(tester, '/admin/usuarios');
      await tester.tap(find.byTooltip('Editar Mayara Santos'));
      await tester.pumpAndSettle();
      await escolher(tester, const Key('usuario-perfil'), 'Administrador');
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(requisicoes('PATCH', '/usuarios/1').single.corpo, {'nome': 'Mayara Santos', 'tipoUsuario': 'D'});
      expect(find.text('Usuário atualizado.'), findsOneWidget);
      expect(find.text('Administrador'), findsNWidgets(2));
    });

    testWidgets('a regra do último administrador bloqueia a troca de perfil', (tester) async {
      const mensagem = 'Esta é a única conta de administrador ativa.';
      mockAuthApiRotas(rotas(patch: erroDaApi('ULTIMO_ADMINISTRADOR', mensagem)));

      await pumpPainelAdmin(tester, '/admin/usuarios');
      await tester.tap(find.byTooltip('Editar Mayara Santos'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Ação não permitida'), findsOneWidget);
      expect(find.text(mensagem), findsOneWidget);
    });

    testWidgets('na própria conta só o nome é editável', (tester) async {
      mockAuthApiRotas(rotas());

      await pumpPainelAdmin(tester, '/admin/usuarios');
      await tester.tap(find.byTooltip('Editar Equipe Guia Jovem'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('usuario-perfil')), findsNothing);
      expect(find.textContaining('peça a outro administrador'), findsOneWidget);
    });
  });

  group('Carregamento, vazio e erro das seções', () {
    const atraso = Duration(milliseconds: 500);

    for (final caso in [
      ('dashboard', 'GET /estatisticas/resumo'),
      ('usuarios', 'GET /usuarios'),
      ('cursos', 'GET /cursos/administracao'),
      ('bolsas', 'GET /programas/administracao'),
    ]) {
      testWidgets('${caso.$1}: mostra o esqueleto enquanto carrega', (tester) async {
        mockAuthApiRotas({
          'GET /notificacoes': semNotificacoes,
          caso.$2: RespostaFalsa(paginaDe([]), atraso: atraso),
          'GET /estatisticas/visitas': RespostaFalsa(envelope(_visitas()), atraso: atraso),
          'GET /estatisticas/ranking': RespostaFalsa(envelope(_ranking()), atraso: atraso),
        });
        sessionController.redefinirParaTestes(usuario: adminDeTeste);

        await pumpComRouter(
          tester,
          initialLocation: '/admin/${caso.$1}',
          rotas: {
            '/admin/:secao': (context) => PainelAdminPage(secao: SecaoAdmin.doCaminho(caso.$1)),
          },
        );

        expect(find.byType(GJSkeleton), findsWidgets);
        await tester.pumpAndSettle();
      });
    }

    testWidgets('usuários: vazio com filtros e erro com "Tentar novamente"', (tester) async {
      var resposta = RespostaFalsa(paginaDe([]));
      mockAuthApiRotasDinamicas({
        'GET /notificacoes': (_) => semNotificacoes,
        'GET /usuarios': (_) => resposta,
      });

      await pumpPainelAdmin(tester, '/admin/usuarios');
      expect(find.text('Nenhum usuário encontrado'), findsOneWidget);

      resposta = _erroInterno;
      await tester.enterText(find.byType(TextField).first, 'x');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível carregar'), findsOneWidget);

      resposta = RespostaFalsa(paginaDe([_usuario(id: 1, nome: 'Mayara Santos')]));
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Mayara Santos'), findsOneWidget);
    });
  });
}
