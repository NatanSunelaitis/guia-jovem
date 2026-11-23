import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/cursos/domain/curso.dart';
import 'package:app/features/cursos/presentation/detalhe_curso_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

Map<String, dynamic> _oferta({
  int cursoId = 7,
  int universidadeId = 2,
  String nomeFantasia = 'UniVale Sorocaba',
  String natureza = 'V',
  String modalidade = 'Presencial',
  String grau = 'Bacharelado',
  String notaMec = '4',
  int duracao = 8,
  String? descricao = '## O que você estuda\n\nGestão de **pessoas** e finanças.',
  List<Map<String, dynamic>>? campus,
}) =>
    {
      'cursoId': cursoId,
      'areaCurso': 'Negócios',
      'grau': grau,
      'modalidade': modalidade,
      'duracaoSemestres': duracao,
      'notaMec': notaMec,
      'descricao': descricao,
      'universidade': {
        'id': universidadeId,
        'nomeFantasia': nomeFantasia,
        'logoUrl': null,
        'natureza': natureza,
        'cidade': 'Sorocaba',
        'estado': 'SP',
      },
      'campus': campus ??
          [
            {'id': 30, 'nome': 'Campus Centro', 'cidade': 'Sorocaba', 'estado': 'SP', 'turno': 'Noturno', 'vagas': 100},
            {'id': 31, 'nome': 'Campus Campolim', 'cidade': 'Sorocaba', 'estado': 'SP', 'turno': 'Matutino', 'vagas': 50},
          ],
      'programas': {
        'ENTRADA': [
          {'id': 1, 'nome': 'Exame Nacional do Ensino Médio', 'sigla': 'ENEM', 'observacao': null, 'institucional': false},
        ],
        'FINANCIAMENTO': [
          {'id': 5, 'nome': 'Fundo de Financiamento Estudantil', 'sigla': 'FIES', 'observacao': 'Até 100% da mensalidade', 'institucional': false},
        ],
        'BOLSA': [
          {'id': 9, 'nome': 'Bolsa Mérito UniVale', 'sigla': 'Mérito', 'observacao': null, 'institucional': true},
        ],
      },
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(WidgetTester tester, Widget pagina) async {
    tester.view.physicalSize = const Size(1366, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: pagina));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('por id: resumo, card da universidade e descrição formatada acima dos cards', (tester) async {
    mockApi({
      '/cursos/5': envelope({
        'id': 5,
        'nome': 'Administração',
        ..._oferta(cursoId: 5),
      }),
    });

    await abrir(tester, const DetalheCursoPage.porId(id: 5));

    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('8 semestres (4 anos)'), findsWidgets);
    expect(find.text('1 universidade em 1 cidade'), findsOneWidget);
    // Uma oferta só: a descrição aparece uma vez, acima do card, formatada.
    expect(find.text('Sobre o curso'), findsOneWidget);
    expect(find.text('O que você estuda', findRichText: true), findsOneWidget);
    expect(find.text('Ver mais'), findsNothing);
    expect(find.text('Universidade que oferece este curso'), findsOneWidget);
    final imagem = tester.widget<Image>(find.byType(Image).first);
    expect((imagem.image as AssetImage).assetName, 'assets/fotos/cursos/administracao.jpg');
  });

  testWidgets('por nome: descrições diferentes em abas por universidade e duração em faixa no resumo', (tester) async {
    mockApi({
      '/cursos/nome/Pedagogia': envelope({
        'nome': 'Pedagogia',
        'areaCurso': 'Humanas',
        'universidades': [
          _oferta(),
          _oferta(
            cursoId: 8,
            universidadeId: 3,
            nomeFantasia: 'UESP',
            natureza: 'P',
            modalidade: 'EAD',
            duracao: 10,
            descricao: 'Texto **diferente** com a modalidade a distância.',
            campus: [
              {'id': 40, 'nome': 'Campus Itapetininga', 'cidade': 'Itapetininga', 'estado': 'SP', 'turno': 'Noturno', 'vagas': 45},
            ],
          ),
        ],
      }),
    });

    await abrir(tester, const DetalheCursoPage.porNome(nome: 'Pedagogia'));

    expect(find.text('Em quais universidades este curso está disponível'), findsOneWidget);
    // Resumo do topo.
    expect(find.text('Bacharelado'), findsWidgets);
    expect(find.text('EAD e Presencial'), findsOneWidget);
    expect(find.text('8 a 10 semestres'), findsOneWidget);
    expect(find.text('2 universidades em 2 cidades'), findsOneWidget);

    // Card: sigla, nome, cidade, natureza, dados do curso, campi e programas.
    // A sigla aparece no card e na aba da descrição.
    expect(find.text('UniVale'), findsNWidgets(2));
    expect(find.text('UniVale Sorocaba'), findsNWidgets(2));
    expect(find.text('Privada'), findsOneWidget);
    expect(find.text('Pública'), findsOneWidget);
    expect(find.text('Campus Centro'), findsOneWidget);
    expect(find.text('Sorocaba/SP · Noturno · 100 vagas'), findsOneWidget);
    expect(find.text('Itapetininga/SP · Noturno · 45 vagas'), findsOneWidget);
    expect(find.text('ENEM'), findsNWidgets(2));
    expect(find.text('FIES'), findsNWidgets(2));
    expect(find.text('Bolsa Mérito UniVale'), findsNWidgets(2));
    expect(find.textContaining('Nota do MEC: 4', findRichText: true), findsNWidgets(2));

    // Descrições diferentes: "Sobre o curso" acima dos cards, com uma aba por
    // universidade e a primeira aberta; nada de descrição dentro dos cards.
    expect(find.text('Sobre o curso'), findsOneWidget);
    expect(find.text('Descrição informada por cada instituição'), findsOneWidget);
    expect(find.byKey(const Key('abas-descricao')), findsOneWidget);
    expect(find.text('Ver mais'), findsNothing);
    expect(find.byKey(const ValueKey('descricao-7')), findsOneWidget);
    expect(find.text('Texto diferente com a modalidade a distância.', findRichText: true), findsNothing);
    final sobre = tester.getRect(find.byKey(const Key('sobre-o-curso')));
    expect(sobre.bottom, lessThan(tester.getTopLeft(find.byKey(const Key('oferta-7'))).dy));

    await tester.tap(find.descendant(of: find.byKey(const Key('abas-descricao')), matching: find.text('UESP')));
    await tester.pump();
    expect(find.byKey(const ValueKey('descricao-8')), findsOneWidget);
    expect(find.text('Texto diferente com a modalidade a distância.', findRichText: true), findsOneWidget);
    expect(find.text('O que você estuda', findRichText: true), findsNothing);

    // Uma modalidade em cada universidade: filtro sobre os cards.
    await tester.tap(find.byKey(const Key('filtro-modalidade-EAD')));
    await tester.pump();
    expect(find.byKey(const Key('oferta-8')), findsOneWidget);
    expect(find.byKey(const Key('oferta-7')), findsNothing);
  });

  testWidgets('por nome: mesmo curso com dois graus mostra a distribuição, o aviso e o filtro por grau', (tester) async {
    mockApi({
      '/cursos/nome/Educação Física': envelope({
        'nome': 'Educação Física',
        'areaCurso': 'Saúde',
        'universidades': [
          _oferta(grau: 'Licenciatura', notaMec: '3', descricao: 'Igual.'),
          _oferta(cursoId: 8, universidadeId: 3, nomeFantasia: 'UESP', duracao: 8, notaMec: '5', descricao: 'Igual.'),
          _oferta(cursoId: 9, universidadeId: 4, nomeFantasia: 'FEITU', descricao: 'Igual.'),
        ],
      }),
    });

    await abrir(tester, const DetalheCursoPage.porNome(nome: 'Educação Física'));

    expect(find.text('Graus'), findsOneWidget);
    expect(find.text('Bacharelado e Licenciatura'), findsOneWidget);
    expect(find.text('Bacharelado em 2 universidades, Licenciatura em 1'), findsOneWidget);
    expect(find.text('3 a 5'), findsOneWidget);
    expect(find.text('8 semestres (4 anos)'), findsWidgets);
    expect(find.byKey(const Key('aviso-graus')), findsOneWidget);
    // Grau em destaque em cada card.
    expect(find.descendant(of: find.byKey(const Key('grau-oferta-7')), matching: find.text('Licenciatura')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('grau-oferta-8')), matching: find.text('Bacharelado')), findsOneWidget);
    // Uma só modalidade: sem filtro de modalidade.
    expect(find.byKey(const Key('filtro-modalidade-todos')), findsNothing);

    await tester.tap(find.byKey(const Key('filtro-grau-Licenciatura')));
    await tester.pump();
    expect(find.byKey(const Key('oferta-7')), findsOneWidget);
    expect(find.byKey(const Key('oferta-8')), findsNothing);
    expect(find.byKey(const Key('oferta-9')), findsNothing);

    await tester.tap(find.byKey(const Key('filtro-grau-todos')));
    await tester.pump();
    expect(find.byKey(const Key('oferta-9')), findsOneWidget);
  });

  testWidgets('por nome: sem descrição nenhuma, "Sobre o curso" mostra uma mensagem curta', (tester) async {
    mockApi({
      '/cursos/nome/Logística': envelope({
        'nome': 'Logística',
        'areaCurso': 'Negócios',
        'universidades': [_oferta(descricao: null), _oferta(cursoId: 8, universidadeId: 3, nomeFantasia: 'UESP', descricao: '  ')],
      }),
    });

    await abrir(tester, const DetalheCursoPage.porNome(nome: 'Logística'));

    expect(find.text('Sobre o curso'), findsOneWidget);
    expect(find.byKey(const Key('sobre-sem-descricao')), findsOneWidget);
    expect(find.byKey(const Key('abas-descricao')), findsNothing);
    expect(find.byKey(const Key('aviso-graus')), findsNothing);
  });

  testWidgets('por nome: só uma universidade descreveu o curso, sem abas', (tester) async {
    mockApi({
      '/cursos/nome/Turismo': envelope({
        'nome': 'Turismo',
        'areaCurso': 'Humanas',
        'universidades': [_oferta(descricao: null), _oferta(cursoId: 8, universidadeId: 3, nomeFantasia: 'UESP')],
      }),
    });

    await abrir(tester, const DetalheCursoPage.porNome(nome: 'Turismo'));

    expect(find.text('O que você estuda', findRichText: true), findsOneWidget);
    expect(find.byKey(const Key('abas-descricao')), findsNothing);
    expect(find.text('Descrição informada por cada instituição'), findsNothing);
  });

  testWidgets('por nome: descrições iguais aparecem uma vez só, acima dos cards', (tester) async {
    mockApi({
      '/cursos/nome/Farmácia': envelope({
        'nome': 'Farmácia',
        'areaCurso': 'Saúde',
        'universidades': [_oferta(), _oferta(cursoId: 8, universidadeId: 3, nomeFantasia: 'UESP')],
      }),
    });

    await abrir(tester, const DetalheCursoPage.porNome(nome: 'Farmácia'));

    expect(find.text('Sobre o curso'), findsOneWidget);
    expect(find.text('O que você estuda', findRichText: true), findsOneWidget);
    expect(find.text('Ver mais'), findsNothing);
    final imagem = tester.widget<Image>(find.byType(Image).first);
    expect((imagem.image as AssetImage).assetName, 'assets/fotos/cursos/farmacia.jpg');
  });

  testWidgets('no celular a página monta sem estourar a largura', (tester) async {
    mockApi({
      '/cursos/nome/Pedagogia': envelope({
        'nome': 'Pedagogia',
        'areaCurso': 'Humanas',
        'universidades': [_oferta(), _oferta(cursoId: 8, universidadeId: 3, nomeFantasia: 'Faculdade Votorantim de Tecnologia', descricao: 'Outra.')],
      }),
    });
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const DetalheCursoPage.porNome(nome: 'Pedagogia')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('FVT'), findsNWidgets(2));
  });

  testWidgets('volume: 20 universidades em 8 por página, com busca, e o resumo conta todas', (tester) async {
    mockApi({
      '/cursos/nome/Direito': envelope({
        'nome': 'Direito',
        'areaCurso': 'Direito',
        'universidades': [
          for (var i = 1; i <= 20; i++)
            _oferta(cursoId: 100 + i, universidadeId: i, nomeFantasia: i == 13 ? 'Faculdade de Itapetininga' : 'Universidade ${i.toString().padLeft(2, '0')}', descricao: 'Igual.'),
        ],
      }),
    });

    await abrir(tester, const DetalheCursoPage.porNome(nome: 'Direito'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('20 universidades em 1 cidade'), findsOneWidget);
    expect(find.text('Página 1 de 3'), findsOneWidget);
    expect(find.text('Universidade 01'), findsOneWidget);
    expect(find.text('Universidade 09'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Buscar universidade ou cidade'), 'itapetininga');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Faculdade de Itapetininga'), findsOneWidget);
    expect(find.text('1 universidade'), findsOneWidget);
  });

  group('resumo do curso', () {
    OfertaCurso oferta({int? duracao, String? descricao, String cidade = 'Sorocaba'}) => OfertaCurso.fromJson({
          ..._oferta(descricao: descricao),
          'duracaoSemestres': duracao,
          'campus': [
            {'id': 1, 'nome': 'C', 'cidade': cidade, 'estado': 'SP', 'turno': null, 'vagas': null},
          ],
        });

    test('duração única, com anos e meio, e faixa', () {
      expect(duracaoDasOfertas([oferta(duracao: 8)]), '8 semestres (4 anos)');
      expect(duracaoDasOfertas([oferta(duracao: 5)]), '5 semestres (2 anos e meio)');
      expect(duracaoDasOfertas([oferta(duracao: 4), oferta(duracao: 10)]), '4 a 10 semestres');
      expect(duracaoDasOfertas([oferta()]), isNull);
    });

    test('cidades distintas e valores com "e"', () {
      expect(cidadesDasOfertas([oferta(), oferta(), oferta(cidade: 'Tatuí')]), {'Sorocaba/SP', 'Tatuí/SP'});
      expect(valoresDistintos(['Bacharelado', 'Licenciatura', 'Bacharelado', 'Tecnólogo']), 'Bacharelado, Licenciatura e Tecnólogo');
    });

    test('descrição única quando só uma universidade descreveu ou todas são iguais', () {
      expect(descricaoComum([oferta(descricao: 'A'), oferta(descricao: 'A')]), 'A');
      expect(descricaoComum([oferta(descricao: 'A'), oferta(descricao: null)]), 'A');
      expect(descricaoComum([oferta(descricao: 'A'), oferta(descricao: 'B')]), isNull);
      expect(descricaoComum([oferta(descricao: null), oferta(descricao: null)]), isNull);
      expect(ofertasComDescricao([oferta(descricao: 'A'), oferta(descricao: ' '), oferta(descricao: null)]), hasLength(1));
    });

    OfertaCurso daUniversidade(int id, {String? grau, String? nota}) => OfertaCurso.fromJson({
          ..._oferta(universidadeId: id, grau: grau ?? 'Bacharelado', notaMec: nota ?? '4'),
        });

    test('distribuição por grau conta universidades, do mais oferecido para o menos', () {
      final ofertas = [daUniversidade(1), daUniversidade(2, grau: 'Tecnólogo'), daUniversidade(3), daUniversidade(3)];
      final distribuicao = distribuicaoPorUniversidade(ofertas, (o) => o.grau);
      expect(distribuicao, [('Bacharelado', 2), ('Tecnólogo', 1)]);
      expect(textoDistribuicao(distribuicao), 'Bacharelado em 2 universidades, Tecnólogo em 1');
      expect(textoDistribuicao(distribuicaoPorUniversidade([daUniversidade(1)], (o) => o.grau)), isNull);
    });

    test('nota do MEC única, em faixa ou em lista', () {
      expect(notaMecDasOfertas([daUniversidade(1), daUniversidade(2)]), '4');
      expect(notaMecDasOfertas([daUniversidade(1, nota: '5'), daUniversidade(2, nota: '3')]), '3 a 5');
      expect(notaMecDasOfertas([daUniversidade(1, nota: 'Sem conceito'), daUniversidade(2, nota: '3')]), 'Sem conceito e 3');
    });
  });
}
